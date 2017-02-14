//
//  YGPVideoEncoder.h
//  RTMPDemo
//
//  Created by 国平 杨 on 16/12/28.
//  Copyright © 2016年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface YGPVideoEncoder : NSObject

+ (instancetype)encoderManager;
- (void)initVTCompressionSessionWithSize:(CGSize)size;
- (void)encoderToH264:(CMSampleBufferRef)sampleBuffer;
- (void)endEncoder;

@end
