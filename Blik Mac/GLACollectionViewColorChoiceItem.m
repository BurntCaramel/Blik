//
//  GLACollectionViewColorChoiceItem.m
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectionViewColorChoiceItem.h"
#import "GLAUIStyle.h"
#import "GLAViewController.h"


@interface GLACollectionViewColorChoiceItem ()

@end

@implementation GLACollectionViewColorChoiceItem

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)prepareView
{
	(self.colorChoiceView.togglesOnAndOff) = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorChoiceViewOnDidChangeNotification:) name:GLAColorChoiceViewOnDidChangeNotification object:(self.colorChoiceView)];
}

- (void)loadView
{
	[super loadView];
	
	[self prepareView];
}

- (void)colorChoiceViewOnDidChangeNotification:(NSNotification *)note
{
	GLAColorChoiceView *colorChoiceView = (note.object);
	BOOL on = (colorChoiceView.on);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionViewSelectedColorChoiceDidChangeNotification object:(self.collectionView) userInfo:
	 @{
	   @"item": self,
	   @"on": @(on)
	   }];
}

- (void)setRepresentedObject:(id)representedObject
{
	NSAssert((representedObject == nil) || [representedObject isKindOfClass:[GLACollectionColor class]], @"%@ representedObject must be a GLACollectionColor", self);
	
	GLACollectionColor *representedCollectionColor = representedObject;
	[super setRepresentedObject:representedCollectionColor];
	
	if (representedCollectionColor) {
		GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
		GLAColorChoiceView *colorChoiceView = (self.colorChoiceView);
		NSColor *displayColor = [uiStyle colorForCollectionColor:representedCollectionColor];
		(colorChoiceView.color) = displayColor;
	}
}

- (GLACollectionColor *)representedCollectionColor
{
	return (self.representedObject);
}

- (id)copyWithZone:(NSZone *)zone
{
	GLACollectionViewColorChoiceItem *copy = [super copyWithZone:zone];
	
	GLAColorChoiceView *colorChoiceView = (id)[GLAViewController viewWithIdentifier:@"colorChoice" inViews:(copy.view.subviews)];
	(copy.colorChoiceView) = colorChoiceView;
	
	[copy prepareView];
	
	return copy;
}

@end

NSString *GLACollectionViewSelectedColorChoiceDidChangeNotification = @"GLACollectionViewSelectedColorChoiceDidChangeNotification";
