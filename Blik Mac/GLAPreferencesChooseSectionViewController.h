//
//  GLAPreferencesChooseSectionViewController.h
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"


@protocol GLAPreferencesChooseSectionViewControllerDelegate;

@interface GLAPreferencesChooseSectionViewController : GLAViewController

@property(weak, nonatomic) id<GLAPreferencesChooseSectionViewControllerDelegate> delegate;

@property(nonatomic) IBOutlet NSTextField *editPermittedApplicationFoldersLabel;
@property(nonatomic) IBOutlet NSButton *editPermittedApplicationFoldersButton;
@property(copy, nonatomic) NSString *editPermittedApplicationFoldersButtonIdentifier;

@property(nonatomic) IBOutlet NSButton *showStatusMenuItemCheckButton;
- (IBAction)toggleShowStatusMenuItem:(id)sender;

@property(nonatomic) IBOutlet NSButton *hideMainWindowWhenInactiveCheckButton;
- (IBAction)toggleHideMainWindowWhenInactive:(id)sender;

@end


@protocol GLAPreferencesChooseSectionViewControllerDelegate

- (void)preferencesChooseSectionViewControllerDelegate:(GLAPreferencesChooseSectionViewController *)vc goToSectionWithIdentifier:(NSString *)sectionIdentifier;

@end