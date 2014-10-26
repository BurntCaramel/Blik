//
//  GLAPrototypeAFilesViewController.h
//  Blik
//
//  Created by Patrick Smith on 3/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLAPrototypeAFilesViewController : NSViewController

@property (nonatomic) NSUInteger currentStep;
@property (readonly, nonatomic) NSUInteger maximumSteps;

@property (nonatomic) IBOutlet NSButton *mainButton;

- (IBAction)mainButtonClicked:(id)sender;

@end
