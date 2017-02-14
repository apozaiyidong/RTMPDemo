//
//  YGPFLVStream.h
//  RTMPDemo
//
//  Created by 国平 杨 on 17/1/6.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YGPFLVStream : NSObject

@property (strong, nonatomic)NSMutableData *flvData;


+ (instancetype)flvStreamManager;

- (void)flvHeaderInformation:(CMSampleBufferRef)sampleBuffer;
- (void)converterH264ToFlvVideoData:(CMSampleBufferRef)sampleBuffer
                           naluData:(NSData *)naluData
                           keyframe:(BOOL)keyframe;

- (void)converterAVCToFlvAudioData:(NSData *)avcData;

- (void)flvStart;

@end
