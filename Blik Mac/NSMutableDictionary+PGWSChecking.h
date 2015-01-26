//
//  NSMutableDictionary+PGWSChecking.h
//  Blik
//
//  Created by Patrick Smith on 23/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableDictionary (PGWSChecking)

- (id)objectForKey:(id<NSCopying>)key addingInstanceOfClassIfNotPresent:(Class)aClass;

- (id)objectForKey:(id<NSCopying>)key addingResultOfBlockIfNotPresent:(id (^)())block;

@end
