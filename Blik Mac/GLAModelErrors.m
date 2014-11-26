//
//  GLAModelErrors.m
//  Blik
//
//  Created by Patrick Smith on 9/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAModelErrors.h"


@implementation GLAModelErrors

+ (NSString *)errorDomain
{
	NSString *bundleIdentifier = ([NSBundle mainBundle].bundleIdentifier);
	
	return [NSString stringWithFormat:@"%@.errorDomain.model", bundleIdentifier];
}

+ (NSError *)errorForMissingRequiredKey:(NSString *)dictionaryKey inJSONFileAtURL:(NSURL *)fileURL
{
	NSString *descriptionFilledOut = NSLocalizedString(@"Saved file is missing essential information.", @"Error description for JSON file not containing required key");
	
	NSString *failureReasonPlaceholder = NSLocalizedString(@"JSON file (%@) does not contain required key (%@).", @"Error failure reason for JSON file not containing required key");
	NSString *failureReasonFilledOut = [NSString localizedStringWithFormat:failureReasonPlaceholder, (fileURL.path), dictionaryKey];
	
	NSDictionary *errorInfo =
	@{
	  NSLocalizedDescriptionKey: descriptionFilledOut,
	  NSLocalizedFailureReasonErrorKey: failureReasonFilledOut
	  };
	
	return [NSError errorWithDomain:[self errorDomain] code:GLAModelErrorCodeJSONMissingRequiredKey userInfo:errorInfo];
}

+ (NSError *)errorForCannotAccessSecurityScopedURL:(NSURL *)fileURL
{
	NSString *descriptionPlaceholder = NSLocalizedString(@"Could not access file URL with path %@.", @"Error description for when security scoped file URL cannot be accessed");
	NSString *description = [NSString localizedStringWithFormat:descriptionPlaceholder, (fileURL.path)];
	
	NSDictionary *errorInfo =
	@{
	  NSLocalizedDescriptionKey: description
	  };
	
	return [NSError errorWithDomain:[self errorDomain] code:GLAModelErrorCodeCannotAccessSecurityScopedURL userInfo:errorInfo];
}

@end
