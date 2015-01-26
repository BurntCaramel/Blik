//
//  GLAPluckedCollectedFilesMenuController.h
//  Blik
//
//  Created by Patrick Smith on 24/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAPluckedCollectedFilesList.h"


@interface GLAPluckedCollectedFilesMenuController : NSObject

+ (instancetype)sharedMenuController;

@property(nonatomic) IBOutlet NSMenu *pluckedMainMenu;
@property(nonatomic) IBOutlet NSMenuItem *placeAllPluckedItemsMenuItem;
@property(nonatomic) IBOutlet NSMenuItem *pluckedCollectedFilesPlaceholderMenuItem;
@property(nonatomic) IBOutlet NSMenuItem *noPluckedItemsMenuItem;

@property(readonly, nonatomic) GLAPluckedCollectedFilesList *pluckedCollectedFilesList;

- (void)updateMenu;

- (void)placePluckedItemsWithMenuItem:(NSMenuItem *)menuItem intoCollection:(GLACollection *)destinationCollection project:(GLAProject *)destinationProject;

@end


@protocol GLAPluckedCollectedFilesMenuResponder <NSObject>

- (IBAction)pluckSelection:(id)sender;
- (IBAction)clearPluckedFilesList:(id)sender;

- (IBAction)placePluckedCollectedFiles:(id)sender;

@end