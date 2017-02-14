//
//  YGPAACEncoder.h
//  RTMPDemo
//
//  Created by 国平 杨 on 17/1/9.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YGPAACEncoder : NSObject

- (void)encoderPCMToAAC:(CMSampleBufferRef)sampleBuffef;
- (void)initAudioStreamBasicDescription;
- (void)endEncoder;

@end
