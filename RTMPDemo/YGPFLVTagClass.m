//
//  YGPSendDataClass.m
//  RTMPDemo
//
//  Created by 国平 杨 on 17/2/11.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import "YGPFLVTagClass.h"

@implementation YGPFLVTagClass

- (void)setVideoTag:(NSData *)data
          timestamp:(NSInteger)timestamp{

    [self setObj:data type:FLVMediaTypeVideo timestamp:timestamp];
}


- (void)setAuidoTag:(NSData *)data
          timestamp:(NSInteger)timestamp{

    [self setObj:data type:FLVMediaTypeAvc timestamp:timestamp];

}

- (void)setObj:(NSData *)data
          type:(FLVMediaType)type
     timestamp:(NSInteger)timestamp{

    self.boby      = data;
    self.type      = type;
    self.bobySize  = (uint32_t)[data length];
    self.timestamp = timestamp;
    
}

@end
