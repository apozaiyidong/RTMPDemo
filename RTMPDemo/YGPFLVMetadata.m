//
//  YGPAMFSerialize.m
//  RTMPDemo
//
//  Created by 国平 杨 on 17/1/13.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import "YGPFLVMetadata.h"

static inline NSData *AMF_NumberValue(NSNumber *numberValue){
    
    double doubleValue = numberValue.doubleValue;
    
    uint64_t doubleValue64 = *(uint64_t *) &doubleValue;
    
    const uint64_t integerValue = OSSwapBigToHostInt64(doubleValue64);
    
    return [NSData dataWithBytes:&integerValue length:sizeof(integerValue)];
    
}

static inline NSData *AMF_BoolValue(NSNumber *numberValue){

   uint8_t value = numberValue.boolValue ? 0x01 : 0x00;
    
   return [NSData dataWithBytes:&value length:sizeof(value)];
    
}

static inline NSData *AMF_onMetadataValue(NSString *key,
                                          NSNumber *numberValue,
                                          BOOL isBoolValue){
    
    NSMutableData *metadata = [[NSMutableData alloc]init];
    
    uint16_t keyLength = OSSwapBigToHostInt16([key length]);// 元素名称长度
    
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding]; //元素名
    
    const uint8_t type = 0x00;//类型
    
    [metadata appendBytes:&keyLength length:sizeof(keyLength)];
    [metadata appendData:keyData];
    [metadata appendBytes:&type      length:sizeof(type)];
    
    if (isBoolValue) {
        [metadata appendData:AMF_BoolValue(numberValue)];
    }else{
        [metadata appendData:AMF_NumberValue(numberValue)];
    }
    
    return metadata;
}

@implementation YGPFLVMetadata

+ (NSData *)onMetadata{

    NSMutableData *onMetadata = [[NSMutableData alloc]init];
    
    int i_width  = [YGPVideoConfigure shareManager].width;
    int i_height = [YGPVideoConfigure shareManager].height;
    
    NSNumber *width  = [NSNumber numberWithInt:i_width];
    NSNumber *height = [NSNumber numberWithInt:i_height];
    NSNumber *bps    = [NSNumber numberWithInteger:[YGPVideoConfigure shareManager].bps];
    NSNumber *framerate = [NSNumber numberWithInteger:[YGPVideoConfigure shareManager].gop / 2];

    [onMetadata appendData:AMF_onMetadataValue(@"duration", @0, NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"filesize", @0, NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"width", width, NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"height",height, NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"videocodecid", @(7), NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"framerate", framerate, NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"videodatarate", bps, NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"audiocodecid", @10, NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"audiosamplerate", @(44100), NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"audiodatarate", @(32000), NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"audiosamplesize", @(16), NO)];
    [onMetadata appendData:AMF_onMetadataValue(@"stereo", @YES, YES)];

    return onMetadata;
}

+ (NSData *)metadata{

    NSMutableData *afmData = [[NSMutableData alloc]init];
    
    //amf 0
    uint8_t  amf0Type     = 0x02;
    uint16_t stringLength = OSSwapBigToHostInt16([@"onMetadata" length]);
    
    [afmData appendBytes:&amf0Type     length:sizeof(amf0Type)];
    [afmData appendBytes:&stringLength length:sizeof(stringLength)];
    [afmData appendData:[@"onMetadata" dataUsingEncoding:NSUTF8StringEncoding]];
    
    //amf1
    uint8_t amf1Type     = 0x08; //0x08 array
    const uint32_t count = OSSwapBigToHostInt32(12);
    
    [afmData appendBytes:&amf1Type length:sizeof(amf1Type)];
    [afmData appendBytes:&count    length:sizeof(count)];
    
    //value
    [afmData appendData:[YGPFLVMetadata onMetadata]];
    
    //end
    uint32_t end = OSSwapBigToHostInt32(0x09);
    //    const uint8_t end[3] = {0x00, 0x00, 0x09};
    [afmData appendBytes:&end length:sizeof(sizeof(end))];
    
    return afmData;
    
}

@end
