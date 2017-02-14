//
//  YGPVideoConfigure.m
//  RTMPDemo
//
//  Created by 国平 杨 on 17/1/6.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import "YGPVideoConfigure.h"

@implementation YGPVideoConfigure

+ (instancetype)shareManager{

    static YGPVideoConfigure *videoConfigure = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        videoConfigure = [[YGPVideoConfigure alloc]init];
    });
    
    return videoConfigure;
}

- (instancetype)init{

    self = [super init];
    
    if (self) {
        
        self.fps = 25;
        self.bps = SCREEN_HEIGHT * 1024;
        self.bps_limit = self.bps * 2 / 8;
        self.gop = 25;
        
    }

    return self;
}

@end
