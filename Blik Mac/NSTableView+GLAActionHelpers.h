//
//  NSTableView+GLAActionHelpers.h
//  Blik
//
//  Created by Patrick Smith on 18/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;


@interface NSTableView (GLAActionHelpers)

- (NSIndexSet *)gla_rowIndexesForActionFrom:(id)sender;

@end
