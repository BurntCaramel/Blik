//
//  GLAProjectOverviewTableCellView.h
//  Blik
//
//  Created by Patrick Smith on 12/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLANavigationButton.h"

@interface GLAProjectOverviewTableCellView : NSTableCellView

@property(weak, nonatomic) IBOutlet GLANavigationButton *deleteProjectButton;

@end
