//
//  GLAArrayUniquePropertyContrainer.h
//  Blik
//
//  Created by Patrick on 9/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAArrayEditor.h"


@interface GLAArrayUniqueKeyPathConstrainer : NSObject <GLAArrayConstraining>

@property(readonly, copy, nonatomic) NSString *keyPath;

- (id)childWhoseKeyPath:(NSString *)keyPath hasValue:(id)value;

@end
