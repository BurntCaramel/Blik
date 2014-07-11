//
//  GLAMainNavigationBarController.h
//  Glance Prototype A
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef NS_ENUM(NSInteger, GLAMainNavigationSection) {
	GLAMainNavigationSectionAll,
	GLAMainNavigationSectionToday,
	GLAMainNavigationSectionPlanned
};

@protocol GLAMainNavigationBarControllerDelegate;


@interface GLAMainNavigationBarController : NSViewController

@property (nonatomic) IBOutlet NSButton *allButton;
@property (nonatomic) IBOutlet NSButton *todayButton;
@property (nonatomic) IBOutlet NSButton *plannedButton;

@property (nonatomic) GLAMainNavigationSection currentSection;

@property (weak, nonatomic) id<GLAMainNavigationBarControllerDelegate> delegate;

- (IBAction)goToAll:(id)sender;
- (IBAction)goToToday:(id)sender;
- (IBAction)goToPlanned:(id)sender;

@end


@protocol GLAMainNavigationBarControllerDelegate <NSObject>

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didChangeCurrentSection:(GLAMainNavigationSection)newSection;

@end