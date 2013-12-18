//
//  CTCoreTextLabel.m
//  CoreTextLabel
//
//  Created by chenjian on 13-12-2.
//  Copyright (c) 2013年 携程. All rights reserved.
//  富文本 Label

#import "CTCoreTextLabel.h"
#import <CoreText/CoreText.h>

#define kCTDefaultTextAlignment         NSTextAlignmentLeft
#define kCTDefaultLineBreakMode         NSLineBreakByWordWrapping
#define kCTDefaultVerticalAlignment     eCTCoreTextLabelVerticalTextAlignmentBottom
#define kCTDefaultLineSpacing           1.0f

//是否由本控件执行 Truncating（系统 ParagraphStyle 有问题），目前在实验阶段
#define kCTCoreTextLabelManuallyTruncating

// 更精确的 Truncating，目前无法正确使用
//#define kCTCoreTextLabelAccurateTruncating

@interface CTCoreTextLabel ()
{
    NSMutableArray *runs_;
    CTCoreTextRun *theRunTouchBegin;
    UITouchPhase lastTouchPhase;
}

/**
 *  计算好的 AttributedString
 */
@property (nonatomic, strong, readwrite) NSAttributedString *calculatedAttributedString;

/**
 *  计算好的 TextFrame
 */
@property (nonatomic, unsafe_unretained, readwrite) CTFrameRef calculatedTextFrame;

/**
 *  计算好的 Text 大小
 */
@property (nonatomic, assign, readwrite) CGSize calculatedTextSize;

@end

@implementation CTCoreTextLabel

@synthesize runs = runs_;

#pragma mark - --------------------退出清空--------------------
- (void)dealloc
{
    self.calculatedTextFrame = NULL;
}

#pragma mark - --------------------初始化--------------------
- (id)init
{
    self = [super init];
    if (self)
    {
        [self initData];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initData];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initData];
    }
    return self;
}

- (void)initData
{
    runs_ = [NSMutableArray arrayWithCapacity:3];
    _textAlignment = kCTDefaultTextAlignment;
    _textVerticalAlignment = kCTDefaultVerticalAlignment;
    _lineBreakMode = kCTDefaultLineBreakMode;
    _maxWidth = MAXFLOAT;
    _maxHeight = MAXFLOAT;
    _lineSpacing  = kCTDefaultLineSpacing;
    lastTouchPhase = UITouchPhaseEnded;
    [self setMultipleTouchEnabled:NO];
    [self setExclusiveTouch:YES];
}

#pragma mark - --------------------System--------------------
- (void)drawRect:(CGRect)rect
{
    if (self.calculatedAttributedString == nil || self.calculatedTextFrame == nil)
    {
        [super drawRect:rect];
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawAttributedStringInContext:context];
}

#pragma mark - --------------------功能函数--------------------
/**
 *  将 self.textAlignmemnt 转换为 CTTextAlignment
 *
 *  @return 转换结果
 */
- (CTTextAlignment)paragraphTextAlignment
{
    switch (self.textAlignment)
    {
        case NSTextAlignmentRight:
            return kCTRightTextAlignment;
            break;
        case NSTextAlignmentCenter:
            return kCTTextAlignmentCenter;
            break;
        case NSTextAlignmentJustified:
            return kCTTextAlignmentJustified;
            break;
        case NSTextAlignmentNatural:
            return kCTTextAlignmentNatural;
            break;
        case NSTextAlignmentLeft:
            return kCTTextAlignmentLeft;
            break;
        default:
            return kCTLeftTextAlignment;
            break;
    }
}

/**
 *  将 self. lineBreakMode 转换为 CTLineBreakMode
 *
 *  @return 转换结果
 */
- (CTLineBreakMode)paragraphLineBreakMode
{
    switch (self.lineBreakMode)
    {
        case NSLineBreakByCharWrapping:
            return kCTLineBreakByCharWrapping;
            break;
        case NSLineBreakByClipping:
            return kCTLineBreakByClipping;
            break;
        case NSLineBreakByWordWrapping:
            return kCTLineBreakByWordWrapping;
            break;
        default:
            return kCTLineBreakByWordWrapping;
            break;
    }
}

/**
 *  绘制文本
 *
 *  @param context 上下文
 */
