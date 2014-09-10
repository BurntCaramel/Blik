//
//  GLACollectionContent.h
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "Mantle/Mantle.h"
#import "GLACollection.h"


// Subclassed
@interface GLACollectionContent : MTLModel <MTLJSONSerializing>

@end


@interface GLACollectionContentItem : MTLModel <GLACollectedItem, MTLJSONSerializing>

@property (copy, readonly, nonatomic) NSString *title;

@end
