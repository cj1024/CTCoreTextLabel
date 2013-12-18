//
//  CTMainViewController.m
//  CoreTextLable
//
//  Created by j_chen on 13-12-2.
//  Copyright (c) 2013年 j_chen. All rights reserved.
//  类文件说明

#import "CTMainViewController.h"

@interface CTMainViewController ()

@property (nonatomic, strong, readwrite) IBOutlet CTCoreTextLabel *mDisplayField;

@property (nonatomic, strong, readwrite) IBOutlet UIScrollView *mScrollView;

@property (nonatomic, strong, readwrite) IBOutlet UITextField *mTextField;

@property (nonatomic, strong, readwrite) CTCoreTextRun *mRunReminder;
@property (nonatomic, strong, readwrite) UIColor *mColorReminder;

@end

@implementation CTMainViewController

#pragma mark - --------------------退出清空--------------------
- (void)dealloc
{
    
}

#pragma mark - --------------------初始化--------------------
#pragma mark 数据初始化
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    
    }
    return self;
}

#pragma mark 视图初始化
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mTextField.delegate = self;
    self.mDisplayField.maxWidth = 320;
    self.mDisplayField.textAlignment = NSTextAlignmentLeft;
    self.mDisplayField.lineBreakMode = NSLineBreakByTruncatingTail;
    self.mDisplayField.numberOfLines = 2;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    [self.view addGestureRecognizer:gesture];
}

#pragma mark - --------------------System--------------------
#pragma mark 内存警告事件处理函数
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - --------------------功能函数--------------------


#pragma mark - --------------------手势事件--------------------
- (IBAction)addRun:(id)sender
{
    CTCoreTextHyperLink *run = [[CTCoreTextHyperLink alloc] init];
    run.isItalic = arc4random()%2 == 1;
    run.isBold = arc4random()%2 == 1;
    run.isUnderline = arc4random()%2 == 1;
    run.text = self.mTextField.text;
    run.font = [UIFont systemFontOfSize:arc4random()%10+20];
    run.textColor = [UIColor colorWithRed:(arc4random()%180)/255.0 green:(arc4random()%180)/255.0 blue:(arc4random()%180)/255.0 alpha:1];
    run.highlightedColor = [UIColor colorWithRed:(arc4random()%255)/255.0 green:(arc4random()%255)/255.0 blue:(arc4random()%255)/255.0 alpha:1];
    run.highlightedBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.mDisplayField.runs];
    [array addObject:run];
    CTCoreTextImageRun *imageRun = [[CTCoreTextImageRun alloc] init];
    imageRun.image = [UIImage imageNamed:[NSString stringWithFormat:@"face%d.png",arc4random()%6]];
    imageRun.imageHeight = arc4random()%10+20;
    imageRun.highlightedBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
//    [array addObject:imageRun];
    self.mDisplayField.runs = array;
    CGSize desiredSize = [self.mDisplayField desiredSize];
    self.mDisplayField.frame = CGRectMake(0, 0, 320, desiredSize.height);
    [self.mScrollView setContentSize:desiredSize];
    [self.mDisplayField reArrange];
    self.mTextField.text = @"";
}

- (IBAction)clearRun:(id)sender
{
    [self.mDisplayField removeAllRun];
    CGSize desiredSize = [self.mDisplayField desiredSize];
    self.mDisplayField.frame = CGRectMake(0, 0, 320, desiredSize.height);
    [self.mDisplayField reArrange];
}

#pragma mark - --------------------按钮事件--------------------

#pragma mark - --------------------代理方法--------------------
- (void)viewTapped:(id)sender
{
    [self.mTextField resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [UIView animateWithDuration:0.5 animations:^
    {
        self.view.transform = CGAffineTransformMakeTranslation(0, -self.view.frame.size.height/2);
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [UIView animateWithDuration:0.5 animations:^
    {
        self.view.transform = CGAffineTransformIdentity;
    }];
}

- (void)theRunTouchUpInside:(CTCoreTextRun *)run
{
    NSLog(@"Run Tapped:%@",run.text);
}

#pragma mark - --------------------属性相关--------------------


#pragma mark - --------------------接口API--------------------


@end
