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

@property(readwrite, nonatomic) BOOL isMissing;
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

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
	self = [super initWithDictionary:dictionaryValue error:error];
	if (self) {
		
	}
	return self;
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
	@"isMissing": null,
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

- (BOOL)updateInformationWithError:(NSError *__autoreleasing *)error
{
	NSURL *URL = (self.URL);
	NSArray *resourceValueKeys = [[self class] coreResourceValueKeys];
	NSDictionary *resourceValues = [URL resourceValuesForKeys:resourceValueKeys error:error];
	if (!resourceValues) {
		return NO;
	}
	[self updateInformationFromURLResourceValues:resourceValues];
	
	BOOL isReachable = [URL checkResourceIsReachableAndReturnError:error];
	(self.isMissing) = !isReachable;
	
	return NO;
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
	NSError *error = nil;
	BOOL isValid = [self validateBookmarkData:&bookmarkData updateProperties:YES error:&error];
	if (!isValid) {
		_bookmarkData = nil;
		return;
	}
	
	_bookmarkData = bookmarkData;
	
	NSArray *resourceValueKeys = [[self class] coreResourceValueKeys];
	NSDictionary *resourceValues = [NSURL resourceValuesForKeys:resourceValueKeys fromBookmarkData:bookmarkData];
	[self updateInformationFromURLResourceValues:resourceValues];
}

#if 1
- (BOOL)validateBookmarkData:(inout __autoreleasing NSData **)ioBookmarkData error:(out NSError *__autoreleasing *)outError
{
	return [self validateBookmarkData:ioBookmarkData updateProperties:NO error:outError];
}

- (BOOL)validateBookmarkData:(inout __autoreleasing NSData **)ioBookmarkData updateProperties:(BOOL)update error:(out NSError *__autoreleasing *)outError
{
	NSData *bookmarkData = *ioBookmarkData;
	if (!bookmarkData) {
		if (update) {
			(self.isMissing) = YES;
		}
		return YES;
	}
	
	BOOL isStale = NO;
	NSError *error = nil;
	// Resolve the bookmark data.
	NSURL *URL = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&isStale error:&error];
	// No URL could be found: invalid.
	if (!URL) {
		switch (error.code) {
			case NSFileNoSuchFileError:
			case NSFileReadUnknownError:
			case NSFileReadNoSuchFileError:
			//case NSFileReadCorruptFileError:
			if (update) {
				(self.isMissing) = YES;
			}
			return YES;
			
			default:
			*outError = error;
			return NO;
		}
	}
	
	if (update) {
		(self.URL) = URL;
		
		//BOOL isReachable = [URL checkResourceIsReachableAndReturnError:&error];
	}
	
	// Is stale: needs updating to new bookmark data.
	if (isStale) {
		NSArray *resourceValues = [[self class] coreResourceValueKeys];
		bookmarkData = [URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:resourceValues relativeToURL:nil error:&error];
		if (!bookmarkData) {
			switch (error.code) {
				case NSFileNoSuchFileError:
				case NSFileReadUnknownError:
				case NSFileReadNoSuchFileError:
				if (update) {
					(self.isMissing) = YES;
				}
				return YES;
				
				default:
				*outError = error;
				return NO;
			}
		}
		
		*ioBookmarkData = bookmarkData;
	}
	
	return YES;
}
#endif

@end
