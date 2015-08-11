//
//  GLAArrangedDirectoryChildren.m
//  Blik
//
//  Created by Patrick Smith on 11/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAArrangedDirectoryChildren.h"
#import "GLAFileInfoRetriever.h"


@interface GLAArrangedDirectoryChildren ()

@property(readwrite, copy, nonatomic) NSString *resourceKeyToSortBy;
@property(readwrite, nonatomic) BOOL sortsAscending;
@property(readwrite, nonatomic) BOOL hidesInvisibles;

@property(readwrite, copy, nonatomic) NSArray *fileURLs;

@property(nonatomic) id<NSObject> didRetrieveContentsOfDirectoryNotificationToken;

@end

@interface GLAArrangedDirectoryChildren (GLAArrangedDirectoryChildrenOptionEditing) <GLAArrangedDirectoryChildrenOptionEditing>

@end

@implementation GLAArrangedDirectoryChildren

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL delegate:(id<GLAArrangedDirectoryChildrenDelegate>)delegate fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever
{
	self = [super init];
	if (self) {
		_directoryURL = [directoryURL copy];
		_delegate = delegate;
		_fileInfoRetriever = fileInfoRetriever;
		
		[self startObservingFileInfoRetriever];
		
		_resourceKeyToSortBy = NSURLLocalizedNameKey;
		_sortsAscending = YES;
	}
	return self;
}

- (void)dealloc
{
	[self stopObservingFileInfoRetriever];
}

#pragma mark -

- (void)startObservingFileInfoRetriever
{
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	
	(self.didRetrieveContentsOfDirectoryNotificationToken) = [fileInfoRetriever addObserver:self forDidRetrieveContentsOfDirectory:^(GLAArrangedDirectoryChildren *self, GLAFileInfoRetriever *fileInfoRetriever, NSURL *directoryURL) {
		if ([directoryURL isEqual:(self.directoryURL)]) {
			[self update];
		}
	}];
}

- (void)stopObservingFileInfoRetriever
{
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	
	[fileInfoRetriever removeObserverWithToken:(self.didRetrieveContentsOfDirectoryNotificationToken)];
}

#pragma mark -

- (void)updateAfterEditingOptions:(void (^)(id<GLAArrangedDirectoryChildrenOptionEditing>))editorBlock
{
	editorBlock(self);
	[self update];
}

- (void)update
{
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	NSString *resourceKeyToSortBy = (self.resourceKeyToSortBy);
	BOOL sortsAscending = (self.sortsAscending);
	BOOL hidesInvisibles = (self.hidesInvisibles);
	
	dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	__weak GLAArrangedDirectoryChildren *weakSelf = self;
	
	dispatch_async(dispatchQueue, ^{
		NSArray *originalChildURLs = [fileInfoRetriever childURLsOfDirectoryWithURL:(self.directoryURL) requestIfNeeded:YES];
		if (!originalChildURLs) {
			return;
		}
		
		NSMutableArray *arrangedChildURLs = [originalChildURLs mutableCopy];
		if (hidesInvisibles) {
			NSIndexSet *invisibleFilesIndexes = [arrangedChildURLs indexesOfObjectsPassingTest:^BOOL(NSURL *fileURL, NSUInteger idx, BOOL *stop) {
				NSNumber *isHiddenValue = [fileInfoRetriever resourceValueForKey:NSURLIsHiddenKey forURL:fileURL];
				if (isHiddenValue) {
					return [isHiddenValue isEqual:@YES];
				}
				else {
					return YES; // Be aggressive, don't show until we know.
				}
			}];
			[arrangedChildURLs removeObjectsAtIndexes:invisibleFilesIndexes];
		}
		
		SEL compareSelector = @selector(compare:);
		if ([resourceKeyToSortBy isEqualToString:NSURLLocalizedNameKey]) {
			compareSelector = @selector(localizedStandardCompare:);
		}
		
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:sortsAscending selector:compareSelector];
		[arrangedChildURLs sortUsingComparator:^NSComparisonResult(NSURL *fileURL1, NSURL *fileURL2) {
			id<NSObject> value1 = [fileInfoRetriever resourceValueForKey:resourceKeyToSortBy forURL:fileURL1];
			id<NSObject> value2 = [fileInfoRetriever resourceValueForKey:resourceKeyToSortBy forURL:fileURL2];
			
			// Nil values
			if (!value1) {
				if (!value2) {
					return NSOrderedSame;
				}
				else {
					return NSOrderedDescending;
				}
			}
			else if (!value2) {
				return NSOrderedAscending;
			}
			
			return [sortDescriptor compareObject:value1 toObject:value2];
		}];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			__strong GLAArrangedDirectoryChildren *self = weakSelf;
			if (!self) {
				return;
			}
			
			NSLog(@"arrangedChildURLs %@", arrangedChildURLs);
			(self.fileURLs) = arrangedChildURLs;
			
			[(self.delegate) arrangedDirectoryChildrenDidUpdateChildren:self];
		}];
	});
}

@end

NSString *GLAArrangedDirectoryChildrenDidUpdateChildrenNotification = @"GLAArrangedDirectoryChildrenDidUpdateChildrenNotification";
