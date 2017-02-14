//
//  ViewController.m
//  RTMPDemo
//
//  Created by 国平 杨 on 16/12/27.
//  Copyright © 2016年 国平 杨. All rights reserved.
//

#import "ViewController.h"
#import "YGPLiveViewController.h"
#import "YGPRTMP.h"
#import "YGPRTMPCalss.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[YGPRTMPCalss shareRTMPClass]openWithURL:"rtmp://192.168.10.162:1935/rtmplive/home"];
    
}

- (IBAction)pushViewController:(id)sender {
    
    YGPLiveViewController *viewController = [[YGPLiveViewController alloc]init];
    
//    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:viewController];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
