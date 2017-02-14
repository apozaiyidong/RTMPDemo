//
//  YGPRTMPCalss.h
//  RTMPDemo
//
//  Created by 国平 杨 on 17/2/10.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YGPFLVTagClass.h"

@interface YGPRTMPCalss : NSObject

@property (copy, nonatomic) NSData *metadata;

+ (instancetype)shareRTMPClass;

- (BOOL)openWithURL:(char *)rtmpUrl;

- (void)sendFLVTag:(YGPFLVTagClass *)videoFrame;

- (void)disconnect;

@end
