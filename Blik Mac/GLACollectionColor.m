//
//  GLACollectionColor.m
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLACollectionColor.h"


@interface GLACollectionColor ()

@property(readwrite, nonatomic) NSString *identifier;

@property(readwrite, nonatomic) NSString *localizedName;

@end

@implementation GLACollectionColor

- (instancetype)initWithIdentifier:(NSString *)identifier
{
	self = [super init];
	if (self) {
		_identifier = [identifier copy];
	}
	return self;
}

- (instancetype)init
{
	return [self initWithIdentifier:nil];
}

- (BOOL)isEqual:(GLACollectionColor *)color
{
	if (self == color) return YES;
	if (!color || ![color isMemberOfClass:self.class]) return NO;
	
	return [(color.identifier) isEqual:(self.identifier)];
}

- (NSUInteger)hash
{
	return (self.identifier.hash);
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}


+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"identifier": @"identifier",
	  @"localizedName": [NSNull null]
	  };
}


+ (instancetype)pastelLightBlue
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierPastelLightBlue];
}

+ (instancetype)pastelGreen
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierPastelGreen];
}

+ (instancetype)pastelPinkyPurple
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierPastelPinkyPurple];
}

+ (instancetype)pastelRed
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierPastelRed];
}

+ (instancetype)pastelYellow
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierPastelYellow];
}

+ (instancetype)strongRed
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierStrongRed];
}

+ (instancetype)strongYellow
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierStrongYellow];
}

+ (instancetype)strongPurple
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierStrongPurple];
}

+ (instancetype)strongBlue
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierStrongBlue];
}

+ (instancetype)strongPink
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierStrongPink];
}

+ (instancetype)strongOrange
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierStrongOrange];
}

+ (instancetype)strongGreen
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierStrongGreen];
}

+ (NSArray *)allPastelColors
{
	return
	@[
	  [self pastelLightBlue],
	  [self pastelGreen],
	  [self pastelPinkyPurple],
	  [self pastelRed],
	  [self pastelYellow]
	  ];
}

+ (NSArray *)allStrongColors
{
	return
	@[
	  [self strongBlue],
	  [self strongGreen],
	  [self strongPurple],
	  [self strongPink],
	  [self strongRed],
	  [self strongOrange],
		[self strongYellow]
	  ];
}

+ (NSArray *)allAvailableColors
{
	return
	[[self allPastelColors]
	 arrayByAddingObjectsFromArray:[self allStrongColors]
	 ];
}

@end


NSString *GLACollectionColorIdentifierPastelLightBlue = @"A.lightBlue";
NSString *GLACollectionColorIdentifierPastelGreen = @"A.green";
NSString *GLACollectionColorIdentifierPastelPinkyPurple = @"A.pinkyPurple";
NSString *GLACollectionColorIdentifierPastelRed = @"A.red";
NSString *GLACollectionColorIdentifierPastelYellow = @"A.yellow";
//NSString *GLACollectionColorIdentifierPastelBlushRed = @"A.blushRed";

//NSString *GLACollectionColorIdentifierMediumRed = @"B.red";

NSString *GLACollectionColorIdentifierStrongRed = @"C.red";
NSString *GLACollectionColorIdentifierStrongYellow = @"C.yellow";
NSString *GLACollectionColorIdentifierStrongPurple = @"C.purple";
NSString *GLACollectionColorIdentifierStrongBlue = @"C.blue";
NSString *GLACollectionColorIdentifierStrongPink = @"C.pink";
NSString *GLACollectionColorIdentifierStrongOrange = @"C.orange";
NSString *GLACollectionColorIdentifierStrongGreen = @"C.green";
