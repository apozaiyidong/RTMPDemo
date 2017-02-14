//
//  YGPFLVStream.m
//  RTMPDemo
//
//  Created by 国平 杨 on 17/1/6.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import "YGPFLVStream.h"
#import "YGPFLVMetadata.h"

#define __WEAK_SELF __weak typeof(self) weakSelf = self;
#define __STRONG_SELF   __strong typeof(weakSelf) strongSelf = weakSelf;

extern NSData *FLV_SpsPpsCData(CMSampleBufferRef sampleBuffer,Boolean isKeyframe){
    
    if (!isKeyframe) {
        return  nil;
    }
    
    CMFormatDescriptionRef sampleBufFormat = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    NSDictionary *dict = (__bridge NSDictionary *)CMFormatDescriptionGetExtensions(sampleBufFormat);
    
    return dict[@"SampleDescriptionExtensionAtoms"][@"avcC"];
}

extern uint32_t FLV_videoCodec(BOOL isKeyframe){
    
    return isKeyframe == YES ? 0x17 : 0x27;
}

@interface YGPFLVStream (){
    
    __block NSData *_flvHeaderData;
    BOOL    _isKeyframe;
    NSData *_naluData;
    CMSampleBufferRef _sampleBuffer;
    dispatch_queue_t  _aQueue;
//    __block uint32_t  _timestamp;
    NSData *_startData;
    uint64_t _audioTimestamp;
    NSData *_spsPpsData;
    dispatch_semaphore_t _semapgore;
    NSData *_audioSpecific;
    dispatch_semaphore_t _audioSemapgore;
    uint64_t _relativeTimestamps;
    dispatch_semaphore_t _timestampsLock;
}

@end

@implementation YGPFLVStream

+ (instancetype)flvStreamManager{
    
    static YGPFLVStream *flvStream = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        flvStream = [[YGPFLVStream alloc]init];
    });
    
    return flvStream;
}


- (instancetype)init{
    
    self = [super init];
    
    if (self) {
        
//        _timestamp      = 0;
        _audioTimestamp = 0;
        _relativeTimestamps = 0;
        
        _aQueue = dispatch_queue_create([NSStringFromClass(self.class) UTF8String], DISPATCH_QUEUE_SERIAL);
        _timestampsLock = dispatch_semaphore_create(1);
        _semapgore = dispatch_semaphore_create(1);
        _audioSemapgore = dispatch_semaphore_create(1);
        _flvHeaderData = nil;
    }
    
    return self;
}

#pragma mark video

//封装 flv
- (void)converterH264ToFlvVideoData:(CMSampleBufferRef)sampleBuffer
                           naluData:(NSData *)naluData
                           keyframe:(BOOL)keyframe 
{
    
    _isKeyframe   = keyframe;
    _sampleBuffer = sampleBuffer;
    _naluData     = naluData;
    
    if (keyframe) {
        
        // sps pps
        if (!_spsPpsData) {
            _spsPpsData = FLV_SpsPpsCData(_sampleBuffer, _isKeyframe);
        }

        NSData *aacC = [YGPFLVStructure FLV_videoSpsPps:_spsPpsData];
        
        [self _videoFrame:aacC isKeyframe:YES];
        
    }else{
        
        //nalu
        NSData *nalu = [YGPFLVStructure FLV_videoTagData:_naluData];

        [self _videoFrame:nalu isKeyframe:NO];
    }
    
}

#pragma mark audio

- (void)converterAVCToFlvAudioData:(NSData *)raw_avcData{
    
    NSMutableData * tagData = [[NSMutableData alloc]init];
    
    YGPFLVTagClass *flvTagDataClass = [[YGPFLVTagClass alloc]init];

    if (!_audioSpecific) {
        
        _audioSpecific = tagData;
        
        [flvTagDataClass setAuidoTag:[YGPFLVStructure FLV_audioSpecificConfig]
                           timestamp:0];
        
        [[YGPRTMPCalss shareRTMPClass]sendFLVTag:flvTagDataClass];
    }
    
    [flvTagDataClass setAuidoTag:[YGPFLVStructure FLV_audioTagData:raw_avcData type:0x01] timestamp:[self _currentTimestamp]];
    
    [[YGPRTMPCalss shareRTMPClass]sendFLVTag:flvTagDataClass];

}

#pragma mark private method

//相对时间戳

- (uint32_t)_currentTimestamp{
    
    //  return  timestamps += 40;
    
    dispatch_semaphore_wait(_timestampsLock, DISPATCH_TIME_FOREVER);
    
    uint32_t current=0;
    if(_relativeTimestamps == 0){
        _relativeTimestamps = NOW;
    }else{
        current = NOW - _relativeTimestamps;
    }
    
    dispatch_semaphore_signal(_timestampsLock);
    
    return current;
}


- (void)_videoFrame:(NSData *)data
         isKeyframe:(BOOL)isKeyframe{
    
    YGPFLVTagClass *flvTagDataClass = [[YGPFLVTagClass alloc]init];
    
    if (isKeyframe) {
        [flvTagDataClass setVideoTag:data timestamp:0];
    }else{
        [flvTagDataClass setVideoTag:data timestamp:[self _currentTimestamp]];
    }
    
    [[YGPRTMPCalss shareRTMPClass]sendFLVTag:flvTagDataClass];
    
}

@end
