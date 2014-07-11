//
//  GLAMainNavigationBarController.m
//  Glance Prototype A
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAMainNavigationBarController.h"

@interface GLAMainNavigationBarController ()

@end

@implementation GLAMainNavigationBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		(self.currentSection) = GLAMainNavigationSectionToday;
		[self updateSelectedSectionUI];
    }
    return self;
}

- (void)awakeFromNib
{
	
}

- (void)updateSelectedSectionUI
{
	GLAMainNavigationSection currentSection = (self.currentSection);
	(self.allButton.state) = (currentSection == GLAMainNavigationSectionAll) ? NSOnState : NSOffState;
	(self.todayButton.state) = (currentSection == GLAMainNavigationSectionToday) ? NSOnState : NSOffState;
	(self.plannedButton.state) = (currentSection == GLAMainNavigationSectionPlanned) ? NSOnState : NSOffState;
}

- (void)changeCurrentSectionTo:(GLAMainNavigationSection)newSection
{
	(self.currentSection) = newSection;
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self didChangeCurrentSection:newSection];
	}
	
	[self updateSelectedSectionUI];
}

- (IBAction)goToAll:(id)sender
{
	[self changeCurrentSectionTo:GLAMainNavigationSectionAll];
}

- (IBAction)goToToday:(id)sender
{
	[self changeCurrentSectionTo:GLAMainNavigationSectionToday];
}

- (IBAction)goToPlanned:(id)sender
{
	[self changeCurrentSectionTo:GLAMainNavigationSectionPlanned];
}

@end
