//
//  NSOperationQueue+PGWSBlockConvenience.h
//  Blik
//
//  Created by Patrick Smith on 13/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;


@interface NSOperationQueue (PGWSBlockOperationConvenience)

- (NSBlockOperation *)pgws_useObject:(id)object inAddedOperationBlock:(void (^)(id object))block;

@end
