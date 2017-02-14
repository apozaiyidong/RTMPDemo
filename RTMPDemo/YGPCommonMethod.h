//
//  YGPCommonMethod.h
//  RTMPDemo
//
//  Created by 国平 杨 on 17/2/13.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NOW (CACurrentMediaTime()*1000)

@interface YGPCommonMethod : NSObject

+ (CGSize)getVideoSize:(NSString *)sessionPreset;

@end
