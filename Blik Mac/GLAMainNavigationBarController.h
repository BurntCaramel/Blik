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

@property(nonatomic) IBOutlet GLAButton *editingProjectBackButton;

@property(nonatomic) IBOutlet GLAButton *addingNewProjectCancelButton;
@property(nonatomic) IBOutlet GLAButton *addingNewProjectConfirmButton;

@property(nonatomic) IBOutlet GLAButton *collectionTitleButton;

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

#pragma mark Projects

- (IBAction)addNewProject:(id)sender;

- (void)enterProject:(GLAProject *)project;
- (void)enterAddedProject:(GLAProject *)project;

@property(nonatomic) GLAProject *currentProject;
@property(nonatomic) BOOL currentProjectIsAddedNew;

- (IBAction)exitCurrentProject:(id)sender;

- (IBAction)cancelAddingNewProject:(id)sender;

- (IBAction)confirmAddingNewProject:(id)sender;

#pragma mark Collections

- (void)enterProjectCollection:(GLACollection *)collection;

@property(nonatomic) GLACollection *currentCollection;

- (IBAction)exitCurrentCollection:(id)sender;

@end


@protocol GLAMainNavigationBarControllerDelegate <NSObject>

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didChangeCurrentSection:(GLAMainNavigationSection)newSection;

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performAddNewProject:(id)sender;

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didExitProject:(id)project;
@end