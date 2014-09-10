//
//  NSValueTransformer+GLAModel.m
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "NSValueTransformer+GLAModel.h"


NSString *const GLAUUIDValueTransformerName = @"GLAUUIDValueTransformerName";
NSString *const GLADataBase64ValueTransformerName = @"GLADataBase64ValueTransformerName";
NSString *const GLADateRFC3339ValueTransformerName = @"GLADateRFC3339ValueTransformerName";


@implementation NSValueTransformer (GLAModel)

+ (NSValueTransformer *)new_GLA_DateRFC3339ValueTransformer
{
	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    (dateFormatter.dateFormat) = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    (dateFormatter.timeZone) = [NSTimeZone timeZoneForSecondsFromGMT:0];
    (dateFormatter.locale) = enUSPOSIXLocale;
	
	MTLValueTransformer *dateRFC3339ValueTransformer = [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *RFC3339String) {
		return [dateFormatter dateFromString:RFC3339String];
	} reverseBlock:^id(NSDate *date) {
		return [dateFormatter stringFromDate:date];
	}];
	
	return dateRFC3339ValueTransformer;
}

+ (void)load
{
	@autoreleasepool {
		MTLValueTransformer *UUIDValueTransformer = [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *UUIDString) {
			return [[NSUUID alloc] initWithUUIDString:UUIDString];
		} reverseBlock:^id(NSUUID *UUID) {
			return [UUID UUIDString];
		}];
		[NSValueTransformer setValueTransformer:UUIDValueTransformer forName:GLAUUIDValueTransformerName];
		
		
		MTLValueTransformer *dataBase64ValueTransformer = [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *base64String) {
			return [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
		} reverseBlock:^id(NSData *data) {
			return [data base64EncodedStringWithOptions:0];
		}];
		[NSValueTransformer setValueTransformer:dataBase64ValueTransformer forName:GLADataBase64ValueTransformerName];
		
		
		NSValueTransformer *dateRFC3339ValueTransformer = [self new_GLA_DateRFC3339ValueTransformer];
		[NSValueTransformer setValueTransformer:dateRFC3339ValueTransformer forName:GLADateRFC3339ValueTransformerName];
	}
}

+ (instancetype)GLA_UUIDValueTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (instancetype)GLA_DataBase64ValueTransformer
{
	return [NSValueTransformer valueTransformerForName:GLADataBase64ValueTransformerName];
}

+ (instancetype)GLA_DateRFC3339ValueTransformer
{
	return [NSValueTransformer valueTransformerForName:GLADateRFC3339ValueTransformerName];
}

@end
