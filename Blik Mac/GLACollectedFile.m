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
{
	NSData *_bookmarkData;
}

@property(readwrite, nonatomic) NSURL *URL;
@property(readwrite, nonatomic) NSString *filePath;
@property(readwrite, nonatomic) NSData *bookmarkData;

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

- (NSString *)filePath
{
	NSURL *URL = (self.URL);
	if (URL) {
		return (URL.path);
	}
	else {
		return nil;
	}
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

- (void)setBookmarkData:(NSData *)bookmarkData
{
	_bookmarkData = bookmarkData;
	
	BOOL isStale = NO;
	NSError *error = nil;
	NSURL *URL = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&isStale error:&error];
	(self.URL) = URL;
	
}

- (BOOL)validateBookmarkData:(inout __autoreleasing NSData **)ioBookmarkData error:(out NSError *__autoreleasing *)outError
{
	NSData *bookmarkData = *ioBookmarkData;
	BOOL isStale = NO;
	// Resolve the bookmark data.
	NSURL *URL = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&isStale error:outError];
	// No URL could be found: invalid.
	if (!URL) {
		return NO;
	}
	
	// Is stale: needs updating to new bookmark data.
	if (isStale) {
		NSArray *resourceValues = [[self class] resourceValuesForCreatingBookmarkData];
		bookmarkData = [URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:resourceValues relativeToURL:nil error:outError];
		if (!bookmarkData) {
			return NO;
		}
		
		*ioBookmarkData = bookmarkData;
	}
	
	return YES;
}

#pragma mark JSON

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"URL": (NSNull.null),
	  @"filePath": @"filePath",
	  @"bookmarkData": @"bookmarkData"
	  };
}

+ (NSValueTransformer *)bookmarkDataJSONTransformer
{
	return [NSValueTransformer GLA_DataBase64ValueTransformer];
}

@end
