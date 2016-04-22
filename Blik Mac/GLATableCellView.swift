//
//  GLATableCellView.swift
//  Blik
//
//  Created by Patrick Smith on 22/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public class GLATableCellView : NSTableCellView
{
	public override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool {
		return true
	}

	public override func mouseDown(theEvent: NSEvent) {
		if enclosingMenuItem != nil {
			// Do not pass up to table view as normal, as we want to do the tracking
		}
		else {
			self.nextResponder?.mouseDown(theEvent)
		}
	}
		
	public override func mouseUp(theEvent: NSEvent) {
		if enclosingMenuItem != nil {
			guard let nextResponder = self.nextResponder else {
				return
			}
			
			if nextResponder.tryToPerform(#selector(NSControl.performClick(_:)), with: self) {
				return
			}
			
			guard let
				scrollView = nextResponderChain.flatMap({ $0 as? NSScrollView }).first,
				tableView = scrollView.documentView as? NSTableView
				else { return }
			
			tableView.tryToPerform(#selector(NSControl.performClick(_:)), with: self)
		}
		else {
			self.nextResponder?.mouseUp(theEvent)
		}
	}
}


public class GLAHighlightsTableCellView : GLATableCellView {
	@IBOutlet var collectionIndicationButton: GLACollectionIndicationButton!
}
