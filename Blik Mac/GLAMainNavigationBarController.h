//
//  GLAMainNavigationBarController.h
//  Blik
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAViewController.h"
#import "GLANavigationBar.h"
#import "GLAButton.h"
#import "GLANavigationButton.h"
#import "GLAProject.h"
#import "GLACollection.h"
#import "GLAMainContentSection.h"
@class GLAMainNavigationButtonGroup;


typedef NS_ENUM(NSInteger, GLAMainNavigationSection) {
	GLAMainNavigationSectionAll,
	GLAMainNavigationSectionToday,
	GLAMainNavigationSectionPlanned
};

@protocol GLAMainNavigationBarControllerDelegate;


@interface GLAMainNavigationBarController : GLAViewController <GLAViewDelegate>

@property(readonly, nonatomic) GLANavigationBar *navigationBar;

@property(nonatomic) IBOutlet GLANavigationButton *allButton;
@property(nonatomic) IBOutlet GLANavigationButton *todayButton;
@property(nonatomic) IBOutlet GLANavigationButton *plannedButton;
@property(nonatomic) IBOutlet GLANavigationButton *addProjectButton;

@property(nonatomic) IBOutlet GLAButton *templateButton;

@property(nonatomic) IBOutlet NSArray *allVisibleButtons;

@property(nonatomic) IBOutlet GLAButton *editingProjectBackButton;
@property(nonatomic) IBOutlet GLAButton *editingProjectWorkOnNowButton;

@property(nonatomic) IBOutlet GLAButton *addingNewProjectCancelButton;
@property(nonatomic) IBOutlet GLAButton *addingNewProjectConfirmButton;
@property(nonatomic) GLAMainNavigationButtonGroup *addingNewProjectButtonGroup;

@property(nonatomic) IBOutlet GLAButton *collectionTitleButton;
@property(nonatomic) IBOutlet GLAButton *collectionBackButton;
@property(nonatomic) GLAMainNavigationButtonGroup *collectionButtonGroup;

@property(nonatomic) IBOutlet NSLayoutConstraint *allButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *todayButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *plannedButtonTopConstraint;
@property(nonatomic) IBOutlet NSLayoutConstraint *addProjectButtonTopConstraint;

@property(readonly, nonatomic) GLAMainContentSection *currentSection;

@property(weak, nonatomic) id<GLAMainNavigationBarControllerDelegate> delegate;

@property(nonatomic, getter = isEnabled) BOOL enabled;

- (void)changeCurrentSectionTo:(GLAMainContentSection *)newSection;

- (void)performChangeCurrentSectionTo:(GLAMainContentSection *)newSection;
- (IBAction)goToAll:(id)sender;
- (IBAction)goToToday:(id)sender;
- (IBAction)goToPlanned:(id)sender;

#pragma mark Projects

- (IBAction)workOnCurrentProjectNow:(id)sender;
- (IBAction)exitEditedProject:(id)sender;

- (IBAction)addNewProject:(id)sender;
- (IBAction)cancelAddingNewProject:(id)sender;
- (IBAction)confirmAddingNewProject:(id)sender;

- (IBAction)exitEditedCollection:(id)sender;

@end


@protocol GLAMainNavigationBarControllerDelegate <NSObject>

//- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller wantsToChangeSection:(GLAMainContentSection *)newSection;

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performChangeCurrentSectionTo:(GLAMainContentSection *)newSection;

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performAddNewProject:(id)sender;
- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performConfirmNewProject:(id)sender;

- (void)mainNavigationBarControllerDidExitEditedProject:(GLAMainNavigationBarController *)controller;

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performWorkOnProjectNow:(GLAProject *)project;

- (void)mainNavigationBarControllerDidExitEditedCollection:(GLAMainNavigationBarController *)controller;

@end
