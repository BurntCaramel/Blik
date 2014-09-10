//
//  GLAModelErrors.m
//  Blik
//
//  Created by Patrick Smith on 9/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAModelErrors.h"


NSString *GLAModelErrorDomain()
{
	NSString *bundleIdentifier = ([NSBundle mainBundle].bundleIdentifier);
	
	return [NSString stringWithFormat:@"%@.errorDomain.model", bundleIdentifier];
}


@implementation GLAModelErrors

+ (NSError *)errorForMissingRequiredKey:(NSString *)dictionaryKey inJSONFileAtURL:(NSURL *)fileURL
{
	NSString *descriptionPlaceholder = NSLocalizedString(@"JSON file (%@) does not contain required key (%@)", @"");
	NSString *descriptionFilledOut = [NSString localizedStringWithFormat:descriptionPlaceholder, (fileURL.path), dictionaryKey];
	
	NSDictionary *errorInfo =
	@{
	  NSLocalizedDescriptionKey: descriptionFilledOut
	  };
	
	return [NSError errorWithDomain:GLAModelErrorDomain() code:GLAModelErrorCodeJSONMissingRequiredKey userInfo:errorInfo];
}

@end
