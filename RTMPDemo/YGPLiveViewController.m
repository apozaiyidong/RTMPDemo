//
//  YGPLiveViewController.m
//  RTMPDemo
//
//  Created by 国平 杨 on 16/12/27.
//  Copyright © 2016年 国平 杨. All rights reserved.
//

#import "YGPLiveViewController.h"
#import "YGPCaptureSessionManager.h"
@interface YGPLiveViewController (){
    UIButton *_stopButton;
    UIButton *_startButton;
}
@property (strong, nonatomic) YGPCaptureSessionManager *sessionManager;


@end

@implementation YGPLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect frame = self.view.frame;
    frame.size.height = frame.size.height - 100;
    
    self.sessionManager = [[YGPCaptureSessionManager alloc]init];
    [self.sessionManager configurePreviewWithSuperView:self.view];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    _stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_stopButton setBackgroundColor:[UIColor redColor]];
    [_stopButton setFrame:CGRectMake(50, 100, 30, 30)];
    
    [_stopButton addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_stopButton];
    
    _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_startButton setBackgroundColor:[UIColor blueColor]];
    [_startButton setFrame:CGRectMake(50, 320, 30, 30)];
    
    [_startButton addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_startButton];
    
}

- (void)stop{

    [self.sessionManager end];
    
}

- (void)start{

    self.sessionManager.isSendRTMP = YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
