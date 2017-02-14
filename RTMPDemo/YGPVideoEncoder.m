//
//  YGPVideoEncoder.m
//  RTMPDemo
//
//  Created by 国平 杨 on 16/12/28.
//  Copyright © 2016年 国平 杨. All rights reserved.
//

#import "YGPVideoEncoder.h"

boolean_t CMPSampleBufferIsKeyframe(CMSampleBufferRef sampleBuffer){
    
    return !CFDictionaryContainsKey((CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
}

@interface YGPVideoEncoder ()
{
    VTCompressionSessionRef _encodingSession;
    NSInteger _frameCount;
}

@end

@implementation YGPVideoEncoder

+ (instancetype)encoderManager{
    
    static YGPVideoEncoder *encoder = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        encoder = [[YGPVideoEncoder alloc]init];
    });
    
    return encoder;
}


- (void)initVTCompressionSessionWithSize:(CGSize)size{
    
    //  flv metadata 用到
    [YGPVideoConfigure shareManager].width  = size.width;
    [YGPVideoConfigure shareManager].height = size.height;
    
    OSStatus status = VTCompressionSessionCreate(NULL, size.width, size.height, kCMVideoCodecType_H264, NULL, NULL, NULL, ygp_VTCompressionDidCallBack, (__bridge void *)(self), &_encodingSession);
    
    if (status != noErr) {
        
        NSLog(@"H264: Unable to create a H264 session");
        
    }else if (status == noErr){
        
        // 设置实时编码输出，降低编码延迟
        VTSessionSetProperty(_encodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        
        VTSessionSetProperty(_encodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        
        // bps 设置编码码率，不设置会很模糊
        VTSessionSetProperty(_encodingSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@([YGPVideoConfigure shareManager].bps));
        
        VTSessionSetProperty(_encodingSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@([YGPVideoConfigure shareManager].bps_limit), @1]);
        
        // 关键帧间隔
        VTSessionSetProperty(_encodingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@([YGPVideoConfigure shareManager].gop));
        
        // 设置帧率
        VTSessionSetProperty(_encodingSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@([YGPVideoConfigure shareManager].gop / 2));
        
         status = VTCompressionSessionPrepareToEncodeFrames(_encodingSession);
        
        if (status != noErr) {
            NSLog(@"VTCompressionSessionPrepareToEncodeFrames error");
        }
    }
}


void ygp_VTCompressionDidCallBack(void * CM_NULLABLE outputCallbackRefCon,
                                  void * CM_NULLABLE sourceFrameRefCon,
                                  OSStatus status,
                                  VTEncodeInfoFlags infoFlags,
                                  CM_NULLABLE CMSampleBufferRef sampleBuffer
                                  ){
    
    //编码是否成功
    if (status != noErr) {
        NSLog(@"status %d",status);
        NSLog(@"ygp_encoer error");
        return;
    }
    
    //不存在则代表压缩不成功或帧丢失
    if (!sampleBuffer) {
        NSLog(@"数据不完整");
        return;
    }
    
    BOOL isKeyframe = CMPSampleBufferIsKeyframe(sampleBuffer);
    
    // get sps pps
    if (isKeyframe) {
        
        size_t pps_size, pps_count;
        size_t sps_size, sps_count;
        
        const uint8_t *spsData,*ppsData;
        
        CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        OSStatus spsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 0, &spsData, &sps_size, &sps_count, 0 );
        
        OSStatus ppsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 1, &ppsData, &pps_size, &pps_count, 0 );
        
        
        if (spsStatus == noErr && ppsStatus == noErr) {
            
            [[YGPFLVStream flvStreamManager] converterH264ToFlvVideoData:sampleBuffer naluData:nil keyframe:YES];
            
        }
    }
    
    //获取编码后的数据
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t   blockDataLen;
    uint8_t *blockData;
    status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &blockDataLen, (char **)&blockData);
    
    size_t length = CMBlockBufferGetDataLength(blockBuffer);
    Byte buffer[length];
    CMBlockBufferCopyDataBytes(blockBuffer, 0, length, buffer);
    
    if (status == noErr) {
        
        size_t bufferOffset               = 0;
        static const int AVCCHeaderLength = 4;
        
        while (bufferOffset < blockDataLen - AVCCHeaderLength) {
            
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, blockData + bufferOffset, AVCCHeaderLength);
            
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData *naluData = [NSData dataWithBytes:blockData + bufferOffset + AVCCHeaderLength length:NALUnitLength];
            
            //封装 flv
            [[YGPFLVStream flvStreamManager] converterH264ToFlvVideoData:sampleBuffer naluData:naluData keyframe:NO];
            
            bufferOffset += AVCCHeaderLength + NALUnitLength;
            
        }
    }
    
};


- (void)encoderToH264:(CMSampleBufferRef)sampleBuffer{
    
    if (!_encodingSession) {
        return;
    }
    
    _frameCount ++;
    
    CVImageBufferRef imageBuf = CMSampleBufferGetImageBuffer(sampleBuffer);
        
    CMTime presentationTimeStamp = CMTimeMake(_frameCount, 1000);
    CMTime duration = kCMTimeInvalid;
    VTEncodeInfoFlags flags;
    OSStatus status = VTCompressionSessionEncodeFrame(_encodingSession, imageBuf, presentationTimeStamp, duration, NULL,NULL, &flags);
        
    if (status != noErr){
            
        NSLog(@"Encode error %d",status);
            
        [self endEncoder];
        
        return ;
    }
        
}

- (void)endEncoder{
    
    
    VTCompressionSessionCompleteFrames(_encodingSession, kCMTimeInvalid);
    
    VTCompressionSessionInvalidate(_encodingSession);
    
    CFRelease(_encodingSession);
    
    _encodingSession = NULL;
    
}

@end
