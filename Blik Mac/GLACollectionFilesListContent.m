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

@property(readonly, nonatomic) NSArray *filesListForJSON;

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

/*- (instancetype)copyWithZone:(NSZone *)zone
{
	
}*/

- (NSArray *)copyFiles
{
	return [(self.filesListEditor) copyChildren];
}

- (id<GLAArrayEditing>)filesListEditing
{
	return (self.filesListEditor);
}

#pragma mark - JSON

- (NSArray *)filesListForJSON
{
	return [self copyFiles];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"filesListForJSON": @"filesList",
	  @"filesListEditing": (NSNull.null),
	  @"filesListEditor": (NSNull.null)
	  };
}

+ (NSValueTransformer *)filesListForJSONJSONTransformer
{
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[GLACollectedFile class]];
}

@end
