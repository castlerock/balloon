#
#  BNImageView.rb
#  Balloon
#
#  Created by Mark Madsen on 4/2/11.
#  Copyright 2011 AGiLE ANiMAL INC. All rights reserved.
#


class BNImageView < NSImageView
  
  def draggingEntered(sender)
    NSDragOperationEvery
  end
  
  def prepareForDragOperation(sender)
    pboard = sender.draggingPasteboard
    files = pboard.propertyListForType(NSFilenamesPboardType)
    number_of_files = files.count;
    NSLog("#{files[0]}")
    workspace = NSWorkspace.sharedWorkspace
    icon_image = workspace.iconForFile(files[0])
    self.image = icon_image
    true
  end

end