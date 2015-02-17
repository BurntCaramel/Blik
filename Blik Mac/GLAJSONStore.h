//
//  GLAJSONStore.h
//  Blik
//
//  Created by Patrick Smith on 17/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAStoring.h"


typedef void(^ GLAJSONStoreLoadCompletionBlock)(NSDictionary *JSON, NSError *error);
typedef void(^ GLAJSONStoreSaveCompletionBlock)(BOOL success, NSError *error);


@interface GLAJSONStore : NSObject

@property(copy, nonatomic) NSURL *fileURL;
@property(copy, nonatomic) NSOperationQueue *backgroundOperationQueue;
@property(copy, nonatomic) GLAJSONStoreLoadCompletionBlock loadCompletionBlock;
@property(copy, nonatomic) GLAJSONStoreSaveCompletionBlock saveCompletionBlock;

@property(readonly, nonatomic) GLAStoringLoadState loadState;
- (BOOL)loadIfNeeded;

@property(readonly, nonatomic) GLAStoringSaveState saveState;
- (void)saveJSONDictionary:(NSDictionary *)dictionary;

@property(nonatomic) id representedObject;

@end