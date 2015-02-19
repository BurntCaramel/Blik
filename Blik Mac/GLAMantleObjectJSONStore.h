//
//  GLAMantleObjectJSONStore.h
//  Blik
//
//  Created by Patrick Smith on 17/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAStoring.h"
#import "Mantle/Mantle.h"


@interface GLAMantleObjectJSONStore : NSObject

- (instancetype)initWithFileURL:(NSURL *)fileURL modelClass:(Class)modelClass freshlyMade:(BOOL)freshlyMade operationQueue:(NSOperationQueue *)operationQueue loadCompletionHandler:(dispatch_block_t)loadCompletionHandler NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFileURL:(NSURL *)fileURL modelClass:(Class)modelClass modelObject:(MTLModel<MTLJSONSerializing> *)modelObject operationQueue:(NSOperationQueue *)operationQueue loadCompletionHandler:(dispatch_block_t)loadCompletionHandler;

@property(readonly, copy, nonatomic) NSURL *fileURL;
@property(readonly, nonatomic) Class modelClass;
@property(readonly, nonatomic) BOOL freshlyMade;

@property(readonly, nonatomic) GLAStoringLoadState loadState;
@property(readonly, nonatomic) GLAStoringSaveState saveState;

// Is present once loading has completed.
// Set to a new object to save it.
@property(nonatomic) MTLModel<MTLJSONSerializing> *object;
@property(readonly, nonatomic) NSError *errorLoading;
@property(readonly, nonatomic) NSError *errorSaving;

@end
