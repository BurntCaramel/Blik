//
//  GLACollectionColor.h
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "Mantle/Mantle.h"


@interface GLACollectionColor : MTLModel <MTLJSONSerializing>

@property(readonly, nonatomic) NSString *identifier;

@property(readonly, nonatomic) NSString *localizedName;


- (instancetype)initWithIdentifier:(NSString *)identifier;


+ (instancetype)lightBlue;
+ (instancetype)green;
+ (instancetype)pinkyPurple;
+ (instancetype)red;
+ (instancetype)yellow;

+ (NSArray *)allAvailableColors;

@end


extern NSString *GLACollectionColorIdentifierLightBlue;
extern NSString *GLACollectionColorIdentifierGreen;
extern NSString *GLACollectionColorIdentifierPinkyPurple;
extern NSString *GLACollectionColorIdentifierRed;
extern NSString *GLACollectionColorIdentifierYellow;
