//
//  CTCoreTextRun.h
//  CoreTextLabel
//
//  Created by chenjian on 13-12-2.
//  Copyright (c) 2013年 携程. All rights reserved.
//  富文本 Label中每一段文字
//  modified by chenjian

#import <Foundation/Foundation.h>

#define kCTDefaultCoreTextFont [UIFont systemFontOfSize:15]
#define kCTDefaultCoreTextColor [UIColor blackColor]

#define kCTCoreTextRunTargetAttributeName @"CTCoreTextRunTargetAttributeName"

#define kCTCoreTextBackgroundColorAttributeName @"CTCoreTextBackgroundColorAttributeName"
#define kCTCoreTextStrikethroughStyleAttributeName @"CTCoreTextStrikethroughStyleAttributeName"
#define kCTCoreTextStrikethroughColorAttributeName @"CTCoreTextStrikethroughColorAttributeName"

/**
 *  dictionary 插入校验
 */
@interface NSMutableDictionary (ValueValidate)

- (void)setObjectForCtrip:(id)value forKey:(id <NSCopying>)key;

@end

/**
 *  富文本 Label中每一段文字
 */
@interface CTCoreTextRun : NSObject

/**
 *  字体，默认系统15号字体
 */
@property (nonatomic, strong, readwrite) UIFont *font;

/**
 *  颜色，默认纯黑色
 */
@property (nonatomic, strong, readwrite) UIColor *textColor;

/**
 *  文本
 */
@property (nonatomic, copy, readwrite) NSString *text;

/**
 *  是否斜体显示，默认否
 */
@property (nonatomic, assign, readwrite) BOOL isItalic;

/**
 *  是否粗体显示，默认否
 */
@property (nonatomic, assign, readwrite) BOOL isBold;

/**
 *  是否展示下划线，默认否
 */
@property (nonatomic, assign, readwrite) BOOL isUnderline;

/**
 *  是否展示删除线，默认否
 */
@property (nonatomic, assign, readwrite) BOOL isStrikeThrough;

/**
 *  删除线颜色，默认0.5透明度灰色
 */
@property (nonatomic, strong, readwrite) UIColor *strikeThroughColor;

/**
 *  删除线宽度，默认1.0
 */
@property (nonatomic, assign, readwrite) CGFloat strikeThroughThickness;

/**
 *  背景色，默认未 nil，不绘制
 */
@property (nonatomic, strong, readwrite) UIColor *backgroundColor;

/**
 *  计算自身的 AttributedString
 *
 *  @return 自身的 AttributedString
 */
- (NSAttributedString*)generateAttributedString;

@end

/**
 *  点击后有高亮效果的 Run，CoreTextLabel 只会正对此类及其子类做高亮重绘工作
 */
@interface CTCoreTextHyperLink : CTCoreTextRun

/**
 *  高亮颜色，默认 nil，以 textColor 替代
 */
@property (nonatomic, strong, readwrite) UIColor *highlightedColor;

/**
 *  高亮时的背景色，默认 nil，以 backgroundColor 替代
 */
@property (nonatomic, strong, readwrite) UIColor *highlightedBackgroundColor;

/**
 *  是否高亮
 */
@property (nonatomic, assign, readwrite) BOOL isHighlighted;

@end

#define kCTDefaultCoreTextImageWidthRate 1
#define kCTDefaultCoreTextImageHeight 12
#define kCTCoreTextImageAttributeName @"CTCoreTextImageAttributeName"

/**
 *  图片 Run（可点击）
 */
@interface CTCoreTextImageRun : CTCoreTextHyperLink

/**
 *  图片
 */
@property (nonatomic, strong, readwrite) UIImage *image;

/**
 *  图片高度，默认12px
 */
@property (nonatomic, assign, readwrite) NSInteger imageHeight;

/**
 *  图片相对宽度，默认1倍高度，尽量使用1倍高度，否则涉及换行就悲剧了，俺不负责
 */
@property (nonatomic, assign, readwrite) NSInteger imageWidthRate;


@end
