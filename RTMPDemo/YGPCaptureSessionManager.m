//
//  YGPCaptureSessionManager.m
//  RTMPDemo
//
//  Created by 国平 杨 on 16/12/27.
//  Copyright © 2016年 国平 杨. All rights reserved.
//

#import "YGPCaptureSessionManager.h"
#import "YGPVideoEncoder.h"

@interface YGPCaptureSessionManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>{
    
    UIView          *_videoPreview;
    YGPVideoEncoder *_encoderManager;
    YGPAACEncoder   *_aacEncoder;
    
    dispatch_queue_t _aVideoQueue;
    dispatch_queue_t _aAudioQueue;
}

@end

@implementation YGPCaptureSessionManager

- (instancetype)init{
    
    self = [super init];
    
    if (self) {
        
        NSString * videoQueueName = [NSString stringWithFormat:@"video_%@",NSStringFromClass(self.class)];
        _aVideoQueue = dispatch_queue_create([videoQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
        
        NSString * audioQueueName = [NSString stringWithFormat:@"audio_%@",NSStringFromClass(self.class)];
        _aAudioQueue = dispatch_queue_create([audioQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
        
    }
    
    return self;
}

- (void)configurePreviewWithSuperView:(UIView *)superView{
    
    _videoPreview = superView;
    
    [self _configureSession];
    
    [self _configurePreView];
    
    [self switchCameraWithIsBackCamera:YES];
    
    [self _configuseAudioInput];
    
    [self _configureOutputData];
    
    [self.session startRunning];
    
}

- (void)_configureSession{
    
    self.session = [[AVCaptureSession alloc]init];
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    
    _encoderManager = [[YGPVideoEncoder alloc]init];
    _aacEncoder     = [[YGPAACEncoder   alloc]init];
    
    [_aacEncoder initAudioStreamBasicDescription];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_encoderManager initVTCompressionSessionWithSize:[YGPCommonMethod getVideoSize:_session.sessionPreset]];
        
    });
    
    
}

- (void)_configurePreView{
    
    AVCaptureVideoPreviewLayer *preViewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_session];
    
    preViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preViewLayer.frame        = _videoPreview.frame;
    self.previewLayer         = preViewLayer;
    [_videoPreview.layer addSublayer:self.previewLayer];
    
}

- (void)_configureOutputData{
    
    self.outputVideoData = [[AVCaptureVideoDataOutput alloc]init];
    
    
    self.outputVideoData.videoSettings = [NSDictionary dictionaryWithObject:
                                          [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    [self.outputVideoData setAlwaysDiscardsLateVideoFrames:YES];
    
    if ([self.session canAddOutput:_outputVideoData]) {
        [self.session addOutput:self.outputVideoData];
    }
    
    // 设置采集图像的方向,如果不设置，采集回来的图形会是旋转90度的
    AVCaptureConnection *connection = [self.outputVideoData connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    [self.outputVideoData setSampleBufferDelegate:self queue:_aVideoQueue];
    
    
    // 音频
    self.outputAudioData = [[AVCaptureAudioDataOutput alloc]init];
    [self.outputAudioData setSampleBufferDelegate:self queue:_aAudioQueue];
    
    if ([self.session canAddOutput:_outputAudioData]) {
        [self.session addOutput:self.outputAudioData];
    }
    
    
}

- (void)_configuseAudioInput{
    
    //麦克风
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    self.inputAudioDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    if ([self.session canAddInput:_inputAudioDevice]) {
        [self.session addInput:_inputAudioDevice];
    }
    
}

#pragma mark camera

// 获取前（后）摄像头
- (void)switchCameraWithIsBackCamera:(BOOL)isBackCamera{
    
    AVCaptureDeviceInput *deviceInput = nil;
    
    if (isBackCamera) {
        deviceInput = [self backCamera];
    }else{
        deviceInput = [self frontCamera];
    }
    
    [self.session beginConfiguration];
    
    [self.session removeInput:_inputVideoDevice];
    
    if (deviceInput) {
        [self.session addInput:deviceInput];
        self.inputVideoDevice = deviceInput;
    }
    
    [self.session commitConfiguration];
}

// 获取前（后）相机 输入流
- (AVCaptureDeviceInput *)cameraWithPosition:(AVCaptureDevicePosition) position{
    
    NSArray *devices = [AVCaptureDevice devices];
    
    AVCaptureDevice *selectDevice = nil;
    
    for (AVCaptureDevice *device in devices) {
        
        if ([device position] == position) {
            NSLog(@"device %@",device);
            selectDevice = device;
        }
    }
    
    NSError *error = nil;
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectDevice error:&error];
    
    if (!error) {
        //添加输入流
        if ([_session canAddInput:deviceInput]) {
            return deviceInput;
        }
        
    }
    
    return nil;
}


- (AVCaptureDeviceInput *)frontCamera{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}


- (AVCaptureDeviceInput *)backCamera{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}


#pragma makr AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (self.isSendRTMP) {
        if ([captureOutput isEqual:self.outputAudioData]) {
            [_aacEncoder encoderPCMToAAC:sampleBuffer];
        }else if ([captureOutput isEqual:self.outputVideoData]){
            [_encoderManager encoderToH264:sampleBuffer];
        }
    }
}

- (void)end{
    
//    [self.session stopRunning];
    self.isSendRTMP = NO;
    [_encoderManager endEncoder];
    [_aacEncoder endEncoder];
    
}

#pragma mark

@end
