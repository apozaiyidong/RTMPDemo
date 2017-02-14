//
//  YGPSendDataClass.h
//  RTMPDemo
//
//  Created by 国平 杨 on 17/2/11.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YGPFLVTagClass : NSObject

@property (strong, nonatomic) NSData *boby;
@property (assign, nonatomic) uint64_t timestamp;
@property (assign, nonatomic) uint32_t bobySize;
@property (assign, nonatomic) unsigned int type;

- (void)setVideoTag:(NSData *)data
          timestamp:(NSInteger)timestamp;


- (void)setAuidoTag:(NSData *)data
          timestamp:(NSInteger)timestamp;
@end
