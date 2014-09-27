//
//  GLAArrayEditor.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAArrayEditing.h"


@interface GLAArrayEditor : NSObject <GLAArrayEditing>

- (instancetype)initWithObjects:(NSArray *)objects;

- (void)replaceChildWithValueForKey:(NSString *)key equalToValue:(id)value withObject:(id)object;

@end

extern NSString *GLAArrayEditorDidChangeNotification;
