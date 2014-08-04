//
//  GLAProject.h
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLACollection.h"
#import "GLAReminder.h"
#import "GLAArrayEditing.h"
#import "Mantle/Mantle.h"


@interface GLAProject : MTLModel

@property(readonly, nonatomic) NSUUID *UUID;

@property(copy, nonatomic) NSString *name;

@property(readonly, copy, nonatomic) NSArray *copyCollections;
- (id<GLAArrayEditing>)collectionsEditing;

//@property(readonly, copy, nonatomic) NSSet *copyReminders;
@property(readonly, copy, nonatomic) NSArray *copyRemindersOrderedByPriority;
- (id<GLAReminderListEditing>)remindersEditing;

@end
