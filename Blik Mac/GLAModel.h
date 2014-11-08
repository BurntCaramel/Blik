//
//  GLAModel.h
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
#import "Mantle/Mantle.h"
#import "NSValueTransformer+GLAModel.h"


@interface GLAModel : MTLModel <MTLJSONSerializing>

@property(readonly, nonatomic) NSUUID *UUID;

- (instancetype)duplicate;

@end


@interface GLAModel (PasteboardSupport) <NSPasteboardReading, NSPasteboardWriting>

+ (NSString *)objectJSONPasteboardType;

+ (BOOL)canCopyObjectsFromPasteboard:(NSPasteboard *)pboard;
+ (NSArray *)copyObjectsFromPasteboard:(NSPasteboard *)pboard;

@end
