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

- (instancetype)initLoadingFromFileURL:(NSURL *)fileURL modelClass:(Class)modelClass operationQueue:(NSOperationQueue *)operationQueue loadCompletionHandler:(dispatch_block_t)loadCompletionHandler;

@property(readonly, copy, nonatomic) NSURL *fileURL;
@property(readonly, nonatomic) Class modelClass;
@property(readonly, nonatomic) NSOperationQueue *operationQueue;

@property(readonly, nonatomic) GLAStoringLoadState loadState;
@property(readonly, nonatomic) GLAStoringSaveState saveState;

@property(nonatomic) MTLModel<MTLJSONSerializing> *object;

@end
