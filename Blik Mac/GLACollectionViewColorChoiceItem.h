//
//  GLACollectionViewColorChoiceItem.h
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLACollectionColor.h"
#import "GLAColorChoiceView.h"


@interface GLACollectionViewColorChoiceItem : NSCollectionViewItem

@property(readonly, nonatomic) GLACollectionColor *representedCollectionColor;
@property(nonatomic) IBOutlet GLAColorChoiceView *colorChoiceView;

@end

extern NSString *GLACollectionViewSelectedColorChoiceDidChangeNotification;
