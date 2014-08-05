//
//  GLACollectionFileContent.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectionFilesListContent.h"
#import "GLACollectedFile.h"
#import "GLAArrayEditor.h"


@interface GLACollectionFilesListContent ()

@property(readonly, nonatomic) GLAArrayEditor *filesListEditor;

@end

@implementation GLACollectionFilesListContent

- (instancetype)init
{
	self = [super init];
	if (self) {
		_filesListEditor = [[GLAArrayEditor alloc] initWithObjects:
							@[
							  [GLACollectedFile collectedFileWithFileURL:[NSURL fileURLWithPath:NSHomeDirectory()]]
							  ]];
	}
	return self;
}

- (NSArray *)copyFiles
{
	return [(self.filesListEditor) copyChildren];
}

- (id<GLAArrayEditing>)filesListEditing
{
	return (self.filesListEditor);
}

@end
