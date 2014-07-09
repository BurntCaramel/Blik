//
//  GLAPrototypeAFilesViewController.m
//  Glance Prototype A
//
//  Created by Patrick Smith on 3/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPrototypeAFilesViewController.h"

@interface GLAPrototypeAFilesViewController ()

@end

@implementation GLAPrototypeAFilesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        (self.currentStep) = 1;
    }
    return self;
}

- (NSUInteger)maximumSteps
{
	return 3;
}

- (void)goToNextStep
{
	if ((self.currentStep) < (self.maximumSteps)) {
		(self.currentStep) += 1;
	}
}

- (NSString *)imageNameForStep:(NSUInteger)step
{
	return [NSString stringWithFormat:@"Glance Panel A Working Files %lu", (unsigned long)step];
}

- (IBAction)mainButtonClicked:(id)sender
{
	[self goToNextStep];
	NSString *imageName = [self imageNameForStep:(self.currentStep)];
	NSLog(@"IMAGE %@", imageName);
	NSImage *image = [NSImage imageNamed:imageName];
	NSButton *button = (self.mainButton);
	(button.image) = image;
}

@end
