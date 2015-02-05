//
//  GLACollectedFile.m
//  Blik
//
//  Created by Patrick Smith on 2/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLACollectedFile.h"
#import "GLAModelErrors.h"


@interface GLACollectedFile ()

@property(readwrite, nonatomic) NSURL *fileReferenceURL;
@property(nonatomic) NSURL *sourceFilePathURL;

@property(readwrite, nonatomic) BOOL isMissing;
@property(readwrite, nonatomic) BOOL isDirectory;
@property(readwrite, nonatomic) BOOL isExecutable;
@property(readwrite, copy, nonatomic) NSString *name;

@property(readwrite, nonatomic) BOOL wasCreatedFromBookmarkData;
@property(nonatomic) NSData *sourceBookmarkData;
@property(readwrite, nonatomic) NSData *bookmarkData;

@end

#define GLA_USE_REFERENCE_URLS 1

@implementation GLACollectedFile

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
	NSParameterAssert(fileURL != nil);
	
	self = [super init];
	if (self) {
		_sourceFilePathURL = [fileURL filePathURL];
		_fileReferenceURL = [fileURL fileReferenceURL];
		
		//NSLog(@"COLLECTED FILE INIT %@ | FP %@ | FR %@", fileURL, _sourceFilePathURL, _fileReferenceURL);
	}
	return self;
}

+ (NSArray *)collectedFilesWithFileURLs:(NSArray *)fileURLs
{
	NSMutableArray *collectedFiles = [NSMutableArray array];
	NSError *error = nil;
	for (NSURL *fileURL in fileURLs) {
		GLACollectedFile *collectedFile = [[GLACollectedFile alloc] initWithFileURL:fileURL];
		[collectedFile updateInformationWithError:&error];
		[collectedFiles addObject:collectedFile];
	}
	
	return collectedFiles;
}

+ (NSArray *)filePathsURLsForCollectedFiles:(NSArray *)collectedFiles ignoreMissing:(BOOL)ignoreMissing
{
	NSMutableArray *URLs = [NSMutableArray new];
	for (GLACollectedFile *collectedFile in collectedFiles) {
		if (ignoreMissing && (collectedFile.isMissing)) {
			continue;
		}
		
		NSURL *filePathURL = (collectedFile.filePathURL);
		if (filePathURL) {
			[URLs addObject:filePathURL];
		}
	}
	
	return URLs;
}

+ (NSArray *)filteredCollectedFiles:(NSArray *)collectedFiles notAlreadyPresentInArrayInspector:(id<GLAArrayInspecting>)inspectableArray
{
	return [inspectableArray filterArray:collectedFiles whoseResultFromVisitorIsNotAlreadyPresent:^id(GLACollectedFile *child) {
		return (child.filePathURL.path);
	}];
}

#pragma mark -

- (NSURL *)filePathURL
{
#if GLA_USE_REFERENCE_URLS
	NSURL *fileReferenceURL = (self.fileReferenceURL);
	if (fileReferenceURL) {
		BOOL accessing = [fileReferenceURL startAccessingSecurityScopedResource];
		NSURL *resolvedFilePathURL = [fileReferenceURL filePathURL];
		NSAssert(resolvedFilePathURL != nil, @"resolvedFilePathURL must be something");
		if (accessing) {
			[fileReferenceURL stopAccessingSecurityScopedResource];
		}
		//return resolvedFilePathURL;
		
		//NSLog(@"\n %@ \n %@ \n %@", resolvedFilePathURL, (self.sourceFilePathURL), @([resolvedFilePathURL isEqual:(self.sourceFilePathURL)]));
		
		return (self.sourceFilePathURL);
	}
	else {
		return (self.sourceFilePathURL);
	}
#else
	return (self.sourceFilePathURL);
#endif
}

- (NSUInteger)hash
{
	return (self.filePathURL.hash);
}

