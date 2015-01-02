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

@end


@interface NSButton (GLAButtonStyling)

+ (NSColor *)backgroundColorForDrawingGLAStyledButton:(NSButtonCell<GLAButtonStyling> *)button highlighted:(BOOL)highlighted;
+ (NSColor *)textColorForDrawingGLAStyledButton:(NSButtonCell<GLAButtonStyling> *)button;

+ (void)GLAStyledCell:(NSButtonCell<GLAButtonStyling> *)buttonCell drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView;

+ (NSRect)GLAStyledCell:(NSButtonCell<GLAButtonStyling> *)buttonCell adjustTitleRect:(NSRect)titleRect;
+ (NSAttributedString *)GLAStyledCell:(NSButtonCell<GLAButtonStyling> *)buttonCell adjustAttributedTitle:(NSAttributedString *)title;
+ (NSRect)GLAStyledCell:(NSButtonCell<GLAButtonStyling> *)buttonCell drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView;

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