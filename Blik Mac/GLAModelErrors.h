//
//  GLAModelErrors.h
//  Blik
//
//  Created by Patrick Smith on 9/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;


extern NSString *GLAModelErrorDomain();

typedef NS_ENUM(NSInteger, GLAModelErrorCode)
{
	GLAModelErrorCodeGeneral = 1,
	GLAModelErrorCodeJSONMissingRequiredKey = 2
};


@interface GLAModelErrors : NSObject

+ (NSError *)errorForMissingRequiredKey:(NSString *)dictionaryKey inJSONFileAtURL:(NSURL *)fileURL;

@end
