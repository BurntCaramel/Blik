//
//  GLAMainNavigationBarController.h
//  Blik
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
// VIEW
#import "GLAViewController.h"
#import "GLANavigationBar.h"
#import "GLAButton.h"
#import "GLANavigationButton.h"
#import "GLASegmentedControl.h"
#import "GLANavigationButtonGroup.h"
// MODEL
#import "GLAProject.h"
#import "GLACollection.h"
#import "GLAMainSection.h"
#import "GLAMainSectionNavigator.h"
@class GLAMainNavigationButtonGroup;


typedef NS_ENUM(NSInteger, GLAMainNavigationSection) {
	GLAMainNavigationSectionAll,
	GLAMainNavigationSectionToday,
	GLAMainNavigationSectionPlanned
};

@protocol GLAMainNavigationBarControllerDelegate;


@interface GLAMainNavigationBarController : GLAViewController <GLAViewDelegate>

@property(nonatomic) GLAMainSectionNavigator *sectionNavigator;

@property(readonly, nonatomic) GLAMainSection *currentSection;

@property(weak, nonatomic) id<GLAMainNavigationBarControllerDelegate> delegate;

@property(nonatomic, getter = isEnabled) BOOL enabled;

#pragma mark -

@property(readonly, nonatomic) GLANavigationBar *navigationBar;

@property(nonatomic) IBOutlet GLANavigationButton *allButton;
@property(nonatomic) IBOutlet GLANavigationButton *todayButton;
@property(nonatomic) IBOutlet GLANavigationButton *plannedButton;
@property(nonatomic) IBOutlet GLANavigationButton *addProjectButton;

@property(nonatomic) IBOutlet GLAButton *templateButton;

@property(nonatomic) IBOutlet NSArray *allVisibleButtons;

@property(nonatomic) IBOutlet GLAButton *editingProjectBackButton;
@property(nonatomic) IBOutlet GLAButton *editingProjectWorkOnNowButton;

@property(nonatomic) GLAMainNavigationButtonGroup *editingProjectPrimaryFoldersButtonGroup;
@property(nonatomic) IBOutlet GLAButton *editingProjectPrimaryFoldersBackButton;

@property(nonatomic) IBOutlet GLAButton *addingNewProjectCancelButton;
@property(nonatomic) IBOutlet GLAButton *addingNewProjectConfirmButton;
@property(nonatomic) GLAMainNavigationButtonGroup *addingNewProjectButtonGroup;

@property(nonatomic) IBOutlet GLAButton *collectionTitleButton;
@property(nonatomic) IBOutlet GLAButton *collectionBackButton;
@property(nonatomic) IBOutlet GLASegmentedControl *collectionViewModeSegmentedControl;
@property(nonatomic) GLANavigationButtonGroup *collectionButtonGroup;

@property(nonatomic) GLAMainNavigationButtonGroup *addNewCollectionButtonGroup;

@property(nonatomic) IBOutlet NSLayoutConstraint *allButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *todayButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *plannedButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *addProjectButtonTopConstraint;

- (void)didChangeCurrentSectionFrom:(GLAMainSection *)previousSection to:(GLAMainSection *)newSection;

- (IBAction)goToAll:(id)sender;
- (IBAction)goToNowProject:(id)sender;

#pragma mark -

- (GLAProject *)currentProject;
- (GLACollection *)currentCollection;

- (IBAction)workOnCurrentProjectNow:(id)sender;
- (IBAction)exitEditedProject:(id)sender;

- (IBAction)addNewProject:(id)sender;
- (IBAction)cancelAddingNewProject:(id)sender;

- (IBAction)exitEditedCollection:(id)sender;

- (void)updateSelectedSectionUI;

@end


@protocol GLAMainNavigationBarControllerDelegate <NSObject>

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller handleWorkNowOnProject:(GLAProject *)project;

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller handleEditDetailsForCollection:(GLACollection *)collection fromButton:(GLAButton *)button;

@end
