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

- (instancetype)initWithFileURL:(NSURL *)fileURL backgroundOperationQueue:(NSOperationQueue *)operationQueue freshlyMade:(BOOL)freshlyMade NS_DESIGNATED_INITIALIZER;

@property(readonly, copy, nonatomic) NSURL *fileURL;
@property(readonly, nonatomic) NSOperationQueue *backgroundOperationQueue;
@property(readonly, nonatomic) BOOL freshlyMade;

@property(copy, nonatomic) GLAJSONStoreLoadCompletionBlock loadCompletionBlock;
@property(copy, nonatomic) GLAJSONStoreSaveCompletionBlock saveCompletionBlock;

@property(readonly, nonatomic) GLAStoringLoadState loadState;
- (BOOL)loadIfNeeded;

@property(readonly, nonatomic) GLAStoringSaveState saveState;
- (void)saveJSONDictionary:(NSDictionary *)dictionary;

@property(nonatomic) id representedObject;

@end