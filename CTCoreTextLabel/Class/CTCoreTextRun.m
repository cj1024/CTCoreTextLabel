//
//  CTCoreTextRun.m
//  CtripWireless
//
//  Created by chenjian on 13-12-2.
//  Copyright (c) 2013年 携程. All rights reserved.
//  富文本 Label中每一段文字

#import "CTCoreTextRun.h"
#import <CoreText/CoreText.h>

@interface CTCoreTextRun ()

/**
 *  生成 Attributes
 *
 *  @return 生成的 Attributes
 */
- (NSMutableDictionary*)generateAttributes;

@end

@implementation CTCoreTextRun

#define kCTDefaultCoreTextStrokeWidth 0.0
#define kCTBoldCoreTextStrokeWidth -3.0

#pragma mark - --------------------退出清空--------------------

#pragma mark - --------------------初始化--------------------
- (id)init
{
    self = [super init];
    if (self)
    {
        _font = kCTDefaultCoreTextFont;
        _textColor = kCTDefaultCoreTextColor;
        _isItalic = NO;
        _isBold = NO;
        _isUnderline = NO;
        _isStrikeThrough = NO;
        _strikeThroughThickness = 1.0;
        _strikeThroughColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    return self;
}

#pragma mark - --------------------System--------------------

#pragma mark - --------------------功能函数--------------------

#pragma mark - --------------------手势事件--------------------

#pragma mark - --------------------按钮事件--------------------

#pragma mark - --------------------代理方法--------------------

#pragma mark - --------------------属性相关--------------------

#pragma mark - --------------------接口API--------------------
- (NSMutableDictionary*)generateAttributes
{
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:5];
    UIFont *realFont = self.font?self.font:kCTDefaultCoreTextFont;
    CTFontRef font = CTFontCreateWithName((CFStringRef)realFont.fontName, realFont.pointSize, NULL);
    //斜体
    if (self.isItalic)
    {
        CTFontRef italicFont = CTFontCreateCopyWithSymbolicTraits(font, 0.0, NULL, kCTFontItalicTrait, kCTFontItalicTrait);
        CFRelease(font);
        font = italicFont;
        CFRetain(font);
        CFRelease(italicFont);
    }
    //粗体
    [attributes setObject:[NSNumber numberWithFloat:self.isBold?kCTBoldCoreTextStrokeWidth:kCTDefaultCoreTextStrokeWidth] forKey:(id)kCTStrokeWidthAttributeName];
    //下划线
    if (self.isUnderline)
    {
        [attributes setObject:[NSNumber numberWithInteger:kCTUnderlineStyleSingle] forKey:(id)kCTUnderlineStyleAttributeName];
    }
    //删除线
    if (self.isStrikeThrough)
    {
        [attributes setObject:[NSNumber numberWithInteger:self.strikeThroughThickness] forKey:kCTCoreTextStrikethroughStyleAttributeName];
        [attributes setObject:(id)self.strikeThroughColor.CGColor forKey:kCTCoreTextStrikethroughColorAttributeName];
    }
    if (self.backgroundColor)
    {
        [attributes setObject:(id)self.backgroundColor.CGColor forKey:kCTCoreTextBackgroundColorAttributeName];
    }
    id idfont = (__bridge id)font;
    if (idfont)
    {
        [attributes setObject:idfont forKey:(id)kCTFontAttributeName];
    }
    UIColor *realTextColor = self.textColor?self.textColor:kCTDefaultCoreTextColor;
    [attributes setObject:(id)realTextColor.CGColor forKey:(id)kCTForegroundColorAttributeName];
    [attributes setObject:self forKey:kCTCoreTextRunTargetAttributeName];
    if (font != NULL)
    {
        CFRelease(font);
    }
    return attributes;
}

- (NSAttributedString*)generateAttributedString
{
    return [[NSAttributedString alloc] initWithString:self.text attributes:[self generateAttributes]];
}

@end

@implementation CTCoreTextHyperLink

- (NSMutableDictionary*)generateAttributes
{
    NSMutableDictionary *attributes = [super generateAttributes];
    if (self.isHighlighted)
    {
        UIColor *realTextColor = self.highlightedColor?self.highlightedColor:self.textColor?self.textColor:kCTDefaultCoreTextColor;
        [attributes setObject:(id)realTextColor.CGColor forKey:(id)kCTForegroundColorAttributeName];
        UIColor *realBackColor = self.highlightedBackgroundColor?self.highlightedBackgroundColor:self.backgroundColor?self.backgroundColor:nil;
        if (realBackColor != nil)
        {
            [attributes setObject:(id)realBackColor.CGColor forKey:(id)kCTCoreTextBackgroundColorAttributeName];
        }
    }
    return attributes;
}

@end

@implementation CTCoreTextImageRun

- (id)init
{
    self = [super init];
    if (self)
    {
        _imageWidthRate = kCTDefaultCoreTextImageWidthRate;
        _imageHeight = kCTDefaultCoreTextImageHeight;
    }
    return self;
}

- (NSAttributedString*)generateAttributedString
{
    NSMutableDictionary *attributes = [self generateAttributes];
    //替图片占位
    NSMutableString *relpaceString = [NSMutableString stringWithCapacity:self.imageWidthRate];
    for (int i = 0; i<self.imageWidthRate; i++)
    {
        [relpaceString appendString:@"囧"];//囧字方方正正，用在这里不错
    }
    UIFont *replaceFont = [UIFont systemFontOfSize:self.imageHeight];
    CTFontRef font = CTFontCreateWithName((CFStringRef)replaceFont.fontName, replaceFont.pointSize, NULL);
    [attributes setObject:(__bridge id)(font) forKey:(id)kCTFontAttributeName];
    [attributes setObject:(id)[UIColor clearColor].CGColor forKey:(id)kCTForegroundColorAttributeName];
    if (self.image)
    {
        [attributes setObject:self.image forKey:kCTCoreTextImageAttributeName];
    }
    CFRelease(font);
    return [[NSAttributedString alloc] initWithString:relpaceString attributes:attributes];
}

@end

