//
//  FileCollectionBar.swift
//  Blik
//
//  Created by Patrick Smith on 17/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation


func changeViewValues<T: NSView>(views: [T], #animate: Bool, #viewBlock: (view: NSView) -> Void) {
	for view in views {
		viewBlock(view: animate ? view.animator() : view)
	}
}


@objc public class FileCollectionBarViewController: GLAViewController {
	@IBOutlet var openInApplicationPopUpButton: NSPopUpButton!
	@IBOutlet var shareButton: GLAButton!
	@IBOutlet var addToHighlightsButton: GLAButton!
	
	var openerApplicationCombinerNotificationObserver: NotificationObserver<AnyStringNotificationIdentifier>!
	
	public override func prepareView() {
		super.prepareView()
		
		shareButton.sendActionOn(
			Int(NSEventMask.LeftMouseDownMask.rawValue)
		)
		
		startObservingOpenerApplicationCombiner()
	}
	
	@objc public var selectionAssistant: FileCollectionSelectionAssistant? {
		didSet {
			clearObservingOfOpenerApplicationCombiner()
			startObservingOpenerApplicationCombiner()
			
			if let selectionAssistant = selectionAssistant {
				let selectionAssistantNotificationObserver = NotificationObserver<FileCollectionSelectionAssistant.Notification>(object: selectionAssistant)
				selectionAssistantNotificationObserver.addObserver(.DidUpdate, block: { [unowned self] notification in
					self.update()
				})
				
				self.selectionAssistantNotificationObserver = selectionAssistantNotificationObserver
			}
			else {
				selectionAssistantNotificationObserver = nil
			}
			
			update()
		}
	}
	
	var selectionAssistantNotificationObserver: NotificationObserver<FileCollectionSelectionAssistant.Notification>?
	
	func clearObservingOfOpenerApplicationCombiner() {
		openerApplicationCombinerNotificationObserver = nil
	}
	
	func startObservingOpenerApplicationCombiner() {
		if let selectionAssistant = selectionAssistant {
			if openerApplicationCombinerNotificationObserver == nil {
				openerApplicationCombinerNotificationObserver = NotificationObserver<AnyStringNotificationIdentifier>(object: selectionAssistant.openerApplicationCombiner)
			}
			
			let nc = NSNotificationCenter.defaultCenter()
			
			openerApplicationCombinerNotificationObserver.addObserver(GLAFileURLOpenerApplicationCombinerDidChangeNotification) { [unowned self] note in
				self.setNeedsToUpdateOpenerApplicationsUI()
			}
		}
	}
	
	public func update() {
		let view = self.view
		
		//updateAddToHighlightsUI()
		updateSelectedFilesUIVisibilityAnimating(false)
		updateOpenerApplicationMenu()
	}
	
	var openerApplicationsPopUpButtonNeedsUpdate = false
	func setNeedsToUpdateOpenerApplicationsUI() {
		if openerApplicationsPopUpButtonNeedsUpdate {
			return
		}
		
		openerApplicationsPopUpButtonNeedsUpdate = true
		
		NSOperationQueue.mainQueue().addOperationWithBlock {
			self.updateOpenerApplicationMenu()
			
			self.openerApplicationsPopUpButtonNeedsUpdate = false
		}
	}
	
	func updateOpenerApplicationMenu() {
		selectionAssistant?.openerApplicationCombiner.updateOpenerApplicationsPullDownPopUpButton(openInApplicationPopUpButton, target: self, action: "openSelectedFilesInChosenApplication:", preferredApplicationURL: nil)
	}
	
	func updateAddToHighlightsUI() {
		let button = addToHighlightsButton
		
		if let selectionAssistant = selectionAssistant {
			if let collectedFileSource = selectionAssistant.source.collectedFileSource {
				if collectedFileSource.isReadyToHighlight {
					button.enabled = true
					
					let selectionIsAllHighlighted = selectionAssistant.collectedFilesAreAllHighlighted
					
					// If all are already highlighted.
					if selectionIsAllHighlighted {
						button.title = NSLocalizedString("Remove from Highlights", comment: "Title for 'Remove from Highlights' button when all of the selected collected files are already in the highlights list.");
						button.action = "removeSelectedFilesFromHighlights:"
					}
						// If some or all are not highlighted.
					else {
						button.title = NSLocalizedString("Add to Highlights", comment: "Title for 'Add to Highlights' button when some of the selected collected files are not yet in the highlights list.");
						button.action = "addSelectedFilesToHighlights:"
					}
				}
				else {
					button.enabled = false
					
					button.title = NSLocalizedString("Loading Highlights", comment: "Title for 'Add to Highlights' button when the highlights is still loading.")
				}
			}
			else {
				let selectedFilesAreAllCollected = selectionAssistant.selectedFilesAreAllCollected
				
				if selectedFilesAreAllCollected {
					button.enabled = false
					button.title = NSLocalizedString("Already in Collection", comment: "Title for 'Add to Collection' button when all of the selected files are already in the collection.")
					button.action = nil
				}
				else {
					button.enabled = true
					button.title = NSLocalizedString("Add to Collection", comment: "Title for 'Add to Collection' button when some of selected files are not yet in the collection list.");
					button.action = "addSelectedFilesToCollection:"
				}
			}
		}
	}
	
	func updateSelectedFilesUIVisibilityAnimating(animate: Bool) {
		let views: [NSView] = [
			openInApplicationPopUpButton,
			addToHighlightsButton,
			shareButton
		]
		
		let hasNoURLs = (selectionAssistant?.source.selectedFileURLs.count ?? 0) == 0
		let alphaValue: CGFloat = hasNoURLs ? 0.0 : 1.0
		
		if animate {
			if !hasNoURLs {
				updateAddToHighlightsUI()
			}
			
			NSAnimationContext.runAnimationGroup(
				{ context in
					context.duration = 3.0 / 16.0;
					context.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseIn)
				
					changeViewValues(views, animate: true, viewBlock: { (view) -> Void in
						view.alphaValue = alphaValue
					})
				},
				completionHandler: {
					if (hasNoURLs) {
						self.updateAddToHighlightsUI()
					}
				}
			)
		}
		else {
			updateAddToHighlightsUI()
		
			changeViewValues(views, animate: false) { view in
				view.alphaValue = alphaValue
			}
		}
	}
	
	@IBAction func addSelectedFilesToHighlights(sender: AnyObject?) {
		selectionAssistant?.addSelectedFilesToHighlights()
		
		updateAddToHighlightsUI()
	}
	
	@IBAction public func removeSelectedFilesFromHighlights(sender: AnyObject?) {
		selectionAssistant?.removeSelectedFilesFromHighlights()
		
		updateAddToHighlightsUI()
	}
	
	@IBAction public func addSelectedFilesToCollection(sender: AnyObject?) {
		selectionAssistant?.addSelectedFilesToCollection()
	}
	
	@IBAction func openSelectedFilesInChosenApplication(sender: AnyObject?) {
		if let menuItem = sender as? NSMenuItem {
			selectionAssistant?.openerApplicationCombiner.openFileURLsUsingMenuItem(menuItem)
		}
	}
	
	var sharingServicePicker: NSSharingServicePicker?
	@IBAction func showShareMenuForSelectedFiles(sender: GLAButton) {
		if let selectedFileURLs = selectionAssistant?.source.selectedFileURLs where selectedFileURLs.count > 0 {
			let picker = NSSharingServicePicker(items: selectedFileURLs)
			self.sharingServicePicker = picker
		
			picker.showRelativeToRect(sender.insetBounds, ofView: sender, preferredEdge: NSMinYEdge)
		}
	}
}
