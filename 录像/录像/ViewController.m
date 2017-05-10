//
//  ViewController.m
//  录像
//
//  Created by Qianrun on 16/5/30.
//  Copyright © 2016年 Qianrun. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define WEAKSELF(weakSelf) __weak __typeof(&*self)weakSelf = self

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

#pragma mark -Delegate
//- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    
//    NSLog(@"...:开始捕捉");
//}
//
//- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
//{
//    NSLog(@"....已经捕捉视频");
//    
//    
//}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"...:开始捕捉");    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"....已经捕捉视频");    
}



#pragma mark -EventMethod
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self test];
}

- (void)test {
    
    // 1. 创建session
    AVCaptureSession *captureSession = [[AVCaptureSession alloc]init];
    
    // 2. 创建一个AVCaptureDevice代表代表输入设备。在这里我们制定设备用于摄像。
//    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    // 3. 创建AVCaptureDeviceInput,并添加到Session中。我们需要使用AVCaptureDeviceInput来让设备添加到session中, AVCaptureDeviceInput负责管理设备端口。我们可以理解它为设备的抽象。一个设备可能可以同时提供视频和音频的捕捉。我们可以分别用AVCaptureDeviceInput来代表视频输入和音频输入。
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (error) {
        NSLog(@"error:%@", error);
    }
    
    [captureSession addInput:input];
    
    // 4. 创建AVCaptureOutput,为了从session中取得数据,我们需要创建一个AVCaptureOutput
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    
    // 5. 设置output delegate,将output添加至session,在代理方法中分析视频流,为了分析视频流,我们需要为output设置delegate,并且指定delegate方法在哪个线程被调用。需要主要的是,线程必须是串行的,确保视频帧按序到达。
    
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    [captureSession addOutput:videoDataOutput];
    
    // 6. 开始捕捉视频
    [captureSession startRunning];
    
}


@end