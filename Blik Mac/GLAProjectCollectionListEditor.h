//
//  GLAProjectCollectionListEditor.h
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLACollection.h"


@interface GLAProjectCollectionListEditor : NSObject <GLACollectionListEditing>

- (instancetype)initWithCollections:(NSArray *)collections;

@end
