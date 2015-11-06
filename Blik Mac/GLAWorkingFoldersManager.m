//
//  GLAWorkingFoldersManager.m
//  Blik
//
//  Created by Patrick Smith on 7/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAWorkingFoldersManager.h"


@interface GLAWorkingFoldersManager ()

@property(nonatomic) dispatch_queue_t fileQueue;

@end

@implementation GLAWorkingFoldersManager

- (instancetype)init
{
	self = [super init];
	if (self) {
		_fileQueue = dispatch_queue_create("com.burntcaramel.blik.GLAWorkingFoldersManager", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

+ (instancetype)sharedWorkingFoldersManager
{
	static GLAWorkingFoldersManager *sharedWorkingFoldersManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedWorkingFoldersManager = [GLAWorkingFoldersManager new];
	});
	
	return sharedWorkingFoldersManager;
}

- (void)handleError:(NSError *)error fromSelector:(SEL)sourceSelector
{
	
}

- (NSURL *)version1DirectoryURLWithInnerDirectoryComponents:(NSArray *)extraPathComponents
{
	__block NSURL *directoryURL;
	
	//CFAbsoluteTime tStart = CFAbsoluteTimeGetCurrent();
	dispatch_sync((self.fileQueue), ^{
		NSFileManager *fm = [NSFileManager defaultManager];
		NSError *error = nil;
		
		directoryURL = [fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
		
		if (!directoryURL) {
			[self handleError:error fromSelector:_cmd];
			return;
		}
		
		// Convert path to its components, so we can add more components
		// and convert back into a URL.
		NSMutableArray *pathComponents = [(directoryURL.pathComponents) mutableCopy];
		
		// {appBundleID}/v1/
		NSString *appBundleID = ([NSBundle mainBundle].bundleIdentifier);
		[pathComponents addObject:appBundleID];
		[pathComponents addObject:@"v1"];
		
		// Append extra path components passed to this method.
		if (extraPathComponents) {
			[pathComponents addObjectsFromArray:extraPathComponents];
		}
		
		// Convert components back into a URL.
		directoryURL = [NSURL fileURLWithPathComponents:pathComponents];
		
		BOOL directorySuccess = [fm createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
		if (!directorySuccess) {
			[self handleError:error fromSelector:_cmd];
			return;
		}
	});
	//CFAbsoluteTime tEnd = CFAbsoluteTimeGetCurrent();
	//NSLog(@"%@ took %@s", NSStringFromSelector(_cmd), @(tEnd - tStart));
	
	return directoryURL;
}

- (NSURL *)version1DirectoryURL
{
	return [self version1DirectoryURLWithInnerDirectoryComponents:nil];
}

//- (void)backup

@end
