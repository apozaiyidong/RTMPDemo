//
//  YGPAACEncoder.m
//  RTMPDemo
//
//  Created by 国平 杨 on 17/1/9.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import "YGPAACEncoder.h"

@interface YGPAACEncoder (){

    AudioConverterRef _audioConverter;
}

@property (assign, nonatomic) uint32_t audioMaxOutputFrameSize;
@property (strong, nonatomic) NSData  *pcmData;

@end

@implementation YGPAACEncoder


static OSStatus aacEncodeInInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData){
    
    YGPAACEncoder *aacEncoder = (__bridge YGPAACEncoder *)inUserData;
    if (aacEncoder.pcmData) {
        ioData->mBuffers[0].mData = (void *)aacEncoder.pcmData.bytes;
        ioData->mBuffers[0].mDataByteSize = (uint32_t)aacEncoder.pcmData.length;
        ioData->mNumberBuffers = 1;
        ioData->mBuffers[0].mNumberChannels = 1;
        
        return noErr;
    }
    
    return -1;
}


- (void)encoderPCMToAAC:(CMSampleBufferRef)sampleBuffef{
    
    self.pcmData = [self audioSampleBuffefToPcmData:sampleBuffef];
        
    AudioBufferList outAudioBufferList = {0};
    outAudioBufferList.mNumberBuffers  = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = 1;
    outAudioBufferList.mBuffers[0].mDataByteSize   = self.audioMaxOutputFrameSize;
    outAudioBufferList.mBuffers[0].mData = malloc(self.audioMaxOutputFrameSize);
    
    uint32_t outputDataPacketSize = 1;
    
    // AudioConverterFillComplexBuffer 编码
    
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, aacEncodeInInputDataProc, (__bridge void *)(self), &outputDataPacketSize, &outAudioBufferList, NULL);
    
        if (status != noErr) {
            NSLog(@"aac 编码失败");
        }else if (status == noErr){
            
            NSData *raw_avcData = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
    
            [[YGPFLVStream flvStreamManager]converterAVCToFlvAudioData:raw_avcData];
            
        }

}


- (NSData *)audioSampleBuffefToPcmData:(CMSampleBufferRef)sampleBuffer{
    
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    
    NSInteger blockBufferSize = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    
    Byte buffer[blockBufferSize];
    
    CMBlockBufferCopyDataBytes(blockBuffer, 0, blockBufferSize, buffer);
    
    return [[NSData dataWithBytes:&buffer length:blockBufferSize] copy];
}

//
- (void)initAudioStreamBasicDescription{

//    http://www.jianshu.com/p/8c7a616b30f1
//    http://www.eduve.org/knowledge/21
//    http://blog.csdn.net/wangruihit/article/details/47664695
    
    //输入
    AudioStreamBasicDescription inAudioStreamBasicDescription;
    
    inAudioStreamBasicDescription.mFormatID   = kAudioFormatLinearPCM;//格式
    inAudioStreamBasicDescription.mSampleRate = 44100;   //样率
    inAudioStreamBasicDescription.mBitsPerChannel = 16;  //采样长度
    inAudioStreamBasicDescription.mFramesPerPacket = 1;  //帧数
    inAudioStreamBasicDescription.mBytesPerFrame   = 2;
    inAudioStreamBasicDescription.mBytesPerPacket = 2;
    inAudioStreamBasicDescription.mChannelsPerFrame = 1;
    inAudioStreamBasicDescription.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsNonInterleaved;
    inAudioStreamBasicDescription.mReserved = 0;;
    
    //输出
    AudioStreamBasicDescription outAudioStreamBasicDescription = {
        .mSampleRate = inAudioStreamBasicDescription.mSampleRate,
        .mChannelsPerFrame = 1,
        .mFormatID = kAudioFormatMPEG4AAC,
        .mFramesPerPacket  = 1024,
        0
    };
    
    UInt32 size = sizeof(outAudioStreamBasicDescription);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &outAudioStreamBasicDescription);
    
    OSStatus status = AudioConverterNew(&inAudioStreamBasicDescription, &outAudioStreamBasicDescription, &_audioConverter);
    
    if(status != 0) {NSLog(@"setup converter failed: %d", (int)status);}
    
    
    //设置编码 bps
    uint32_t bps     = 64000;
    uint32_t bpsSize = sizeof(bps);
    status = AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, bpsSize, &bps);
    
    if (status != noErr) {
        NSLog(@"audio bps set error");
    }
    
    //查询最大输出
    uint32_t maxOutValue = 0;
    uint32_t maxOutValueSize = sizeof(maxOutValue);
    
    status = AudioConverterGetProperty(_audioConverter, kAudioConverterPropertyMaximumOutputPacketSize, &maxOutValueSize, &maxOutValue);
    
    self.audioMaxOutputFrameSize = maxOutValue;
    
    if (status !=noErr) {
        NSLog(@"audio 获取输出最大值失败");
    }

}


- (void)endEncoder{

    AudioConverterDispose(_audioConverter);
    _audioConverter = nil;
    self.pcmData = nil;
    self.audioMaxOutputFrameSize = 0;
    
}

@end
