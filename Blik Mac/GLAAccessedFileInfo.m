//
//  GLAFileInfo.m
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAAccessedFileInfo.h"


@interface GLAAccessedFileInfo ()

@property(nonatomic) BOOL accessSecurityScopeWasSuccessful;

@end

@implementation GLAAccessedFileInfo

#if 0
+ (NSArray *)coreResourceValueKeys
{
	return
	@[
	  NSURLIsDirectoryKey,
	  NSURLIsExecutableKey,
	  NSURLTypeIdentifierKey,
	  NSURLNameKey,
	  NSURLLocalizedNameKey
	  ];
}
#else
+ (NSArray *)coreResourceValueKeys
{
	return
	@[
	  ];
}
#endif

+ (NSData *)createBookmarkDataForFileURL:(NSURL *)fileURL error:(NSError *__autoreleasing*)errorOut
{
	NSError *error = nil;
	
	BOOL canAccess = [fileURL startAccessingSecurityScopedResource];
	NSArray *resourceValues = [[self class] coreResourceValueKeys];
	NSData *bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:resourceValues relativeToURL:nil error:&error];
	if (!bookmarkData) {
#if DEBUG
		NSLog(@"CANNOT CREATE BOOKMARK DATA FOR STALE URL");
#endif
		switch (error.code) {
			case NSFileNoSuchFileError:
			case NSFileReadUnknownError:
			case NSFileReadNoSuchFileError:
				
			default:
				*errorOut = error;
				return nil;
		}
	}
	if (canAccess) {
		[fileURL stopAccessingSecurityScopedResource];
	}
	
	return bookmarkData;
}

+ (NSURL *)resolveFileURLFromBookmarkData:(NSData *)bookmarkData error:(NSError *__autoreleasing*)errorOut recreatedBookmarkDataIfStale:(NSData *__autoreleasing*)recreatedBookmarkDataIfStale
{
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
				
			default:
				*errorOut = error;
				return nil;
		}
	}
	
	// Is stale: needs updating to new bookmark data.
	if (isStale) {
#if DEBUG
		NSLog(@"IS STALE %@", URL);
#endif
		NSData *recreatedBookmarkData = [self createBookmarkDataForFileURL:URL error:&error];
		if (!recreatedBookmarkData) {
			*errorOut = error;
		}
		
		*recreatedBookmarkDataIfStale = recreatedBookmarkData;
	}
	else {
		*recreatedBookmarkDataIfStale = nil;
	}
	
	return URL;
}

- (instancetype)initWithBookmarkData:(NSData *)bookmarkData
{
	self = [super init];
	if (self) {
		NSError *error = nil;
		NSData *recreatedBookmarkData = nil;
		NSURL *fileURL = [[self class] resolveFileURLFromBookmarkData:bookmarkData error:&error recreatedBookmarkDataIfStale:&recreatedBookmarkData];
		
		if (!fileURL) {
			_errorResolving = error;
		}
		
		if (recreatedBookmarkData) {
			_sourceBookmarkData = [recreatedBookmarkData copy];
		}
		else {
			_sourceBookmarkData = [bookmarkData copy];
		}
		
		_filePathURL = fileURL;
		
		[self startAccessingSecurityScope];
	}
	return self;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
	NSError *error = nil;
	NSData *bookmarkData = [[self class] createBookmarkDataForFileURL:fileURL error:&error];
	if (!bookmarkData) {
		_errorResolving = error;
	}
	
	return [self initWithBookmarkData:bookmarkData];
}

- (void)dealloc
{
	[self stopAccessingSecurityScopeIfNeeded];
}

- (void)startAccessingSecurityScope
{
	NSURL *filePathURL = (self.filePathURL);
	(self.accessSecurityScopeWasSuccessful) = [filePathURL startAccessingSecurityScopedResource];
}

- (void)stopAccessingSecurityScopeIfNeeded
{
	NSURL *filePathURL = (self.filePathURL);
	if (self.accessSecurityScopeWasSuccessful) {
		[filePathURL stopAccessingSecurityScopedResource];
	}
	
	(self.accessSecurityScopeWasSuccessful) = NO;
}

- (void)resolveFilePathURLAgain
{
	NSError *error = nil;
	NSData *recreatedBookmarkData = nil;
	NSURL *filePathURL = [[self class] resolveFileURLFromBookmarkData:(self.sourceBookmarkData) error:&error recreatedBookmarkDataIfStale:&recreatedBookmarkData];
	
	if (!filePathURL) {
		_errorResolving = error;
	}
	
	_filePathURL = filePathURL;
	
	if (recreatedBookmarkData) {
		_sourceBookmarkData = [recreatedBookmarkData copy];
	}
}

@end
