//
//  NSOperationQueue+PGWSBlockConvenience.m
//  Blik
//
//  Created by Patrick Smith on 13/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "NSOperationQueue+PGWSBlockConvenience.h"

@implementation NSOperationQueue (PGWSBlockConvenience)

- (NSBlockOperation *)pgws_useObject:(id)object inAddedOperationBlock:(void (^)(id object))block
{
	__weak id weakObject = object;
	
	NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
		id strongObject = weakObject;
		
		block(strongObject);
	}];
	[self addOperation:blockOperation];
	
	return blockOperation;
}

@end
