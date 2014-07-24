//
//  GLAMainNavigationBarController.h
//  Blik
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAViewController.h"
#import "GLAPrototypeBNavigationBar.h"


typedef NS_ENUM(NSInteger, GLAMainNavigationSection) {
	GLAMainNavigationSectionAll,
	GLAMainNavigationSectionToday,
	GLAMainNavigationSectionPlanned
};

@protocol GLAMainNavigationBarControllerDelegate;


@interface GLAMainNavigationBarController : GLAViewController <GLAViewDelegate>

@property(readonly, nonatomic) GLAPrototypeBNavigationBar *navigationBar;

@property(nonatomic) IBOutlet NSButton *allButton;
@property(nonatomic) IBOutlet NSButton *todayButton;
@property(nonatomic) IBOutlet NSButton *plannedButton;
@property(nonatomic) IBOutlet NSButton *addProjectButton;

@property(nonatomic) IBOutlet NSButton *templateButton;

@property(nonatomic) IBOutlet NSButton *editingProjectBackButton;

@property(nonatomic) IBOutlet NSButton *addingNewProjectCancelButton;
@property(nonatomic) IBOutlet NSButton *addingNewProjectConfirmButton;

@property(nonatomic) IBOutlet NSLayoutConstraint *allButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *todayButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *plannedButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *addProjectButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *editingProjectBackButtonLeadingConstraint;

@property(nonatomic) GLAMainNavigationSection currentSection;

@property(weak, nonatomic) id<GLAMainNavigationBarControllerDelegate> delegate;

@property(nonatomic, getter = isEnabled) BOOL enabled;

- (IBAction)goToAll:(id)sender;
- (IBAction)goToToday:(id)sender;
- (IBAction)goToPlanned:(id)sender;

- (IBAction)addNewProject:(id)sender;

- (void)enterProject:(id)project;
- (void)enterAddedProject:(id)project;
@property(nonatomic) id currentProject;
@property(nonatomic) BOOL currentProjectIsAddedNew;
- (IBAction)exitCurrentProject:(id)sender;

@end


@protocol GLAMainNavigationBarControllerDelegate <NSObject>

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didChangeCurrentSection:(GLAMainNavigationSection)newSection;

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performAddNewProject:(id)sender;

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didExitProject:(id)project;
@end