- (void)drawAttributedStringInContext:(CGContextRef)context
{
    [self drawAttributedStringInContextByRun:context TextFrame:self.calculatedTextFrame];
}

/**
 *  直接使用 TextFrame 绘制
 *
 *  @param context   上下文
 *  @param textFrame 计算好的 textFrame
 */
- (void)drawAttributedStringInContext:(CGContextRef)context ByTextFrame:(CTFrameRef)textFrame
{
    CGContextSaveGState(context);
    //图像方向转换
    CGContextConcatCTM(context, CGAffineTransformScale(CGAffineTransformMakeTranslation(0, self.bounds.size.height), 1.f, -1.f));
    CTFrameDraw(textFrame, context);
    CGContextRestoreGState(context);
}

/**
 *  计算垂直偏移，为保证垂直居中
 *
 *  @return 垂直偏移
 */
- (CGFloat)verticalOffset
{
    CGFloat vOffset = 0;
    if (!CGSizeEqualToSize(self.calculatedTextSize, CGSizeZero))
    {
        vOffset = self.bounds.size.height - self.calculatedTextSize.height;
        vOffset /= 2;
    }
    return vOffset;
}

/**
 *  计算 run 在 self 中的位置
 *
 *  @param run    要计算的 run
 *  @param line   run 所在的 line
 *  @param origin run 的基础偏移
 *
 *  @return 计算好的位置（和 UI 表现有一个翻转的偏移）
 */
- (CGRect)calculateRunRect:(CTRunRef)run Line:(CTLineRef)line Origin:(CGPoint)origin
{
    CGRect runRect;
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    runRect.size.width = CTRunGetTypographicBounds(run,CFRangeMake(0, 0),&ascent,&descent,&leading);
    runRect.size.height = ascent + descent;
    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringIndicesPtr(run)[0], NULL);
    runRect.origin.x = origin.x + xOffset;
    runRect.origin.y = origin.y - descent + [self verticalOffset];
    return runRect;
}

/**
 *  由本控件处理 Truncating
 *
 *  @param CTLineRef 需要处理的 line
 *
 *  @return  处理好的 line
 */
#ifdef kCTCoreTextLabelManuallyTruncating
- (CTLineRef)createTuncateLine:(CTLineRef)line CurrentLine:(NSInteger)currentLine TotalLine:(NSInteger)totalLine
{
    CTLineRef result = CFRetain(line);
    CGRect lineBounds = CGRectZero;
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    CGFloat whiteSpace = CTLineGetTrailingWhitespaceWidth(line);
    lineBounds.size.width = CTLineGetTypographicBounds(line,&ascent,&descent,&leading) - whiteSpace;
    lineBounds.size.height = ascent + descent;
    CFRange currentRange = CTFrameGetVisibleStringRange(self.calculatedTextFrame), totalRange = CTFrameGetStringRange(self.calculatedTextFrame);
    BOOL needTruncating = currentRange.location != totalRange.location || currentRange.length != totalRange.length;
    if (self.lineBreakMode == NSLineBreakByTruncatingTail && currentLine == totalLine - 1 && needTruncating)
    {
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        NSInteger runCount = CFArrayGetCount(runs);
        if (runCount > 0)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, runCount - 1);
            NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
            NSAttributedString *truncatedString = [[NSAttributedString alloc]initWithString:@"\u2026" attributes:attDic];
            CTLineRef token = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncatedString);
#ifdef kCTCoreTextLabelAccurateTruncating
            CGFloat u2026width = CTLineGetImageBounds(token, NULL).size.width;
            if (whiteSpace < u2026width)
            {
                CFRelease(result);
                result = CTLineCreateTruncatedLine(line, self.bounds.size.width, kCTLineTruncationEnd, token);
            }
            else
            {
                CFRelease(result);
                result = CTLineCreateTruncatedLine(line, lineBounds.size.width - 1, kCTLineTruncationEnd, token);
            }
#else
            CFRelease(result);
            result = CTLineCreateTruncatedLine(line, lineBounds.size.width - 1, kCTLineTruncationEnd, token);
