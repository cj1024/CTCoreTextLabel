//
//  CTCoreTextLabel.h
//  CtripWireless
//
//  Created by chenjian on 13-12-2.
//  Copyright (c) 2013年 携程. All rights reserved.
//  富文本 Label
//  modified by chenjian

#import <UIKit/UIKit.h>
#import "CTCoreTextRun.h"

/**
 *  文本垂直对齐方式
 */
typedef enum
{
    eCTCoreTextLabelVerticalTextAlignmentBottom,    //底部对齐
    eCTCoreTextLabelVerticalTextAlignmentMiddle,    //居中对齐
    eCTCoreTextLabelVerticalTextAlignmentTop        //上部对齐
}eCTCoreTextLabelVerticalTextAlignment;

/**
 *  手势回调
 */
@protocol CTCoreTextRunTouchDelegate <NSObject>

@optional
- (void)theRunTouchBegan:(CTCoreTextRun*)run;
- (void)theRunTouchCancelled:(CTCoreTextRun*)run;
- (void)theRunTouchEnded:(CTCoreTextRun*)run;
- (void)theRunTouchMoved:(CTCoreTextRun*)run;
- (void)theRunTouchUpInside:(CTCoreTextRun*)run;

@end

/**
 *  富文本 Label
 */
@interface CTCoreTextLabel : UIView

/**
 *  文本布局方式，默认 UITextAlignmentLeft，仅 Left，Center，Right 明白是什么意思，测试过
 */
@property (nonatomic, assign, readwrite) NSTextAlignment textAlignment;

/**
 *  文本垂直布局方式，默认 eCTCoreTextLabelVerticalTextAlignmentBottom，目前仅底部对齐支持比较好
 */
@property (nonatomic, assign, readwrite) eCTCoreTextLabelVerticalTextAlignment textVerticalAlignment;

/**
 *  文本换行方式，默认 NSLineBreakByWordWrapping，目前由于技术原因 Truncating 类型的展示可能有缺陷
 */
@property (nonatomic, assign, readwrite) NSLineBreakMode lineBreakMode;

/**
 *  强制最多显示行数，默认0，<=0表不限制
 */
@property (nonatomic, assign, readwrite) NSInteger numberOfLines;

/**
 *  文本布局区域宽度大小，超过 maxWidth自动换行，否则一行显示，默认 MAXFLOAT
 */
@property (nonatomic, assign, readwrite) CGFloat maxWidth;

/**
 *  文本布局区域高度大小，超过 maxHeight按 lineBreakMode 显示，默认 MAXFLOAT
 */
@property (nonatomic, assign, readwrite) CGFloat maxHeight;

/**
 *  存储所有富文本段的 array，存储 CTCoreTextRun
 */
@property (nonatomic, strong, readwrite) NSArray *runs;

/**
 *  行间距，默认1.0，强制大于0
 */
@property (nonatomic, assign, readwrite) CGFloat lineSpacing;

/**
 *  手势回调
 */
@property (nonatomic, unsafe_unretained, readwrite) IBOutlet id<CTCoreTextRunTouchDelegate> touchDelegate;

/**
 *  添加一段富文本
 *
 *  @param run 富文本实体
 */
- (void)addRun:(CTCoreTextRun*)run;

/**
 *  添加多段富文本
 *
 *  @param array 富文本实体Array
 */
- (void)addRunsFromArray:(NSArray*)array;

/**
 *  添加一段富文本的简化接口
 *
 *  @param text  文案
 *  @param color 颜色
 *  @param font  字体
 *
 *  @return 添加的 run
 */
- (CTCoreTextRun*)addRunWithText:(NSString*)text TextColor:(UIColor*)color Font:(UIFont*)font;

/**
 *  去除一段富文本
 *
 *  @param run 富文本实体
 */
- (void)removeRun:(CTCoreTextRun*)run;

/**
 *  清空富文本
 */
- (void)removeAllRun;

/**
 *  计算大小
 *
 *  @return 需要的区域大小，调用者可根据此大小调整 View 的大小
 */
- (CGSize)desiredSize;

/**
 *  重新排版
 *  建议使用desiredSize方法获取尺寸后先设置 View 大小，再调用此函数
 */
- (void)reArrange;

@end
