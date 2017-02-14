//
//  YGPCaptureSessionManager.h
//  RTMPDemo
//
//  Created by 国平 杨 on 16/12/27.
//  Copyright © 2016年 国平 杨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
//#import <AudioUnit/AudioUnit.h>

@interface YGPCaptureSessionManager : NSObject

@property (strong, nonatomic) AVCaptureSession           *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

//video
@property (strong, nonatomic) AVCaptureDeviceInput       *inputVideoDevice;
@property (strong, nonatomic) AVCaptureVideoDataOutput   *outputVideoData;

//audio
@property (strong, nonatomic) AVCaptureAudioDataOutput   *outputAudioData;
@property (strong, nonatomic) AVCaptureDeviceInput       *inputAudioDevice;

@property (assign, nonatomic) BOOL isSendRTMP;

- (void)configurePreviewWithSuperView:(UIView *)superView;
- (void)end;

@end
