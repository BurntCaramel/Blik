//
//  GLACollectedFile.m
//  Blik
//
//  Created by Patrick Smith on 2/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFile.h"
#import "NSValueTransformer+GLAModel.h"


@interface GLACollectedFile ()

@property(nonatomic) NSData *loadedBookmarkData;

@end

@implementation GLACollectedFile

- (instancetype)initWithFileURL:(NSURL *)URL
{
	self = [super init];
	if (self) {
		_URL = URL;
	}
	return self;
}

+ (instancetype)collectedFileWithFileURL:(NSURL *)URL
{
	return [[self alloc] initWithFileURL:URL];
}

#pragma mark -

- (NSUInteger)hash
{
	return (self.URL.hash);
}

- (BOOL)isEqual:(id)object
{
	if (self == object) return YES;
	if (![object isKindOfClass:self.class]) return NO;
	
	GLACollectedFile *other = object;
	return [(self.URL) isEqual:(other.URL)];
}

#pragma mark Bookmark Data

+ (NSArray *)resourceValuesForCreatingBookmarkData
{
	return
	@[
	  NSURLIsDirectoryKey,
	  NSURLIsExecutableKey,
	  NSURLLocalizedNameKey
	  ];
}

- (NSData *)bookmarkDataWithError:(NSError *__autoreleasing *)error
{
	NSURL *URL = (self.URL);
	NSArray *resourceValues = [[self class] resourceValuesForCreatingBookmarkData];
	return [URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:resourceValues relativeToURL:nil error:error];
}

- (NSData *)bookmarkData
{
	NSError *error = nil;
	return [self bookmarkDataWithError:&error];
}

#pragma mark JSON

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"URL": (NSNull.null),
	  @"bookmarkData": @"bookmarkData"
	  };
}

+ (NSValueTransformer *)bookmarkDataJSONTransformer
{
	return [NSValueTransformer GLA_DataBase64ValueTransformer];
}

@end
