//
//  GLAModelErrors.h
//  Blik
//
//  Created by Patrick Smith on 9/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;


typedef NS_ENUM(NSInteger, GLAModelErrorCode)
{
	GLAModelErrorCodeGeneral = 1,
	GLAModelErrorCodeJSONMissingRequiredKey = 2,
	GLAModelErrorCodeCannotAccessSecurityScopedURL = 3
};


@interface GLAModelErrors : NSObject

+ (NSString *)errorDomain;

#pragma mark -

+ (NSError *)errorForMissingRequiredKey:(NSString *)dictionaryKey inJSONFileAtURL:(NSURL *)fileURL;

+ (NSError *)errorForCannotAccessSecurityScopedURL:(NSURL *)fileURL;

@end
