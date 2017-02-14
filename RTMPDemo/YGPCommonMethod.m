//
//  YGPCommonMethod.m
//  RTMPDemo
//
//  Created by 国平 杨 on 17/2/13.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import "YGPCommonMethod.h"

@implementation YGPCommonMethod

+ (CGSize)getVideoSize:(NSString *)sessionPreset {
    
    CGSize size = CGSizeZero;
    
    if ([sessionPreset isEqualToString:AVCaptureSessionPresetMedium]) {
        size = CGSizeMake(480, 360);
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        size = CGSizeMake(1920, 1080);
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        size = CGSizeMake(1280, 720);
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        size = CGSizeMake(640, 480);
    }
    
    
    return size;
}

@end
