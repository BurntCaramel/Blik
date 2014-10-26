//
//  GLAProjectHighlightsViewController.h
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAProject.h"
#import "GLAHighlightedItem.h"

@class GLAProjectViewController;


@interface GLAProjectHighlightsViewController : GLAViewController <NSTableViewDelegate, NSTableViewDataSource>

@property(nonatomic) IBOutlet NSTableView *tableView;
@property(nonatomic) IBOutlet NSLayoutConstraint *scrollLeadingConstraint;

@property(weak) IBOutlet GLAProjectViewController *parentViewController;

@property(nonatomic) GLAProject *project;
@property(nonatomic) NSArray *highlightedItems;

@end
