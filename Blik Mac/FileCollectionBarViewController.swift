//
//  FileCollectionBar.swift
//  Blik
//
//  Created by Patrick Smith on 17/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation


func changeViewValues<T: NSView>(_ views: [T], animate: Bool, viewBlock: (_ view: NSView) -> Void) {
	for view in views {
		viewBlock(animate ? view.animator() : view)
	}
}


@objc open class FileCollectionBarViewController: GLAViewController {
	@IBOutlet var openInApplicationPopUpButton: NSPopUpButton!
	@IBOutlet var shareButton: GLAButton!
	@IBOutlet var addToHighlightsButton: GLAButton!
	
	var openerApplicationCombinerNotificationObserver: AnyNotificationObserver!
	
	open override func prepareView() {
		super.prepareView()
		
    shareButton.sendAction(on: .leftMouseDown)
		
		startObservingOpenerApplicationCombiner()
	}
	
	@objc open var selectionAssistant: FileCollectionSelectionAssistant? {
		didSet {
			clearObservingOfOpenerApplicationCombiner()
			startObservingOpenerApplicationCombiner()
			
			if let selectionAssistant = selectionAssistant {
				let selectionAssistantNotificationObserver = NotificationObserver<FileCollectionSelectionAssistant.Notification>(object: selectionAssistant)
				selectionAssistantNotificationObserver.observe(.DidUpdate, block: { [weak self] notification in
					self?.update()
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
				openerApplicationCombinerNotificationObserver = AnyNotificationObserver(object: selectionAssistant.openerApplicationCombiner)
			}
			
			openerApplicationCombinerNotificationObserver.observe(NSNotification.Name.GLAFileURLOpenerApplicationCombinerDidChange.rawValue) { [weak self] note in
				self?.setNeedsToUpdateOpenerApplicationsUI()
			}
		}
	}
	
	open func update() {
		_ = self.view
		
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
		
		OperationQueue.main.addOperation {
			self.updateOpenerApplicationMenu()
			
			self.openerApplicationsPopUpButtonNeedsUpdate = false
		}
	}
	
	func updateOpenerApplicationMenu() {
		selectionAssistant?.openerApplicationCombiner.updateOpenerApplicationsPullDownPopUpButton(openInApplicationPopUpButton, target: self, action: #selector(FileCollectionBarViewController.openSelectedFilesInChosenApplication(_:)), preferredApplicationURL: nil)
	}
	
	func updateAddToHighlightsUI() {
		let button = addToHighlightsButton
		
		if let selectionAssistant = selectionAssistant {
			if let collectedFileSource = selectionAssistant.source.collectedFileSource {
				if collectedFileSource.isReadyToHighlight {
					button?.isEnabled = true
					
					let selectionIsAllHighlighted = selectionAssistant.collectedFilesAreAllHighlighted
					
					// If all are already highlighted.
					if selectionIsAllHighlighted {
						button?.title = NSLocalizedString("Remove from Highlights", comment: "Title for 'Remove from Highlights' button when all of the selected collected files are already in the highlights list.");
						button?.action = #selector(FileCollectionBarViewController.removeSelectedFilesFromHighlights(_:))
					}
						// If some or all are not highlighted.
					else {
						button?.title = NSLocalizedString("Add to Highlights", comment: "Title for 'Add to Highlights' button when some of the selected collected files are not yet in the highlights list.");
						button?.action = #selector(FileCollectionBarViewController.addSelectedFilesToHighlights(_:))
					}
				}
				else {
					button?.isEnabled = false
					
					button?.title = NSLocalizedString("Loading Highlights", comment: "Title for 'Add to Highlights' button when the highlights is still loading.")
				}
			}
			else {
				let selectedFilesAreAllCollected = selectionAssistant.selectedFilesAreAllCollected
				
				if selectedFilesAreAllCollected {
					button?.isEnabled = false
					button?.title = NSLocalizedString("Already in Collection", comment: "Title for 'Add to Collection' button when all of the selected files are already in the collection.")
					button?.action = nil
				}
				else {
					button?.isEnabled = true
					button?.title = NSLocalizedString("Add to Collection", comment: "Title for 'Add to Collection' button when some of selected files are not yet in the collection list.");
					button?.action = #selector(FileCollectionBarViewController.addSelectedFilesToCollection(_:))
				}
			}
		}
	}
	
	func updateSelectedFilesUIVisibilityAnimating(_ animate: Bool) {
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
	
	@IBAction func addSelectedFilesToHighlights(_ sender: AnyObject?) {
		selectionAssistant?.addSelectedFilesToHighlights()
		
		updateAddToHighlightsUI()
	}
	
	@IBAction open func removeSelectedFilesFromHighlights(_ sender: AnyObject?) {
		selectionAssistant?.removeSelectedFilesFromHighlights()
		
		updateAddToHighlightsUI()
	}
	
	@IBAction open func addSelectedFilesToCollection(_ sender: AnyObject?) {
		selectionAssistant?.addSelectedFilesToCollection()
	}
	
	@IBAction func openSelectedFilesInChosenApplication(_ sender: AnyObject?) {
		if let menuItem = sender as? NSMenuItem {
			selectionAssistant?.openerApplicationCombiner.openFileURLs(using: menuItem)
		}
	}
	
	var sharingServicePicker: NSSharingServicePicker?
	@IBAction func showShareMenuForSelectedFiles(_ sender: GLAButton) {
		if let selectedFileURLs = selectionAssistant?.source.selectedFileURLs , selectedFileURLs.count > 0 {
			let picker = NSSharingServicePicker(items: selectedFileURLs)
			self.sharingServicePicker = picker
		
			picker.show(relativeTo: sender.insetBounds, of: sender, preferredEdge: NSRectEdge.minY)
		}
	}
}
