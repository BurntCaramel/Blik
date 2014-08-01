//
//  GLACollectionFileContent.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectionFilesListContent.h"


@interface GLACollectionFilesListContent ()

@property(nonatomic) NSMutableArray *URLs;
@property(nonatomic) NSMutableArray *bookmarkDataArray;

@end

@implementation GLACollectionFilesListContent

- (NSArray *)copyURLs
{
	return (self.URLs.copy);
}

- (NSArray *)copyBookmarkDataArray
{
	return (self.bookmarkDataArray.copy);
}

@end
