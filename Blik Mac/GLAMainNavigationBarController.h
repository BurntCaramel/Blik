//
//  GLAMainNavigationBarController.h
//  Blik
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAPrototypeBNavigationBar.h"


typedef NS_ENUM(NSInteger, GLAMainNavigationSection) {
	GLAMainNavigationSectionAll,
	GLAMainNavigationSectionToday,
	GLAMainNavigationSectionPlanned
};

@protocol GLAMainNavigationBarControllerDelegate;


@interface GLAMainNavigationBarController : NSViewController <GLAViewDelegate>

@property(readonly, nonatomic) GLAPrototypeBNavigationBar *navigationBar;

@property(nonatomic) IBOutlet NSButton *allButton;
@property(nonatomic) IBOutlet NSButton *todayButton;
@property(nonatomic) IBOutlet NSButton *plannedButton;
@property(nonatomic) IBOutlet NSButton *addProjectButton;
@property(nonatomic) IBOutlet NSButton *editingProjectBackButton;

@property(nonatomic) IBOutlet NSLayoutConstraint *allButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *todayButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *plannedButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *addProjectButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *editingProjectBackButtonLeadingConstraint;

@property(nonatomic) GLAMainNavigationSection currentSection;

@property(weak, nonatomic) id<GLAMainNavigationBarControllerDelegate> delegate;

- (IBAction)goToAll:(id)sender;
- (IBAction)goToToday:(id)sender;
- (IBAction)goToPlanned:(id)sender;

- (void)enterProject:(id)project;
@property(nonatomic) id currentProject;
- (IBAction)exitCurrentProject:(id)sender;

@property(nonatomic, getter = isEnabled) BOOL enabled;

@end


@protocol GLAMainNavigationBarControllerDelegate <NSObject>

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didChangeCurrentSection:(GLAMainNavigationSection)newSection;

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didExitProject:(id)project;
@end