//
//  YGPRTMP.m
//  RTMPDemo
//
//  Created by 国平 杨 on 16/12/29.
//  Copyright © 2016年 国平 杨. All rights reserved.
//

#import "YGPRTMP.h"

@interface YGPRTMP ()<NSStreamDelegate>{

    NSInputStream  *_inputStream;
    NSOutputStream *_outputStream;
}

@end

@implementation YGPRTMP

- (instancetype)init{

    self = [super init];
    
    if (self) {
        
    
    }

    return self;
}

- (void)conn{
    
//http://localhost:8080/
    NSString *host = @"192.168.30.53";
    
    int prot       = 1935;
    
    //定义输入输出流
    CFReadStreamRef  readStream;
    CFWriteStreamRef writeStream;
    
    //socket 请求链接
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(host), prot, &readStream, &writeStream);
    
    //转换 oc 语言输入流
    _inputStream  = (__bridge NSInputStream *)(readStream);
    _outputStream = (__bridge NSOutputStream*)(writeStream);
    
    _inputStream.delegate  = self;
    _outputStream.delegate = self;
    
    // 不添加主运行循环 代理有可能不工作
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_inputStream  open];
    [_outputStream open];
    

}

- (void)sendVideo:(NSData *)data{

     [_outputStream write:data.bytes maxLength:data.length];
    
}

- (void)reData{
    
//    //建立数据缓存区
//    uint8_t buf[1024];
//    
//    //返回实际装载的字节数
//    NSInteger len = [_inputStream read:buf maxLength:sizeof(buf)];
//    
//    //字节数组转化成字符串
//    NSData *data = [NSData dataWithBytes:buf length:len];
//    //    NSString *reData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    //    NSLog(@"reData %@",reData);
//    
////    NSLog(@"1111    %@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]);
////    [data writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/audio.aac"] atomically:YES];
//    
//    NSLog(@"data %@",data);
//    
//    //获取服务器接收到的数据
//        NSString *reData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"reData %@",reData);
    //    _readCOntent.text = reData;
    
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    
    
    NSLog(@"eventCode %@",@(eventCode));
    //    NSStreamEventOpenCompleted = 1UL << 0,//输入输出流打开完成
    //    NSStreamEventHasBytesAvailable = 1UL << 1,//有字节可读
    //    NSStreamEventHasSpaceAvailable = 1UL << 2,//可以发放字节
    //    NSStreamEventErrorOccurred = 1UL << 3,// 连接出现错误
    //    NSStreamEventEndEncountered = 1UL << 4// 连接结束
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            NSLog(@"输入输出流打开完成");
            break;
        case NSStreamEventHasBytesAvailable:
            NSLog(@"有字节可读");
            [self reData];
            //                         [self readData];
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"可以发送字节");
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@" 连接出现错误");
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"连接结束");
            
            // 关闭输入输出流
            [_inputStream close];
            [_outputStream close];
            
            // 从主运行循环移除
            [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            break;
        default:
            break;
    }
}

@end
