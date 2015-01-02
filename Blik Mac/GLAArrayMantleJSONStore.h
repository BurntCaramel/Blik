//
//  GLAArrayMantleJSONStore.h
//  Blik
//
//  Created by Patrick Smith on 11/12/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "GLAArrayEditor.h"
#import "Mantle/Mantle.h"


@protocol GLAArrayMantleJSONStoreErrorHandler;

@interface GLAArrayMantleJSONStore : NSObject <GLAArrayStoring>

- (instancetype)initWithModelClass:(Class)modelClass JSONFileURL:(NSURL *)JSONFileURL JSONDictionaryKey:(NSString *)JSONKey freshlyMade:(BOOL)freshlyMade operationQueue:(NSOperationQueue *)operationQueue errorHandler:(id<GLAArrayMantleJSONStoreErrorHandler>)errorHandler NS_DESIGNATED_INITIALIZER;

@property(readonly, nonatomic) Class modelClass;
@property(copy, readonly, nonatomic) NSURL *JSONFileURL;
@property(copy, readonly, nonatomic) NSString *JSONDictionaryKeyForArray;
@property(readonly, nonatomic) NSOperationQueue *operationQueue;

@property(weak, readonly, nonatomic) id<GLAArrayMantleJSONStoreErrorHandler> errorHandler;

@end

@interface GLAArrayMantleJSONStore (Errors)

+ (NSString *)errorDomain;

typedef NS_ENUM(NSInteger, GLAArrayMantleJSONEditorStoreErrorCode)
{
	GLAArrayMantleJSONEditorStoreErrorCodeGeneric = 1,
	GLAArrayMantleJSONEditorStoreErrorCodeJSONMissingRequiredKey,
	GLAArrayMantleJSONEditorStoreErrorCodeCannotMakeModelsFromJSONArray
};

+ (NSError *)errorForMissingRequiredKey:(NSString *)dictionaryKey inJSONFileAtURL:(NSURL *)fileURL;
+ (NSError *)errorForCannotMakeModelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray loadedFromFileAtURL:(NSURL *)fileURL mantleError:(NSError *)error;

@end

//extern NSString *GLAArrayMantleJSONStoreErrorNotification;

@protocol GLAArrayMantleJSONStoreErrorHandler <NSObject>

- (void)arrayMantleJSONStore:(GLAArrayMantleJSONStore *)store handleError:(NSError *)error;
							  
@end
