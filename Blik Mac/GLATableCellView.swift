//
//  GLATableCellView.swift
//  Blik
//
//  Created by Patrick Smith on 22/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


open class GLATableCellView : NSTableCellView
{
	open override func acceptsFirstMouse(for theEvent: NSEvent?) -> Bool {
		return true
	}

	open override func mouseDown(with theEvent: NSEvent) {
		if enclosingMenuItem != nil {
			// Do not pass up to table view as normal, as we want to do the tracking
		}
		else {
			self.nextResponder?.mouseDown(with: theEvent)
		}
	}
		
	open override func mouseUp(with theEvent: NSEvent) {
		if enclosingMenuItem != nil {
			guard let nextResponder = self.nextResponder else {
				return
			}
			
			if nextResponder.try(toPerform: #selector(NSControl.performClick(_:)), with: self) {
				return
			}
			
			guard let
				scrollView = nextResponderChain.flatMap({ $0 as? NSScrollView }).first,
				let tableView = scrollView.documentView as? NSTableView
				else { return }
			
			tableView.try(toPerform: #selector(NSControl.performClick(_:)), with: self)
		}
		else {
			self.nextResponder?.mouseUp(with: theEvent)
		}
	}
}


open class GLAHighlightsTableCellView : GLATableCellView {
	@IBOutlet var collectionIndicationButton: GLACollectionIndicationButton!
}
