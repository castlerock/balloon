#
#  UploadOperation.rb
#  Balloon
#
#  Created by Mark Madsen on 5/28/11.
#  Copyright 2011 AGiLE ANiMAL INC. All rights reserved.
#

framework 'Foundation'
framework 'Growl'

require 'rubygems'
require 'yaml'

class UploadOperation < NSOperation
  
  attr_accessor :fileURL
  attr_accessor :iconImage
  attr_accessor :imageURL
  attr_accessor :shortURL
  
  attr_accessor :cloudfilesConfig
  
  attr_accessor :urlUpdatedDelegate
  
  def initWithFile(fileURL, iconImage)
    self.init
    self.cloudfilesConfig = YAML.load_file(NSBundle.mainBundle.resourcePath.fileSystemRepresentation+'/config.yml')['cloudfiles']
    @iconImage = iconImage
    @fileURL = fileURL
    self 
  end
  
  def setURLUpdatedDelegate(delegate)
      @urlUpdatedDelegate = delegate
  end
  
  
  def main
    cloud = CloudFiles::Connection.new(:username => cloudfilesConfig['username'], :api_key => cloudfilesConfig['api_key'])
    container = cloud.container(cloudfilesConfig['container'])
    object = container.create_object NSFileManager.defaultManager.displayNameAtPath(@fileURL), false
    object.write File.open(@fileURL)
    @imageURL = container.cdn_url + '/' + object.name
    @shortURL = Googl.shorten(imageURL).short_url
    
    @urlUpdatedDelegate.performSelectorOnMainThread("urlChanged:", withObject:{fileURL:@fileURL, shortURL:@shortURL}, waitUntilDone:false)
        
    GrowlApplicationBridge.notifyWithTitle("File Uploaded", description: shortURL, notificationName: "File Upload", iconData: @iconImage.TIFFRepresentation, priority: 0, isSticky: false, clickContext: nil)
    
  end
  

end