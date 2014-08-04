//
//  GLACollectionFileContent.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectionFilesListContent.h"


@interface GLACollectionFilesListContent ()

@property(nonatomic) NSMutableArray *files;

@end

@implementation GLACollectionFilesListContent

- (NSArray *)copyFiles
{
	return (self.files.copy);
}

@end
