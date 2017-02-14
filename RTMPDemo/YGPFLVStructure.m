//
//  YGPFLVStructure.m
//  RTMPDemo
//
//  Created by 国平 杨 on 17/1/13.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import "YGPFLVStructure.h"
#define OSSwapBigToHostInt24(x) ((((x) & 0xff0000) >> 16) | ((x) & 0x00ff00) | (((x) & 0x0000ff) << 16))
#define OSSwapHostToBigInt24(x) ((((x) & 0xff0000) >> 16) | ((x) & 0x00ff00) | (((x) & 0x0000ff) << 16))

#pragma mark FLVHeader
typedef struct FLVHeader {
    unsigned signature : 24; //文件类型： 通常 FVL
    unsigned version : 8;    //版本信息：0x01
    unsigned flags : 8;
    unsigned length : 32;
} __attribute__((packed)) FLVHeader;

#pragma mark AVCHeader

typedef struct AVCHeader {
    unsigned videoCodec : 8;
    unsigned nalu : 8;       // AVCPacket type
    unsigned time : 24;
} __attribute__((packed)) AVCHeader;

static inline AVCHeader AVCHeaderMake(uint32_t videoCodec,uint32_t packet){
    
    AVCHeader avcHeader;
    avcHeader.videoCodec = videoCodec;
    avcHeader.nalu       = packet;
    avcHeader.time       = 0;
    
    return avcHeader;
}

#pragma mark FLVTag

typedef struct FLVTag {
    unsigned type : 8;   // 0x09 表示视频 0x08 音频
    unsigned length : 24;
    unsigned timestamp : 24; //时间戳
    unsigned timestampExtended : 8;
    unsigned stream : 24;        // Always 0.
    char data[0];
} __attribute((packed)) FLVTag;


static inline FLVTag FLVTagMake(uint8_t type, uint32_t length, uint32_t timestamp, uint32_t stream)
{
    FLVTag tag;
    tag.type      = type;
    tag.length    = (uint32_t)OSSwapHostToBigInt24(length);
    tag.timestamp = (uint32_t)OSSwapHostToBigInt24(timestamp);
    tag.timestampExtended = (timestamp >> 24) & 0x7f;
    tag.stream    = OSSwapHostToLittleInt32(stream);
    
    return tag;
}

#pragma mark FLVPreviousTag

typedef struct FLVPreviousTag {
    unsigned length : 32;
} __attribute((packed)) FLVPreviousTag;


static inline FLVPreviousTag FLVPreviousTagMake(uint32_t length)
{
    FLVPreviousTag previousTag;
    previousTag.length = OSSwapHostToBigInt32(length);
    return previousTag;
}

#pragma makr audio

typedef struct FLVAudioHeader {
    
    //    unsigned audioCodec;       //编码格式
    //    unsigned sampleRate;       //采样率
    //    unsigned bitsPerChannel;   //采样长度 （大小）
    //    unsigned channelsPerFrame; //声道
    //    unsigned type;
    
    unsigned audioHeader : 8;
    unsigned type : 8;
    
    
}__attribute__((packed))FLVAudioHeader;

static NSData *FLVAudioHeaderMake(uint8_t type){

    FLVAudioHeader flvAudioHeader;
    flvAudioHeader.audioHeader = 0xAF;
    flvAudioHeader.type  = type;

    return [NSData dataWithBytes:&flvAudioHeader length:sizeof(flvAudioHeader)];
    
}

@interface YGPFLVStructure()

@end

@implementation YGPFLVStructure

+ (NSData *)FLV_header{

    NSMutableData *flvHeader = [[NSMutableData alloc]init];
    
    FLVHeader header;
    header.signature = OSSwapHostToBigInt24(' FLV');
    header.version   = 1;
    header.flags     = 1|4;
    header.length    = OSSwapHostToBigInt32(sizeof(header));
    
    [flvHeader appendData:[NSData dataWithBytes:&header length:sizeof(header)]];
    
    return flvHeader;
}

