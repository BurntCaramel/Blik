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

- (NSArray *)allColors
{
	return [GLACollectionColor allAvailableColors];
}

- (void)loadView
{
	[super loadView];
	
	NSCollectionView *colorGridCollectionView = (self.colorGridCollectionView);
	(colorGridCollectionView.content) = [self allColors];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	(colorGridCollectionView.backgroundColors) = @[uiStyle.chooseColorBackgroundColor];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionViewSelectedColorChoiceDidChangeNotification:) name:GLACollectionViewSelectedColorChoiceDidChangeNotification object:colorGridCollectionView];
}

- (void)changeChosenViewItem:(GLACollectionViewColorChoiceItem *)item changeUI:(BOOL)changeUI
{
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
	
	if (changeUI) {
		(item.colorChoiceView.on) = YES;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionColorPickerViewControllerChosenColorDidChangeNotification object:self];
}

- (void)collectionViewSelectedColorChoiceDidChangeNotification:(NSNotification *)note
{
	GLACollectionViewColorChoiceItem *item = (note.userInfo)[@"item"];
	
	[self changeChosenViewItem:item changeUI:NO];
}

- (void)selectCollectionColorInUI:(GLACollectionColor *)color
{
	(void)(self.view);
	
	NSArray *allColors = (self.allColors);
	NSUInteger colorIndex = [allColors indexOfObject:color];
	GLACollectionViewColorChoiceItem *item = (GLACollectionViewColorChoiceItem *)[(self.colorGridCollectionView) itemAtIndex:colorIndex];
	[self changeChosenViewItem:item changeUI:YES];
}

@end

NSString *GLACollectionColorPickerViewControllerChosenColorDidChangeNotification = @"GLACollectionColorPickerViewControllerChosenColorDidChangeNotification";
