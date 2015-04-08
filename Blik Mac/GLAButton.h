//
//  GLAButton.h
//  
//
//  Created by Patrick Smith on 14/07/2014.
//
//

@import Cocoa;
@class GLAButtonCell;


@protocol GLAButtonStyling <NSObject>

@property(nonatomic) CGFloat leftSpacing;
@property(nonatomic) CGFloat rightSpacing;
@property(nonatomic) CGFloat verticalOffsetDown;

@property(nonatomic, getter = isAlwaysHighlighted) BOOL alwaysHighlighted;

@property(nonatomic) NSColor *textHighlightColor;
@property(nonatomic) NSColor *backgroundColor;
@property(nonatomic) CGFloat backgroundInsetAmount;
@property(nonatomic) CGFloat backgroundInsetXAmount;
@property(nonatomic) CGFloat backgroundInsetYAmount;
@property(nonatomic) CGFloat highlightAmount;

@property(readonly, nonatomic, getter = isOnAndShowsOnState) BOOL onAndShowsOnState;

@property(nonatomic) BOOL hasPrimaryStyle;
@property(nonatomic) BOOL hasSecondaryStyle;

@property(nonatomic) NSRect insetBounds;

@end


@interface NSButton (GLAButtonStyling)

+ (NSColor *)backgroundColorForDrawingGLAStyledButton:(NSActionCell<GLAButtonStyling> *)button selected:(BOOL)selected highlighted:(BOOL)highlighted;
+ (NSColor *)textColorForDrawingGLAStyledButton:(NSActionCell<GLAButtonStyling> *)button;
+ (NSRect)insetBoundsForGLAStyledCell:(NSActionCell<GLAButtonStyling> *)buttonCell withBounds:(NSRect)bounds inView:(NSView *)controlView;

+ (void)GLAStyledCell:(NSActionCell<GLAButtonStyling> *)buttonCell drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView;

+ (NSRect)GLAStyledCell:(NSActionCell<GLAButtonStyling> *)buttonCell adjustTitleRect:(NSRect)titleRect;
+ (NSAttributedString *)GLAStyledCell:(NSActionCell<GLAButtonStyling> *)buttonCell adjustAttributedTitle:(NSAttributedString *)title;
+ (NSRect)GLAStyledCell:(NSActionCell<GLAButtonStyling> *)buttonCell drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView;

- (void)gla_animateHighlightForHovered:(BOOL)hovered;
- (void)gla_animateHighlightForPressed:(BOOL)pressed;
- (void)gla_animateHighlightForOn:(BOOL)on;

@end

/*
@interface GLAButtonCellStyle : NSObject

@property(nonatomic) CGFloat leftSpacing;
@property(nonatomic) CGFloat rightSpacing;
@property(nonatomic) CGFloat verticalOffsetDown;

@property(nonatomic, getter = isAlwaysHighlighted) BOOL alwaysHighlighted;

@property(nonatomic) NSColor *textHighlightColor;
@property(nonatomic) NSColor *backgroundColor;
@property(nonatomic) CGFloat backgroundInsetAmount;
@property(nonatomic) CGFloat highlightAmount;

@property(readonly, nonatomic, getter = isOnAndShowsOnState) BOOL onAndShowsOnState;

@property(nonatomic) BOOL hasPrimaryStyle;
@property(nonatomic) BOOL hasSecondaryStyle;

@end
*/

@interface GLAButton : NSButton <GLAButtonStyling>

@property(nonatomic) GLAButtonCell *cell;

@end


@interface GLAButtonCell : NSButtonCell <GLAButtonStyling>

//@property(nonatomic) GLAButtonCellStyle *gla_style;

@end