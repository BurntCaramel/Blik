//
//  GLAProjectInstructionsViewController.m
//  Blik
//
//  Created by Patrick Smith on 5/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAInstructionsViewController.h"
#import "GLAUIStyle.h"


@interface GLAInstructionsViewController ()

@end

@implementation GLAInstructionsViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSTextField *mainTextLabel = (self.mainTextLabel);
	if (mainTextLabel) {
		[uiStyle prepareInstructionalTextLabel:mainTextLabel];
	}
	
	NSTextField *secondaryTextLabel = (self.secondaryTextLabel);
	if (secondaryTextLabel) {
		[uiStyle prepareSecondaryInstructionalTextLabel:secondaryTextLabel];
	}
	
	NSTextField *headingTextLabel = (self.headingTextLabel);
	if (headingTextLabel) {
		[uiStyle prepareInstructionalHeadingLabel:headingTextLabel];
	}
}

@end
