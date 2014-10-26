//
//  GLAModel.h
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "Mantle/Mantle.h"


@interface GLAModel : MTLModel <MTLJSONSerializing>

@end


@interface GLAModel (PasteboardSupport) <NSPasteboardReading, NSPasteboardWriting>

//extern NSString *GLACollectionJSONPasteboardType;

+ (NSString *)objectJSONPasteboardType;

+ (BOOL)canCopyObjectsFromPasteboard:(NSPasteboard *)pboard;
+ (NSArray *)copyObjectsFromPasteboard:(NSPasteboard *)pboard;

@end
