//
//  YGPVideoConfigure.h
//  RTMPDemo
//
//  Created by 国平 杨 on 17/1/6.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface YGPVideoConfigure : NSObject

//Frames Per Second
@property (assign, nonatomic) NSInteger fps;

//Bit Per Second
@property (assign, nonatomic) NSInteger bps;
@property (assign, nonatomic) NSInteger bps_limit;

//关键帧间隔
@property (assign, nonatomic) NSInteger gop;

@property (assign, nonatomic) int width;
@property (assign, nonatomic) int height;

+ (instancetype)shareManager;

@end