+ (NSData *)FLV_videoSpsPps:(NSData *)spsPpsData{

    NSMutableData *tag_data = [[NSMutableData alloc]init];

    //header
    AVCHeader avcHeader;
    avcHeader.videoCodec = 0x17;
    avcHeader.nalu       = 0x00;
    avcHeader.time       = 0;
    
    [tag_data appendBytes:&avcHeader length:sizeof(avcHeader)];
    [tag_data appendData:spsPpsData];
    
    return tag_data;
}

+ (NSData *)FLV_TagHeader:(NSInteger)length
                     videoType:(FLVMediaType)videoType
                     timestamp:(uint32_t)timestamp{
    
    FLVTag tag = FLVTagMake(videoType,(uint32_t)length, timestamp, 0);
    
    return [NSData dataWithBytes:&tag length:sizeof(tag)];
    
}

+ (NSData *)FLV_videoTagHeader:(NSInteger)length
                     timestamp:(uint32_t)timestamp{

    FLVTag tag = FLVTagMake(FLVMediaTypeVideo,(uint32_t)length, timestamp, 0);
    
    return [NSData dataWithBytes:&tag length:sizeof(tag)];
    
}

+ (NSData *)FLV_videoTagData:(NSData *)data{

    // big to li
    uint32_t naluLength = (uint32_t)data.length;
    uint8_t naluLenArr[4] = {naluLength >> 24 & 0xff, naluLength >> 16 & 0xff, naluLength >> 8 & 0xff, naluLength & 0xff};
    
    NSMutableData *naluData = [NSMutableData dataWithBytes:naluLenArr length:4];
    [naluData appendData:data];
    
    NSMutableData *tagData = [[NSMutableData alloc]init];
    
    //header
    AVCHeader avcHeader;
    avcHeader.videoCodec = 0x27;
    avcHeader.nalu       = 0x01;
    avcHeader.time       = 0;
    
    [tagData appendBytes:&avcHeader length:sizeof(avcHeader)];
    [tagData appendData:naluData];
    
    return tagData;
    
}

+ (NSData *)FLV_previousTagLength:(NSInteger)length{

    FLVPreviousTag previousTag = FLVPreviousTagMake((uint32_t)length);
    
    return [NSData dataWithBytes:&previousTag length:sizeof(previousTag)];
    
}

+ (NSData *)FLV_End{

    NSMutableData *flv_data = [[NSMutableData alloc]init];

    unsigned char end[] = {
        0x17,
        0x02,
        0x00, 0x00, 0x00,
    };

    [flv_data appendData:[YGPFLVStructure FLV_videoTagHeader:5 timestamp:0]];
    [flv_data appendBytes:&end length:sizeof(end)];
    
    return flv_data;
}

#pragma mark audio
+ (NSData *)FLV_audioSpecificConfig{

    NSMutableData *data = [[NSMutableData alloc]init];
    
    uint8_t profile = kMPEG4Object_AAC_LC;
    uint8_t sampleRate = 4;
    uint8_t chanCfg = 1;
    uint8_t config1 = (profile << 3) | ((sampleRate & 0xe) >> 1);
    uint8_t config2 = ((sampleRate & 0x1) << 7) | (chanCfg << 3);

    uint8_t af = 0xAF;
    uint8_t type = 0x00;
    
    [data appendBytes:&af length:sizeof(af)];
    [data appendBytes:&type length:sizeof(type)];

    [data appendBytes:&config1 length:sizeof(config1)];
    [data appendBytes:&config2 length:sizeof(config2)];
    
    return data;
}

+ (NSData *)FLV_audioTagHeader:(NSInteger)length
                     timestamp:(uint32_t)timestamp{
    
    FLVTag tag = FLVTagMake(FLVMediaTypeAvc,(uint32_t)length, timestamp, 0);
    
    return [NSData dataWithBytes:&tag length:sizeof(tag)];
    
}

+ (NSData *)_FLV_audioTagDataHeader:(uint8_t )type{

    return FLVAudioHeaderMake(type);
}

+ (NSData *)FLV_audioTagData:(NSData *)data
                        type:(uint8_t)type{
    
    NSMutableData *tagData = [[NSMutableData alloc]init];
    
    [tagData appendData:FLVAudioHeaderMake(type)];

    [tagData appendData:data];
        
    return tagData;
}

@end
