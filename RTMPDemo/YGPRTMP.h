//
//  YGPRTMP.h
//  RTMPDemo
//
//  Created by 国平 杨 on 16/12/29.
//  Copyright © 2016年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YGPRTMP : NSObject

- (void)sendVideo:(NSData *)data;
- (void)conn;

@end
