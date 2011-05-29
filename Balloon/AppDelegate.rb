#
#  AppDelegate.rb
#  Balloon
#
#  Created by Mark Madsen on 4/1/11.
#  Copyright 2011 CRRI. All rights reserved.
#

framework 'Foundation'
framework 'Growl'
require 'rubygems'
require 'json'
require 'cloudfiles'
require 'googl'
require 'yaml'

require 'UploadOperation'

class AppDelegate
  
  # Persistence accessors
  attr_reader :persistentStoreCoordinator
  attr_reader :managedObjectModel
  attr_reader :managedObjectContext
  
  # Accessors for NIB
  attr_accessor :window
  attr_accessor :imageView
  attr_accessor :uploadURLButton
  attr_accessor :imageURL
  attr_accessor :cloudfilesConfig
  
  attr_accessor :queue
  #
  # Read in config and set defaults.
  # Like I am going to show you my API key...
  # Register for Drag and Drop
  #
  
  def applicationDidFinishLaunching(a_notification)
    @queue = NSOperationQueue.alloc.init
    @imageURL = nil
    
    #window.registerForDraggedTypes(NSArray.arrayWithObjects(NSFilenamesPboardType, nil))
    
    imageView.registerForDraggedTypes([NSFilenamesPboardType, nil])
    imageView.dragDelegate = self;
    imageView.image = NSImage.imageNamed('ready.png')

    GrowlApplicationBridge.setGrowlDelegate(self)
  end
  
  #
  # Handle the drag and drop
  #
  
  def draggingEntered(sender)
    imageView.image = NSImage.imageNamed('upload.png')
    NSDragOperationEvery
  end
  
  def draggingExited(sender)
    imageView.image = NSImage.imageNamed('ready.png')
    NSDragOperationEvery
  end

  def prepareForDragOperation(sender)
    imageView.image = NSImage.imageNamed('uploading.png')
    pboard = sender.draggingPasteboard
    files = pboard.propertyListForType(NSFilenamesPboardType)
    files.each do |file|
      workspace = NSWorkspace.sharedWorkspace
      iconImage = workspace.iconForFile(file)
      
      # THIS WAY WILL BLOCK ON THE MAIN UI THREAD
      ##uploadImageToCloud(files[0], iconImage)
      # THIS WAY WILL NOT
      uploader = UploadOperation.alloc.initWithFile(file, iconImage)
      uploader.setURLUpdatedDelegate(self)
      @queue.addOperation uploader
    end
  end
  
  
  
  #
  # Uploads the image (or other file) to the cloud
  #
  
  def uploadImageToCloud(path, icon)
    cloudfilesConfig = YAML.load_file(NSBundle.mainBundle.resourcePath.fileSystemRepresentation+'/config.yml')['cloudfiles']
    cloud = CloudFiles::Connection.new(:username => cloudfilesConfig['username'], :api_key => cloudfilesConfig['api_key'])
    container = cloud.container(cloudfilesConfig['container'])
    object = container.create_object NSFileManager.defaultManager.displayNameAtPath(path), false
    object.write File.open(path)
    self.imageURL = container.cdn_url + '/' + object.name

    short_url = Googl.shorten(imageURL).short_url
    
    uploadURLButton.title = short_url
    
    GrowlApplicationBridge.notifyWithTitle("File Uploaded", description: short_url, notificationName: "File Upload", iconData: icon.TIFFRepresentation, priority: 0, isSticky: false, clickContext: nil)
  end
  
  #
  # Once upload completes, update the UI
  #
  
  def urlChanged(paths)
    short_url = paths[:shortURL]
    file_url = paths[:fileURL]
    
    @imageURL = short_url
    @uploadURLButton.title = short_url
    @imageView.image = NSImage.alloc.initWithContentsOfFile(file_url)
  end
  
  #
  # Opens the URL in a web browser
  #
  
  def openURL(sender)
    NSLog(imageURL)
    if !self.imageURL.nil?
      url = NSURL.URLWithString(imageURL)
      NSWorkspace.sharedWorkspace.openURL(url)
    end
  end
  
  
  
    
  #
  # Returns the directory the application uses to store the Core Data store file. This code uses a directory named "Balloon" in the user's Library directory.
  #
  def applicationFilesDirectory
    file_manager = NSFileManager.defaultManager
    library_url = file_manager.URLsForDirectory(NSLibraryDirectory, inDomains:NSUserDomainMask).lastObject
    library_url.URLByAppendingPathComponent("Balloon")
  end

  #
  # Creates if necessary and returns the managed object model for the application.
  #
  def managedObjectModel
    unless @managedObjectModel
      model_url = NSBundle.mainBundle.URLForResource("Balloon", withExtension:"momd")
      @managedObjectModel = NSManagedObjectModel.alloc.initWithContentsOfURL(model_url)
    end
    
    @managedObjectModel
  end

  #
  # Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
  #
  def persistentStoreCoordinator
    return @persistentStoreCoordinator if @persistentStoreCoordinator

    mom = self.managedObjectModel
    unless mom
      puts "#{self.class} No model to generate a store from"
      return nil
    end

    file_manager = NSFileManager.defaultManager
    directory = self.applicationFilesDirectory
    error = Pointer.new_with_type('@')

    properties = directory.resourceValuesForKeys([NSURLIsDirectoryKey], error:error)

    if properties.nil?
      ok = false
      if error[0].code == NSFileReadNoSuchFileError
        ok = file_manager.createDirectoryAtPath(directory.path, withIntermediateDirectories:true, attributes:nil, error:error)
      end
      if ok == false
        NSApplication.sharedApplication.presentError(error[0])
      end
    elsif properties[NSURLIsDirectoryKey] != true
        # Customize and localize this error.
        failure_description = "Expected a folder to store application data, found a file (#{directory.path})."

        error = NSError.errorWithDomain("YOUR_ERROR_DOMAIN", code:101, userInfo:{NSLocalizedDescriptionKey => failure_description})

        NSApplication.sharedApplication.presentError(error)
        return nil
    end

    url = directory.URLByAppendingPathComponent("Balloon.storedata")
    @persistentStoreCoordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(mom)

    unless @persistentStoreCoordinator.addPersistentStoreWithType(NSXMLStoreType, configuration:nil, URL:url, options:nil, error:error)
      NSApplication.sharedApplication.presentError(error[0])
      return nil
    end

    @persistentStoreCoordinator
  end

  #
  # Returns the managed object context for the application (which is already
  # bound to the persistent store coordinator for the application.) 
  #
  def managedObjectContext
    return @managedObjectContext if @managedObjectContext
    coordinator = self.persistentStoreCoordinator

    unless coordinator
      dict = {
        NSLocalizedDescriptionKey => "Failed to initialize the store",
        NSLocalizedFailureReasonErrorKey => "There was an error building up the data file."
      }
      error = NSError.errorWithDomain("YOUR_ERROR_DOMAIN", code:9999, userInfo:dict)
      NSApplication.sharedApplication.presentError(error)
      return nil
    end

    @managedObjectContext = NSManagedObjectContext.alloc.init
    @managedObjectContext.setPersistentStoreCoordinator(coordinator)

    @managedObjectContext
  end

  #
  # Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
  #
  def windowWillReturnUndoManager(window)
    self.managedObjectContext.undoManager
  end

  #
  # Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
  #
  def saveAction(sender)
    error = Pointer.new_with_type('@')

    unless self.managedObjectContext.commitEditing
      puts "#{self.class} unable to commit editing before saving"
    end

    unless self.managedObjectContext.save(error)
      NSApplication.sharedApplication.presentError(error[0])
    end
  end

  def applicationShouldTerminate(sender)
    # Save changes in the application's managed object context before the application terminates.

    return NSTerminateNow unless @managedObjectContext

    unless self.managedObjectContext.commitEditing
      puts "%@ unable to commit editing to terminate" % self.class
    end

    unless self.managedObjectContext.hasChanges
      return NSTerminateNow
    end

    error = Pointer.new_with_type('@')
    unless self.managedObjectContext.save(error)
      # Customize this code block to include application-specific recovery steps.
      return NSTerminateCancel if sender.presentError(error[0])

      alert = NSAlert.alloc.init
      alert.messageText = "Could not save changes while quitting. Quit anyway?"
      alert.informativeText = "Quitting now will lose any changes you have made since the last successful save"
      alert.addButtonWithTitle "Quit anyway"
      alert.addButtonWithTitle "Cancel"

      answer = alert.runModal
      return NSTerminateCancel if answer == NSAlertAlternateReturn
    end

    NSTerminateNow
  end
end

