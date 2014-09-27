//
//  GLACollectionColorPickerViewController.m
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectionColorPickerViewController.h"
#import "GLAUIStyle.h"


@interface GLACollectionColorPickerViewController ()

@end

@implementation GLACollectionColorPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)loadView
{
	[super loadView];
	
	NSCollectionView *colorGridCollectionView = (self.colorGridCollectionView);
	(colorGridCollectionView.content) = [GLACollectionColor allAvailableColors];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	(colorGridCollectionView.backgroundColors) = @[uiStyle.chooseColorBackgroundColor];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionViewSelectedColorChoiceDidChangeNotification:) name:GLACollectionViewSelectedColorChoiceDidChangeNotification object:colorGridCollectionView];
}

- (void)collectionViewSelectedColorChoiceDidChangeNotification:(NSNotification *)note
{NSLog(@"%@", (self.colorGridCollectionView.subviews));
	GLACollectionViewColorChoiceItem *item = (note.userInfo)[@"item"];
	
	GLACollectionViewColorChoiceItem *previouslyChosenItem = (self.chosenViewItem);
	if (previouslyChosenItem == item) {
		// Prevent responding to the .on = NO below.
		return;
	}
	if (previouslyChosenItem) {
		(previouslyChosenItem.colorChoiceView.on) = NO;
	}
	
	(self.chosenViewItem) = item;
	(self.chosenCollectionColor) = (item.representedCollectionColor);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionColorPickerViewControllerChosenColorDidChangeNotification object:self];
}

@end

NSString *GLACollectionColorPickerViewControllerChosenColorDidChangeNotification = @"GLACollectionColorPickerViewControllerChosenColorDidChangeNotification";
