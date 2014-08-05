//
//  GLACollectedFile.m
//  Blik
//
//  Created by Patrick Smith on 2/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFile.h"


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

@end


@implementation GLACollectedFile (URLBookmarkData)

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

@end
