//
//  NSValueTransformer+GLAModel.h
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "Mantle/Mantle.h"


extern NSString * const GLAUUIDValueTransformerName;


@interface NSValueTransformer (GLAModel)

+ (instancetype)GLA_UUIDValueTransformer;

@end