#endif
            CFRelease(token);
        }
    }
    else if (self.lineBreakMode == NSLineBreakByTruncatingHead && currentLine == totalLine - 1 && needTruncating)
    {
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        NSInteger runCount = CFArrayGetCount(runs);
        if (runCount > 0)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, 0);
            NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
            NSAttributedString *truncatedString = [[NSAttributedString alloc]initWithString:@"\u2026" attributes:attDic];
            CTLineRef token = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncatedString);
#ifdef kCTCoreTextLabelAccurateTruncating
            CGFloat u2026width = CTLineGetImageBounds(token, NULL).size.width;
            if (whiteSpace < u2026width)
            {
                CFRelease(result);
                result = CTLineCreateTruncatedLine(line, self.bounds.size.width - 1, kCTLineTruncationStart, token);
            }
            else
            {
                CFRelease(result);
                result = CTLineCreateTruncatedLine(line, lineBounds.size.width - 1, kCTLineTruncationStart, token);
            }
#else
            CFRelease(result);
            result = CTLineCreateTruncatedLine(line, lineBounds.size.width - 1, kCTLineTruncationStart, token);
#endif
            CFRelease(token);
        }
    }
    else if (self.lineBreakMode == NSLineBreakByTruncatingMiddle && currentLine == totalLine - 1 && needTruncating)
    {
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        NSInteger runCount = CFArrayGetCount(runs);
        if (runCount > 0)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, runCount/2);
            NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
            NSAttributedString *truncatedString = [[NSAttributedString alloc]initWithString:@"\u2026" attributes:attDic];
            CTLineRef token = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncatedString);
#ifdef kCTCoreTextLabelAccurateTruncating
            CGFloat u2026width = CTLineGetImageBounds(token, NULL).size.width;
            if (whiteSpace < u2026width)
            {
                CFRelease(result);
                result = CTLineCreateTruncatedLine(line, self.bounds.size.width - 1, kCTLineTruncationMiddle, token);
            }
            else
            {
                CFRelease(result);
                result = CTLineCreateTruncatedLine(line, lineBounds.size.width - 1, kCTLineTruncationMiddle, token);
            }
#else
            CFRelease(result);
            result = CTLineCreateTruncatedLine(line, lineBounds.size.width - 1, kCTLineTruncationMiddle, token);
#endif
            CFRelease(token);
        }
    }
    return result;
}
#endif

/**
 *  针对每一个 run 绘制，如需要图文混合等特殊布局需要使用此种方式
 *
 *  @param context 上下文
 */
