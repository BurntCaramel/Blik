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

@property (nonatomic) GLAButtonCell *cell;

@property (nonatomic) CGFloat leftSpacing;
@property (nonatomic) CGFloat rightSpacing;
@property (nonatomic) CGFloat verticalOffsetDown;

@property (nonatomic, getter = isAlwaysHighlighted) BOOL alwaysHighlighted;
@property (nonatomic, getter = isSecondary) BOOL secondary; // Shows a gray highlight

@property (nonatomic) NSColor *textHighlightColor;
@property (nonatomic) CGFloat highlightOpacity;

@property (readonly, nonatomic, getter = isOnAndShowsOnState) BOOL onAndShowsOnState;

@end


@interface GLAButtonCell : NSButtonCell

@property (nonatomic) CGFloat leftSpacing;
@property (nonatomic) CGFloat rightSpacing;
@property (nonatomic) CGFloat verticalOffsetDown;

@property (nonatomic, getter = isAlwaysHighlighted) BOOL alwaysHighlighted;
@property (nonatomic, getter = isSecondary) BOOL secondary; // Shows a gray highlight

@property (nonatomic) NSColor *textHighlightColor;
@property (nonatomic) CGFloat highlightOpacity;

@property (readonly, nonatomic, getter = isOnAndShowsOnState) BOOL onAndShowsOnState;

@end