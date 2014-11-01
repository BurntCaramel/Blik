//
//  GLACollectedFile.m
//  Blik
//
//  Created by Patrick Smith on 2/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLACollectedFile.h"


@interface GLACollectedFile ()
{
	NSData *_bookmarkData;
}

@property(readwrite, nonatomic) NSURL *URL;

@property(readwrite, nonatomic) NSString *filePath;

@property(readwrite, nonatomic) BOOL isDirectory;
@property(readwrite, nonatomic) BOOL isExecutable;
@property(readwrite, copy, nonatomic) NSString *name;

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

+ (NSString *)objectJSONPasteboardType
{
	return @"com.burntcaramel.GLACollectedFile.JSONPasteboardType";
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	NSNull *null = [NSNull null];
	
	return
  @{
	@"URL": null,
	@"name": null,
	@"isDirectory": null,
	@"isExecutable": null
	};
}

+ (NSValueTransformer *)bookmarkDataJSONTransformer
{
	return [NSValueTransformer GLA_DataBase64ValueTransformer];
}

#pragma mark Bookmark Data

+ (NSArray *)coreResourceValueKeys
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

- (void)updateInformationFromURLResourceValues:(NSDictionary *)resourceValues
{
	(self.isDirectory) = [[NSNumber numberWithBool:YES] isEqual:resourceValues[NSURLIsDirectoryKey]];
	(self.isExecutable) = [[NSNumber numberWithBool:YES] isEqual:resourceValues[NSURLIsExecutableKey]];
	(self.name) = resourceValues[NSURLLocalizedNameKey];
}

- (void)updateInformationWithError:(NSError *__autoreleasing *)error
{
	NSURL *URL = (self.URL);
	NSArray *resourceValueKeys = [[self class] coreResourceValueKeys];
	NSDictionary *resourceValues = [URL resourceValuesForKeys:resourceValueKeys error:error];
	[self updateInformationFromURLResourceValues:resourceValues];
}

- (NSData *)bookmarkDataWithError:(NSError *__autoreleasing *)error
{
	NSURL *URL = (self.URL);
	NSArray *resourceValueKeys = [[self class] coreResourceValueKeys];
	return [URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:resourceValueKeys relativeToURL:nil error:error];
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
	
	NSArray *resourceValueKeys = [[self class] coreResourceValueKeys];
	NSDictionary *resourceValues = [NSURL resourceValuesForKeys:resourceValueKeys fromBookmarkData:bookmarkData];
	[self updateInformationFromURLResourceValues:resourceValues];
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
		NSArray *resourceValues = [[self class] coreResourceValueKeys];
		bookmarkData = [URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:resourceValues relativeToURL:nil error:outError];
		if (!bookmarkData) {
			return NO;
		}
		
		*ioBookmarkData = bookmarkData;
	}
	
	return YES;
}

@end
