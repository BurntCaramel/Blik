//
//  NSValueTransformer+GLAModel.h
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "Mantle/Mantle.h"


extern NSString *const GLAUUIDValueTransformerName;
extern NSString *const GLADataBase64ValueTransformerName;
extern NSString *const GLADateRFC3339ValueTransformerName;


@interface NSValueTransformer (GLAModel)

+ (instancetype)GLA_UUIDValueTransformer;
+ (instancetype)GLA_DataBase64ValueTransformer;
+ (instancetype)GLA_DateRFC3339ValueTransformer;

@end
