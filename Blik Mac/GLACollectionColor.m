//
//  GLACollectionColor.m
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
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
		_identifier = identifier;
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


+ (instancetype)lightBlue
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierLightBlue];
}

+ (instancetype)green
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierGreen];
}

+ (instancetype)pinkyPurple
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierPinkyPurple];
}

+ (instancetype)red
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierRed];
}

+ (instancetype)yellow
{
	return [[self alloc] initWithIdentifier:GLACollectionColorIdentifierYellow];
}

+ (NSArray *)allAvailableColors
{
	return
	@[
	  [self lightBlue],
	  [self green],
	  [self pinkyPurple],
	  [self red],
	  [self yellow]
	  ];
}

@end


NSString *GLACollectionColorIdentifierLightBlue = @"A.lightBlue";
NSString *GLACollectionColorIdentifierGreen = @"A.green";
NSString *GLACollectionColorIdentifierPinkyPurple = @"A.pinkyPurple";
NSString *GLACollectionColorIdentifierRed = @"A.red";
NSString *GLACollectionColorIdentifierYellow = @"A.yellow";
