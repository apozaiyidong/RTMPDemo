//
//  YGPRTMPCalss.m
//  RTMPDemo
//
//  Created by 国平 杨 on 17/2/10.
//  Copyright © 2017年 国平 杨. All rights reserved.
//

#import "YGPRTMPCalss.h"
#import "YGPFLVTagClass.h"
#import "YGPFLVMetadata.h"

@interface YGPRTMPCalss(){

    RTMP *_rtmp;
    BOOL _isSendMetadata;
    dispatch_queue_t _aRTMPSendQueue;
    dispatch_semaphore_t _aSendMedatadaLock;
    
}

@property (assign, nonatomic) BOOL isConnected;
@property (assign, nonatomic) BOOL isConnecting;

@property (assign, nonatomic) BOOL isSending;
@property (strong, nonatomic) NSMutableArray *buffers;

@end

@implementation YGPRTMPCalss

+ (instancetype)shareRTMPClass{

    static YGPRTMPCalss *_class = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _class = [[YGPRTMPCalss alloc]init];
        _class->_rtmp = RTMP_Alloc();
        RTMP_Init(_class->_rtmp);
    });
    
    return _class;
}

- (instancetype)init{

    self = [super init];

    if (self) {
        
        self.buffers = [[NSMutableArray alloc]init];
        _aRTMPSendQueue = dispatch_queue_create("com.ygp.sendrtmp", DISPATCH_QUEUE_SERIAL);
        _aSendMedatadaLock = dispatch_semaphore_create(1);
    }
    
    return self;
}

- (void)sendFLVTag:(YGPFLVTagClass *)videoFrame{

    if (!videoFrame) return;
    
    [self.buffers addObject:videoFrame];
    [self sendFLVTagData];
}


- (void)sendFLVTagData{
    
    dispatch_async(_aRTMPSendQueue, ^{
        
        if (!_isSendMetadata) {
            
            dispatch_semaphore_wait(_aSendMedatadaLock, DISPATCH_TIME_FOREVER);
            
            [self sendMetadata];
            
            dispatch_semaphore_signal(_aSendMedatadaLock);
        }
        
        if (!self.isSending && [self.buffers count] > 0) {
            self.isSending = YES;
            [self sendPacket:[self.buffers objectAtIndex:0]];
        }

    });
    
}


- (void)sendPacket:(YGPFLVTagClass *)videoFrame{

//    http://www.cnblogs.com/haibindev/archive/2011/12/29/2305712.html
//    https://my.oschina.net/jerikc/blog/501948
    
    unsigned char *boby =(unsigned char *)[videoFrame.boby bytes];
    
    RTMPPacket rtmp_packet;
    
    RTMPPacket_Reset(&rtmp_packet);
    RTMPPacket_Alloc(&rtmp_packet,(uint32_t)videoFrame.bobySize);
    
    rtmp_packet.m_nBodySize       = videoFrame.bobySize;
    rtmp_packet.m_hasAbsTimestamp = 0;
    rtmp_packet.m_packetType      = videoFrame.type;
    rtmp_packet.m_nInfoField2     = _rtmp->m_stream_id;
    rtmp_packet.m_nChannel        = 0x04;
    rtmp_packet.m_headerType      = RTMP_PACKET_SIZE_LARGE;
    rtmp_packet.m_nTimeStamp      = (uint32_t)videoFrame.timestamp;

    if (FLVMediaTypeAvc == videoFrame.type && videoFrame.bobySize !=4){
        rtmp_packet.m_headerType = RTMP_PACKET_SIZE_MEDIUM;
    }
    
    memcpy(rtmp_packet.m_body,boby,videoFrame.bobySize);

    [self _isSendPacket:rtmp_packet];

    RTMPPacket_Free(&rtmp_packet);

}

- (void)sendMetadata{

    NSData * metadata = [YGPFLVMetadata metadata];
    char *boby = (char *)[metadata bytes];
    
    RTMPPacket rtmp_packet;
    
    rtmp_packet.m_nChannel   = 0x03;
    rtmp_packet.m_headerType = RTMP_PACKET_SIZE_LARGE;
    rtmp_packet.m_packetType = RTMP_PACKET_TYPE_INFO;
    rtmp_packet.m_nTimeStamp = 0;
    rtmp_packet.m_nInfoField2 = _rtmp->m_stream_id;
    rtmp_packet.m_hasAbsTimestamp = TRUE;
    rtmp_packet.m_body = boby;
    rtmp_packet.m_nBodySize = (uint32_t)[metadata length];
    
    if (!RTMP_SendPacket(_rtmp, &rtmp_packet, 0)) {
        return;
    }

    _isSendMetadata = YES;
}

#pragma mark sending

- (void)_isSendPacket:(RTMPPacket)rtmp_packet{

    if (RTMP_IsConnected(_rtmp)) {
        
        int success = RTMP_SendPacket(_rtmp, &rtmp_packet, 0);
        
        if (success) {
            NSLog(@"发送成功");
        }else{
            NSLog(@"发送失败");
        }
    }
    
    [self.buffers removeObjectAtIndex:0];
    [self sendFLVTagData];
    
    self.isSending = NO;
    
}

#pragma mark connectRTMP

- (BOOL)openWithURL:(char *)rtmpUrl{
    
//    http://blog.csdn.net/leixiaohua1020/article/details/14229543
//    http://blog.csdn.net/leixiaohua1020/article/details/42105049
    
    if (self.isConnecting) {
        return NO;
    }
    
    if (RTMP_SetupURL(_rtmp, rtmpUrl) == FALSE) {
        
        NSLog(@"PILI_RTMP_SetupURL error ");
        return [self _rtmpConnectFailed];;
    }
    
    //推流模式
    RTMP_EnableWrite(_rtmp);
    
    //连接服务器
    if (RTMP_Connect(_rtmp, NULL) == FALSE) {
     
        NSLog(@"PILI_RTMP_Connect error");
        
        return [self _rtmpConnectFailed];;
    }

    //连接流
    if (RTMP_ConnectStream(_rtmp, 0) == FALSE) {
        
        NSLog(@"PILI_RTMP_ConnectStream error ");
        
        return [self _rtmpConnectFailed];
    }
    
    self.isConnected  = YES;
    self.isConnecting = YES;
    
    NSLog(@"连接成功");
    
    return YES;
}


- (BOOL)_rtmpConnectFailed{

    RTMP_Close(_rtmp);
    RTMP_Free(_rtmp);

    self.isConnected  = NO;
    self.isSending    = NO;
    self.isConnecting = NO;
    
    return NO;
}


- (void)disconnect{

    dispatch_async(_aRTMPSendQueue, ^{
        [self _disconnect];
        
    });
    
}

- (void)_disconnect{

    if (_rtmp) {
        
        RTMP_Close(_rtmp);
        RTMP_Free(_rtmp);
        
        _rtmp = NULL;
        
        self.isConnected  = NO;
        self.isSending    = NO;
        self.isConnecting = NO;
        
    }

}

@end
