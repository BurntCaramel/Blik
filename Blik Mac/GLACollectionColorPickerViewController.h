//
//  GLACollectionColorPickerViewController.h
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLACollectionColor.h"
#import "GLACollectionViewColorChoiceItem.h"


@interface GLACollectionColorPickerViewController : GLAViewController <NSCollectionViewDelegate>

@property(nonatomic) IBOutlet NSCollectionView *colorGridCollectionView;

@property(nonatomic) GLACollectionColor *chosenCollectionColor;
@property(nonatomic) GLACollectionViewColorChoiceItem *chosenViewItem;

- (void)selectCollectionColorInUI:(GLACollectionColor *)color;

@end

extern NSString *GLACollectionColorPickerViewControllerChosenColorDidChangeNotification;