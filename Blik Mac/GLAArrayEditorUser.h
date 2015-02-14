//
//  GLAArrayEditorUser.h
//  Blik
//
//  Created by Patrick Smith on 13/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAArrayEditor.h"


typedef GLAArrayEditor *(^ GLAArrayEditorUserAccessingBlock)(BOOL createIfNeeded, BOOL loadIfNeeded);
typedef void (^ GLAArrayEditorUserLoadingBlock)(GLAArrayEditor *arrayEditor, dispatch_block_t callWhenLoaded);
typedef void (^ GLAArrayEditorUserEditBlock)(GLAArrayEditingBlock editingBlock);


@interface GLAArrayEditorUser : NSObject <GLALoadableArrayUsing>

- (instancetype)initWithOwner:(id)owner accessingBlock:(GLAArrayEditorUserAccessingBlock)accessingBlock editBlock:(GLAArrayEditorUserEditBlock)editBlock;

- (void)makeObserverOfOwnerForLoadNotificationWithName:(NSString *)loadNotificationName changeNotificationWithName:(NSString *)changeNotificationName;

@end
