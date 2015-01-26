//
//  NSMutableDictionary+PGWSChecking.m
//  Blik
//
//  Created by Patrick Smith on 23/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "NSMutableDictionary+PGWSChecking.h"

@implementation NSMutableDictionary (PGWSChecking)

- (id)objectForKey:(id<NSCopying>)key addingInstanceOfClassIfNotPresent:(Class)aClass
{
	id object = [self objectForKey:key];
	if (!object) {
		object = [aClass new];
		[self setObject:object forKey:key];
	}
	
	return object;
}

- (id)objectForKey:(id<NSCopying>)key addingResultOfBlockIfNotPresent:(id (^)())block
{
	id object = [self objectForKey:key];
	if (!object) {
		object = block();
		[self setObject:object forKey:key];
	}
	
	return object;
}

@end
