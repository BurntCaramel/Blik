//
//  GLACollectionColor.h
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "Mantle/Mantle.h"


@interface GLACollectionColor : MTLModel <MTLJSONSerializing>

@property(readonly, nonatomic) NSString *identifier;

@property(readonly, nonatomic) NSString *localizedName;


- (instancetype)initWithIdentifier:(NSString *)identifier;



+ (instancetype)pastelLightBlue;
+ (instancetype)pastelGreen;
+ (instancetype)pastelPinkyPurple;
+ (instancetype)pastelRed;
+ (instancetype)pastelYellow;
//+ (instancetype)pastelBlushRed;
//+ (instancetype)pastelPurplyBlue;

+ (instancetype)strongRed;
+ (instancetype)strongYellow;
+ (instancetype)strongPurple;
+ (instancetype)strongBlue;
+ (instancetype)strongPink;
+ (instancetype)strongOrange;
+ (instancetype)strongGreen;

+ (NSArray *)allPastelColors;
+ (NSArray *)allStrongColors;
+ (NSArray *)allAvailableColors;

@end


extern NSString *GLACollectionColorIdentifierPastelLightBlue;
extern NSString *GLACollectionColorIdentifierPastelGreen;
extern NSString *GLACollectionColorIdentifierPastelPinkyPurple;
extern NSString *GLACollectionColorIdentifierPastelRed;
extern NSString *GLACollectionColorIdentifierPastelYellow;

extern NSString *GLACollectionColorIdentifierStrongRed;
extern NSString *GLACollectionColorIdentifierStrongYellow;
extern NSString *GLACollectionColorIdentifierStrongPurple;
extern NSString *GLACollectionColorIdentifierStrongBlue;
extern NSString *GLACollectionColorIdentifierStrongPink;
extern NSString *GLACollectionColorIdentifierStrongOrange;
extern NSString *GLACollectionColorIdentifierStrongGreen;
