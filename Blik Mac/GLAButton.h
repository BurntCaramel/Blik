//
//  GLAButton.h
//  
//
//  Created by Patrick Smith on 14/07/2014.
//
//

@import Cocoa;
@class GLAButtonCell;


@interface GLAButton : NSButton

@property(nonatomic) GLAButtonCell *cell;

@property(nonatomic) CGFloat leftSpacing;
@property(nonatomic) CGFloat rightSpacing;
@property(nonatomic) CGFloat verticalOffsetDown;

@property(nonatomic, getter = isAlwaysHighlighted) BOOL alwaysHighlighted;

@property(nonatomic) NSColor *textHighlightColor;
@property(nonatomic) NSColor *backgroundColor;
@property(nonatomic) CGFloat highlightAmount;

@property(readonly, nonatomic, getter = isOnAndShowsOnState) BOOL onAndShowsOnState;

@property(nonatomic) BOOL hasPrimaryStyle;
@property(nonatomic) BOOL hasSecondaryStyle;

@end


@interface GLAButtonCell : NSButtonCell

@property(nonatomic) CGFloat leftSpacing;
@property(nonatomic) CGFloat rightSpacing;
@property(nonatomic) CGFloat verticalOffsetDown;

@property(nonatomic, getter = isAlwaysHighlighted) BOOL alwaysHighlighted;

@property(nonatomic) NSColor *textHighlightColor;
@property(nonatomic) CGFloat highlightAmount;
@property(nonatomic) NSColor *backgroundColor;
@property(nonatomic) CGFloat backgroundInsetAmount;

@property(readonly, nonatomic, getter = isOnAndShowsOnState) BOOL onAndShowsOnState;

@property(nonatomic) BOOL hasPrimaryStyle;
@property(nonatomic) BOOL hasSecondaryStyle;

@property(readonly, nonatomic) NSColor *textColorForDrawing;
@property(readonly, nonatomic) NSColor *backgroundColorForDrawing;

@end