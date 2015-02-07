//
//  GLAApplicationSettingsManager.m
//  Blik
//
//  Created by Patrick Smith on 7/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAApplicationSettingsManager.h"


@implementation GLAApplicationSettingsManager

+ (instancetype)sharedApplicationSettingsManager
{
	static GLAApplicationSettingsManager *sharedApplicationSettingsManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedApplicationSettingsManager = [GLAApplicationSettingsManager new];
	});
	
	return sharedApplicationSettingsManager;
}

#pragma mark -

- (void)loadPermittedApplicationFolders
{
	
}

- (NSArray *)copyPermittedApplicationFolders
{
	return nil;
}

- (BOOL)editPermittedApplicationFoldersUsingBlock:(void (^)(id<GLAArrayEditing>))block
{
	return NO;
}

@end