- (void)drawAttributedStringInContextByRun:(CGContextRef)context TextFrame:(CTFrameRef)textFrame
{
    CGContextSaveGState(context);
    //图像方向转换
    CGContextConcatCTM(context, CGAffineTransformScale(CGAffineTransformMakeTranslation(0, self.bounds.size.height), 1.f, -1.f));
    // 获取CTFrame中的CTLine
    CFArrayRef lines = CTFrameGetLines(textFrame);
    NSInteger lineCount = CFArrayGetCount(lines);
    CGPoint origins[lineCount];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
    CTFrameGetFrameAttributes(textFrame);
    CGFloat baseOffset = 9;//此值暂时确定为9，用于垂直对齐
    CGFloat vOffset = [self verticalOffset];
    for (int i = 0; i < lineCount; i++)
    {
        CGPoint origin = origins[i];
        // 获取CTLine中的CTRun
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRetain(line);
#ifdef kCTCoreTextLabelManuallyTruncating
        CTLineRef truncatedLine = [self createTuncateLine:line CurrentLine:i TotalLine:lineCount];
        CFRelease(line);
        line = truncatedLine;
        CFRetain(line);
        CFRelease(truncatedLine);
#endif
        CGRect lineBounds = CTLineGetImageBounds(line, context);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        for (int j = 0; j < CFArrayGetCount(runs); j++)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
            // 不管是绘制链接还是表情，我们都需要知道绘制区域的大小，所以我们需要计算下
            CGRect runBounds = [self calculateRunRect:run Line:line Origin:origin];
            //CFRange range = CTRunGetStringRange(run);
            CGFloat ox = origin.x,oy = origin.y+vOffset;
            CGFloat gap = lineBounds.size.height - runBounds.size.height;
            switch (self.textVerticalAlignment)
            {
                case eCTCoreTextLabelVerticalTextAlignmentBottom:
                    break;
                case eCTCoreTextLabelVerticalTextAlignmentMiddle:
                    oy = oy + gap / 2 - baseOffset / 2;
                    break;
                case eCTCoreTextLabelVerticalTextAlignmentTop:
                    oy = oy + gap - baseOffset;
                    break;
                default:
                    break;
            }
            //最先背景色
            if ([attDic objectForKey:kCTCoreTextBackgroundColorAttributeName])
            {
                CGColorRef backColor = (__bridge CGColorRef)([attDic objectForKey:kCTCoreTextBackgroundColorAttributeName]);
                CGContextSetFillColorWithColor(context, backColor);
                CGRect backgroundBounds = CGRectInset(runBounds, 0, -2);
                CGContextFillRect(context, backgroundBounds);
            }
            CGContextSetTextPosition(context, ox, oy);
            CTRunDraw(run, context, CFRangeMake(0, 0));
            //绘制删除线
            if ([attDic objectForKey:kCTCoreTextStrikethroughStyleAttributeName]&&[attDic objectForKey:kCTCoreTextStrikethroughColorAttributeName])
            {
                CGFloat strikeThroughThickness = [[attDic objectForKey:kCTCoreTextStrikethroughStyleAttributeName] floatValue];
                CGColorRef strikeThroughColor = (__bridge CGColorRef)([attDic objectForKey:kCTCoreTextStrikethroughColorAttributeName]);
                CGRect strikeThroughBounds = runBounds;
                strikeThroughBounds.origin.y = runBounds.origin.y + (runBounds.size.height - strikeThroughThickness) / 2;
                strikeThroughBounds.size.height = strikeThroughThickness;
                CGContextSetFillColorWithColor(context, strikeThroughColor);
                CGContextFillRect(context, strikeThroughBounds);
            }
            //绘制 Image
            if ([attDic objectForKey:kCTCoreTextImageAttributeName])
            {
                UIImage *image = [attDic objectForKey:kCTCoreTextImageAttributeName];
                CGContextDrawImage(context, runBounds, image.CGImage);
            }
        }
        CFRelease(line);
    }
    CGContextRestoreGState(context);
}

- (CTCoreTextRun*)runOfTouch:(CGPoint)touch
{
    // 获取CTFrame中的CTLine
    if (self.calculatedTextFrame == nil || self.calculatedAttributedString == nil)
    {
        return nil;
    }
    CFArrayRef lines = CTFrameGetLines(self.calculatedTextFrame);
    NSInteger lineCount = CFArrayGetCount(lines);
    CGPoint origins[lineCount];
    CTFrameGetLineOrigins(self.calculatedTextFrame, CFRangeMake(0, 0), origins);
    for (int i = 0; i < lineCount; i++)
    {
        CGPoint origin = origins[i];
        // 获取CTLine中的CTRun
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRetain(line);
#ifdef kCTCoreTextLabelManuallyTruncating
        CTLineRef truncatedLine = [self createTuncateLine:line CurrentLine:i TotalLine:lineCount];
        CFRelease(line);
        line = truncatedLine;
        CFRetain(line);
        CFRelease(truncatedLine);
#endif
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        for (int j = 0; j < CFArrayGetCount(runs); j++)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            // 不管是绘制链接还是表情，我们都需要知道绘制区域的大小，所以我们需要计算下，实际 Rect 要做一个翻转
            CGRect runBounds = [self calculateRunRect:run Line:line Origin:origin];
            runBounds = CGRectApplyAffineTransform(runBounds, CGAffineTransformScale(CGAffineTransformMakeTranslation(0, self.bounds.size.height), 1.f, -1.f));
            if (CGRectContainsPoint(runBounds, touch))
            {
                // 获取CTRun的属性
                NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
                CTCoreTextRun *theRun = [attDic objectForKey:kCTCoreTextRunTargetAttributeName];
                CFRelease(line);
                return theRun;
            }
        }
        CFRelease(line);
    }
    return nil;
}

- (CTCoreTextRun*)runOfTouches:(NSSet*)touches
{
    if ([touches count]>0)
    {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:touch.view];
        return [self runOfTouch:point];
    }
    return nil;
}

