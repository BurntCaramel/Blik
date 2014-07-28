//
//  GLAProjectItem.h
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "Mantle/Mantle.h"


typedef NS_ENUM(NSInteger, GLACollectionColor) {
	GLACollectionColorUnknown,
	GLACollectionColorLightBlue,
	GLACollectionColorGreen,
	GLACollectionColorPinkyPurple,
	GLACollectionColorRed,
	GLACollectionColorYellow
};


@interface GLACollection : MTLModel <MTLJSONSerializing>

@property(readonly, nonatomic) NSUUID *UUID;
@property(copy, nonatomic) NSString *title;

@property(nonatomic) GLACollectionColor colorIdentifier;


+ (instancetype)dummyCollectionWithTitle:(NSString *)title colorIdentifier:(GLACollectionColor)colorIdentifier;

+ (NSValueTransformer *)colorIdentifierValueTransformer;

@end


@protocol GLACollectionListEditing <NSObject>

//- (NSArray *)childCollectionsAtIndexes:(NSIndexSet *)indexes;

- (void)addChildCollections:(NSArray *)collections;
- (void)insertChildCollections:(NSArray *)collections atIndexes:(NSIndexSet *)indexes;
//- (void)removeChildCollections:(NSArray *)collections;
- (void)removeChildCollectionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceChildCollectionsAtIndexes:(NSIndexSet *)indexes withChildCollections:(NSArray *)collections;
- (void)moveChildCollectionsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex;

- (void)addObserverForAnyChanges:(void(^)())block;

/*
- (void)addObserverForInsertedCollections:(void(^)(NSIndexSet *indexesInserted))block;
- (void)addObserverForRemovedCollections:(void(^)(NSIndexSet *indexesRemoved, NSArray *collectionsRemoved))block;
- (void)addObserverForChangedIndexes:(void(^)(NSIndexSet *indexesChanged))block;
*/
@end