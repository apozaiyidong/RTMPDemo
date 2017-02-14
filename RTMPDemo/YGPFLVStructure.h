//
//  YGPFLVStructure.h
//  RTMPDemo
//
//  Created by 国平 杨 on 17/1/13.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint32_t, AVCPacketType){
    
    AVCPacketTypeAvcC = 0x00,
    AVCPacketTypeNalu = 0x01,
    
};

typedef NS_ENUM(uint32_t, FLVMediaType){
    
    FLVMediaTypeVideo  = 0x09,
    FLVMediaTypeAvc    = 0x08,
    FLVMediaTypeScript = 0x12,
    
};

@interface YGPFLVStructure : NSObject

+ (NSData *)FLV_header;
+ (NSData *)FLV_videoSpsPps:(NSData *)spsPpsData;
+ (NSData *)FLV_videoTagHeader:(NSInteger)length
                     timestamp:(uint32_t)timestamp;

+ (NSData *)FLV_videoTagData:(NSData *)data;
+ (NSData *)FLV_previousTagLength:(NSInteger)length;
+ (NSData *)FLV_End;

+ (NSData *)FLV_TagHeader:(NSInteger)length
                videoType:(FLVMediaType)videoType
                timestamp:(uint32_t)timestamp;

#pragma makr audio
+ (NSData *)FLV_audioSpecificConfig;

+ (NSData *)FLV_audioTagHeader:(NSInteger)length
                     timestamp:(uint32_t)timestamp;

+ (NSData *)FLV_audioTagData:(NSData *)data
                        type:(uint8_t)type;

@end