#pragma mark - --------------------手势事件--------------------
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CTCoreTextRun *theRun = [self runOfTouches:touches];
    theRunTouchBegin = theRun;
    lastTouchPhase = UITouchPhaseBegan;
    if ([theRunTouchBegin isKindOfClass:[CTCoreTextHyperLink class]])
    {
        ((CTCoreTextHyperLink*)theRunTouchBegin).isHighlighted = YES;
        [self reArrange];
    }
    if([self.touchDelegate respondsToSelector:@selector(theRunTouchBegan:)] && theRun)
    {
        [self.touchDelegate theRunTouchBegan:theRun];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    CTCoreTextRun *theRun = [self runOfTouches:touches];
    BOOL isTouchUpInside = theRun != nil && theRun == theRunTouchBegin && lastTouchPhase == UITouchPhaseBegan;
    if ([theRunTouchBegin isKindOfClass:[CTCoreTextHyperLink class]])
    {
        ((CTCoreTextHyperLink*)theRunTouchBegin).isHighlighted = NO;
        [self reArrange];
    }
    theRunTouchBegin = nil;
    lastTouchPhase = UITouchPhaseCancelled;
    if([self.touchDelegate respondsToSelector:@selector(theRunTouchCancelled:)] && theRun)
    {
        [self.touchDelegate theRunTouchCancelled:theRun];
    }
    if (isTouchUpInside && [self.touchDelegate respondsToSelector:@selector(theRunTouchUpInside:)] && theRun)
    {
        [self.touchDelegate theRunTouchUpInside:theRun];
    }
    [super touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CTCoreTextRun *theRun = [self runOfTouches:touches];
    BOOL isTouchUpInside = theRun != nil && theRun == theRunTouchBegin && lastTouchPhase == UITouchPhaseMoved;
    if ([theRunTouchBegin isKindOfClass:[CTCoreTextHyperLink class]])
    {
        ((CTCoreTextHyperLink*)theRunTouchBegin).isHighlighted = NO;
        [self reArrange];
    }
    theRunTouchBegin = nil;
    lastTouchPhase = UITouchPhaseEnded;
    if([self.touchDelegate respondsToSelector:@selector(theRunTouchEnded:)] && theRun)
    {
        [self.touchDelegate theRunTouchEnded:theRun];
    }
    if (isTouchUpInside && [self.touchDelegate respondsToSelector:@selector(theRunTouchUpInside:)] && theRun)
    {
        [self.touchDelegate theRunTouchUpInside:theRun];
    }
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CTCoreTextRun *theRun = [self runOfTouches:touches];
    if ([theRunTouchBegin isKindOfClass:[CTCoreTextHyperLink class]])
    {
        BOOL fromHighlighted = ((CTCoreTextHyperLink*)theRunTouchBegin).isHighlighted, toHighlighted = theRunTouchBegin == theRun;
        ((CTCoreTextHyperLink*)theRunTouchBegin).isHighlighted = toHighlighted;
        if (fromHighlighted != toHighlighted)
        {
            [self reArrange];
        }
    }
    lastTouchPhase = UITouchPhaseMoved;
    if([self.touchDelegate respondsToSelector:@selector(theRunTouchMoved:)] && theRun)
    {
        [self.touchDelegate theRunTouchMoved:theRun];
    }
    [super touchesMoved:touches withEvent:event];
}

#pragma mark - --------------------按钮事件--------------------


#pragma mark - --------------------代理方法--------------------


#pragma mark - --------------------属性相关--------------------
- (void)setRuns:(NSArray *)runs
{
    [self removeAllRun];
    if (runs)
    {
        [self addRunsFromArray:runs];
    }
}

- (void)setCalculatedTextFrame:(CTFrameRef)calculatedTextFrame
{
    if (self.calculatedTextFrame != NULL)
    {
        CFRelease(self.calculatedTextFrame);
    }
    _calculatedTextFrame = calculatedTextFrame;
    if (self.calculatedTextFrame != NULL)
    {
        CFRetain(self.calculatedTextFrame);
    }
}

#pragma mark - --------------------接口API--------------------
- (void)addRun:(CTCoreTextRun *)run
{
    [runs_ addObject:run];
}

- (void)addRunsFromArray:(NSArray *)array
{
    for (id run in array)
    {
        if ([run isKindOfClass:[CTCoreTextRun class]])
        {
            [runs_ addObject:run];
        }
    }
}

- (CTCoreTextRun*)addRunWithText:(NSString *)text TextColor:(UIColor *)color Font:(UIFont *)font
{
    if (text == nil)
    {
        text = @"";
    }
    if (font == nil)
    {
        font = kCTDefaultCoreTextFont;
    }
    if (color == nil)
    {
        color = kCTDefaultCoreTextColor;
    }
    CTCoreTextRun *run = [[CTCoreTextRun alloc] init];
    run.text = text;
    run.font = font;
    run.textColor = color;
    [self addRun:run];
    return run;
}

- (void)removeRun:(CTCoreTextRun *)run
{
    [runs_ removeObject:run];
}

- (void)removeAllRun
{
    [runs_ removeAllObjects];
}

- (CGSize)desiredSize
{
    NSMutableAttributedString *finalAttributedString = [[NSMutableAttributedString alloc] init];
    for (CTCoreTextRun *run in self.runs)
    {
        [finalAttributedString appendAttributedString:[run generateAttributedString]];
    }
    NSMutableDictionary *paraphAttributes = [NSMutableDictionary dictionaryWithCapacity:3];
    CTTextAlignment coreTextAlignment = [self paragraphTextAlignment];
    CTLineBreakMode coreTextLBMode = [self paragraphLineBreakMode];
    CGFloat lineHeight = self.lineSpacing < 0 ? 0 : self.lineSpacing;
    CTParagraphStyleSetting paraStyles[4] =
    {
        {.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = (const void*)&coreTextAlignment},
        {.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void*)&coreTextLBMode},
        {.spec = kCTParagraphStyleSpecifierMinimumLineSpacing, .valueSize = sizeof(CGFloat), .value = (const void*)&lineHeight},
        {.spec = kCTParagraphStyleSpecifierMaximumLineSpacing, .valueSize = sizeof(CGFloat), .value = (const void*)&lineHeight},
    };
    CTParagraphStyleRef aStyle = CTParagraphStyleCreate(paraStyles, 4);
    [paraphAttributes setObject:(__bridge id)(aStyle) forKey:(id)kCTParagraphStyleAttributeName];
    [finalAttributedString addAttributes:paraphAttributes range:NSMakeRange(0, finalAttributedString.length)];
    CFRelease(aStyle);
    self.calculatedAttributedString = finalAttributedString;
    //计算，准备绘制
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.calculatedAttributedString);
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(self.maxWidth, self.maxHeight), NULL);
    if (self.numberOfLines>0)
    {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0,0, self.bounds.size.width, ceilf(textSize.height)));
        CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(textFrame);
        NSInteger linesCount = CFArrayGetCount(lines);
        if (linesCount > self.numberOfLines)
        {
            CTFrameGetFrameAttributes(textFrame);
            // 获取CTLine中的CTRun
            CTLineRef line = CFArrayGetValueAtIndex(lines, self.numberOfLines - 1);
            CFRange stringRange = CTLineGetStringRange(line);
            stringRange.length += stringRange.location;
            stringRange.location = 0;
            NSAttributedString *stringForVisibleLine = [self.calculatedAttributedString attributedSubstringFromRange:NSMakeRange(stringRange.location, stringRange.length)];
            CTFramesetterRef realFrameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)stringForVisibleLine);
            CFRelease(framesetter);
            framesetter = realFrameSetter;
            CFRetain(framesetter);
            CFRelease(realFrameSetter);
            textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(self.maxWidth, self.maxHeight), NULL);
        }
        CFRelease(path);
        CFRelease(textFrame);
    }
    textSize = CGSizeMake(ceilf(textSize.width), ceilf(textSize.height));
    CFRelease(framesetter);
    return textSize;
}

- (void)reArrange
{
    //计算，准备绘制
    self.calculatedTextSize = [self desiredSize];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.calculatedAttributedString);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0,0, self.bounds.size.width, self.calculatedTextSize.height));
    CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0,0), path, NULL);
    self.calculatedTextFrame = textFrame;
    CFRelease(textFrame);
    CGPathRelease(path);
    CFRelease(framesetter);
    [self setNeedsDisplay];
}

@end
