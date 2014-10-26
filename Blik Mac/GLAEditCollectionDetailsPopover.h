//
//  GLAEditCollectionDetailsPopover.h
//  Blik
//
//  Created by Patrick Smith on 20/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
#import "GLAEditCollectionDetailsViewController.h"


@interface GLAEditCollectionDetailsPopover : NSPopover

+ (instancetype)sharedEditCollectionDetailsPopover;

@property(strong, nonatomic) GLAEditCollectionDetailsViewController *editCollectionDetailsViewController;

- (void)setUpWithCollection:(GLACollection *)collection;

@property(nonatomic) NSString *chosenName;
@property(nonatomic) GLACollectionColor *chosenCollectionColor;

@end

extern NSString *GLAEditCollectionDetailsPopoverChosenNameDidChangeNotification;
extern NSString *GLAEditCollectionDetailsPopoverChosenColorDidChangeNotification;

