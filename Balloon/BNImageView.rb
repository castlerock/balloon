#
#  BNImageView.rb
#  Balloon
#
#  Created by Mark Madsen on 4/2/11.
#  Copyright 2011 AGiLE ANiMAL INC. All rights reserved.
#


class BNImageView < NSImageView
  
  attr_accessor :dragDelegate
  
  def draggingEntered(sender)
    dragDelegate.draggingEntered(sender)
  end
  
  def prepareForDragOperation(sender)
    dragDelegate.prepareForDragOperation(sender)
  end
  
  def draggingExited(sender)
    dragDelegate.draggingExited(sender)
  end

end