- (BOOL)isEqual:(id)object
{
	if (self == object) return YES;
	if (![object isKindOfClass:(self.class)]) return NO;
	
	GLACollectedFile *other = object;
	return [(self.filePathURL) isEqual:(other.filePathURL)];
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
	@"fileReferenceURL": null,
	@"sourceFilePathURL": null,
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

#pragma mark Pasteboard Writing

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return @[[[self class] objectJSONPasteboardType], (id)kUTTypeFileURL];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
	if ([type isEqualToString:(id)kUTTypeFileURL]) {
		NSURL *filePathURL = (self.filePathURL);
		return [filePathURL pasteboardPropertyListForType:type];
	}
	else {
		return [super pasteboardPropertyListForType:type];
	}
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

- (void)updateInformationFromURLResourceValues:(NSDictionary *)resourceValues
{
	(self.isDirectory) = [@YES isEqual:resourceValues[NSURLIsDirectoryKey]];
	(self.isExecutable) = [@YES isEqual:resourceValues[NSURLIsExecutableKey]];
	(self.name) = resourceValues[NSURLLocalizedNameKey];
}

- (BOOL)updateInformationApartFromKeys:(NSArray *)keysToExclude error:(NSError *__autoreleasing *)outError
{
	NSURL *URL = (self.filePathURL);
	BOOL wasCreatedFromBookmarkData = (self.wasCreatedFromBookmarkData);
	NSArray *resourceValueKeys = [[self class] coreResourceValueKeys];
	
	if (keysToExclude) {
		NSMutableArray *resourceValueKeysMutable = [resourceValueKeys mutableCopy];
		[resourceValueKeysMutable removeObjectsInArray:keysToExclude];
		if ((resourceValueKeysMutable.count) == 0) {
			return YES;
		}
		
		resourceValueKeys = resourceValueKeysMutable;
	}
	
	if (wasCreatedFromBookmarkData) {
		BOOL canAccess = [URL startAccessingSecurityScopedResource];
		if (!canAccess) {
			*outError = [GLAModelErrors errorForCannotAccessSecurityScopedURL:URL];
			return NO;
		}
	}
	
	NSDictionary *resourceValues = [URL resourceValuesForKeys:resourceValueKeys error:outError];
	if (resourceValues) {
		[self updateInformationFromURLResourceValues:resourceValues];
		
		NSError *error = nil;
		BOOL isReachable = [URL checkResourceIsReachableAndReturnError:&error];
		(self.isMissing) = !isReachable;
	}

	if (wasCreatedFromBookmarkData) {
		[URL stopAccessingSecurityScopedResource];
	}
	
	return (resourceValues != nil);
}

- (BOOL)updateInformationWithError:(NSError *__autoreleasing *)outError
{
	return [self updateInformationApartFromKeys:nil error:outError];
}

- (NSData *)bookmarkDataWithError:(NSError *__autoreleasing *)outError
{
	NSURL *URL = (self.filePathURL);
#if DEBUG
	NSLog(@"BOOKMARK DATA FOR FILE PATH URL %@", URL);
#endif
	BOOL wasCreatedFromBookmarkData = (self.wasCreatedFromBookmarkData);
	//wasCreatedFromBookmarkData = YES;
	
	BOOL canAccess = [URL startAccessingSecurityScopedResource];
	if (!canAccess) {
		*outError = [GLAModelErrors errorForCannotAccessSecurityScopedURL:URL];
		//return nil;
	}
	
	NSArray *resourceValueKeys = [[self class] coreResourceValueKeys];
	NSData *bookmarkData = [URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:resourceValueKeys relativeToURL:nil error:outError];
	
	if (canAccess) {
		[URL stopAccessingSecurityScopedResource];
	}
	
	return bookmarkData;
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
		(self.wasCreatedFromBookmarkData) = NO;
		//(self.sourceBookmarkData) = nil;
		return;
	}
	
	//(self.sourceBookmarkData) = bookmarkData;
	(self.wasCreatedFromBookmarkData) = YES;
	
	if (self.isMissing) {
		return;
	}
	
	NSArray *resourceValueKeys = [[self class] coreResourceValueKeys];
	NSDictionary *resourceValues = [NSURL resourceValuesForKeys:resourceValueKeys fromBookmarkData:bookmarkData];
	[self updateInformationFromURLResourceValues:resourceValues];
	
	[self updateInformationApartFromKeys:[resourceValues allKeys] error:&error];
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
#if 0
		NSLog(@"LOADED URL %@", URL);
		NSLog(@"FILE PATH URL %@", [URL filePathURL]);
		NSLog(@"FILE REF URL %@", [URL fileReferenceURL]);
		NSLog(@"FILE REF PATH URL %@", [[URL fileReferenceURL] filePathURL]);
#endif
		(self.sourceFilePathURL) = [URL filePathURL];
		(self.fileReferenceURL) = [URL fileReferenceURL];
		
		//BOOL isReachable = [URL checkResourceIsReachableAndReturnError:&error];
	}
	
	// Is stale: needs updating to new bookmark data.
	if (isStale) {
#if DEBUG
		NSLog(@"IS STALE %@", URL);
#endif
		BOOL canAccess = [URL startAccessingSecurityScopedResource];
		NSArray *resourceValues = [[self class] coreResourceValueKeys];
		bookmarkData = [URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:resourceValues relativeToURL:nil error:&error];
		if (!bookmarkData) {
#if DEBUG
			NSLog(@"CANNOT CREATE BOOKMARK DATA FOR STALE URL");
#endif
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
		if (canAccess) {
			[URL stopAccessingSecurityScopedResource];
		}
		
		*ioBookmarkData = bookmarkData;
	}
	
	return YES;
}
#endif

@end
