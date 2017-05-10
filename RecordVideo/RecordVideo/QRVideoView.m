//
//  QRAnotherView.m
//  视频录制封装
//
//  Created by Qianrun on 16/6/1.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "QRVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

//recordBtn
#define TIMER_INTERVAL 0.05
//#define VIDEO_FOLDER @"videoFolder"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface QRVideoView ()<AVCaptureFileOutputRecordingDelegate>

@property (strong,nonatomic) AVCaptureSession *captureSession;//负责输入和输出设置之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层

@property (strong,nonatomic)  UIView *viewContainer;//视频容器
@property (strong,nonatomic)  UIImageView *focusCursor; //聚焦光标

//@property float totalTime; //视频总长度 默认10秒
@property (nonatomic, assign) float totalTime; //视频总长度 默认10秒

@end

@implementation QRVideoView {
    
    NSMutableArray* urlArray;//保存视频片段的数组
    
    float currentTime; //当前视频长度
    
    NSTimer *countTimer; //计时器
    UIView* progressPreView; //进度条
    float progressStep; //进度条每次变长的最小单位
    
    float preLayerWidth;//镜头宽
    float preLayerHeight;//镜头高
    float preLayerHWRate; //高，宽比
    
    UIView* btView; //
    UIButton* recordBtn;//录制按钮
//    UIButton* finishBt;//结束按钮
    
    UIButton* flashBt;//闪光灯
    UIButton* cameraBt;//切换摄像头
    
    float QR_SCREENWIDTH;
    float QR_SCREENHEIGHT;
}

- (id)initWithFrame:(CGRect)frame totalTime:(float)totalTime videoDirectoryPath:(NSString *)videoDirectoryPath {
    
    
    if (self = [super initWithFrame:frame]) {
        
        QR_SCREENWIDTH = CGRectGetWidth(frame);
        QR_SCREENHEIGHT = CGRectGetHeight(frame);
        
        self.backgroundColor = UIColorFromRGB(0x1d1e20);
        
        //视频最大时长 默认10秒
        self.totalTime = totalTime;

        if (self.totalTime==0) {
            self.totalTime =10;
        }
        
        // videoDirectoryPath
        _videoDirectoryPath = videoDirectoryPath;
        
        urlArray = [[NSMutableArray alloc]init];
        
        preLayerWidth = QR_SCREENWIDTH;
        preLayerHeight = QR_SCREENHEIGHT - 110;
        preLayerHWRate = preLayerHeight/preLayerWidth;
        
        progressStep = QR_SCREENWIDTH*TIMER_INTERVAL/totalTime;
        
//        [self createVideoFolderIfNotExist];
        // 判断是否存在videoDirectoryPath这个文件夹
        if (videoDirectoryPath && [self isPathExit:videoDirectoryPath]) {
            
            _videoDirectoryPath = videoDirectoryPath;
            
        } else { // 如果不存在视频的默认存储位置为document下
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *path = [paths objectAtIndex:0];
            _videoDirectoryPath = path;
        }
        
        //
        [self initCapture];
        
        NSLog(@"self.bounds:%@", NSStringFromCGRect(self.bounds));
    }
    
    [self.captureSession startRunning];
    return self;
}

-(void)initCapture{
    
    //视频高度加进度条（10）高度
    self.viewContainer = [[UIView alloc]initWithFrame:CGRectMake(0, 0, preLayerWidth, preLayerHeight+10)];
    [self addSubview:self.viewContainer];
    
    self.focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 50, 50)];
    [self.focusCursor setImage:[UIImage imageNamed:@"focusImg"]];
    self.focusCursor.alpha = 0;
    [self.viewContainer addSubview:self.focusCursor];
    
    
    btView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 86, 86)];
    btView.center = CGPointMake(QR_SCREENWIDTH/2, preLayerHeight+12+43);
    
    btView.layer.cornerRadius = 43;
    btView.backgroundColor = UIColorFromRGB(0xeeeeee);
    [self addSubview:btView];
    
    recordBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 76, 76)];
    recordBtn.center = CGPointMake(43, 43);
    
    recordBtn.backgroundColor = UIColorFromRGB(0xfa5f66);
    
    [recordBtn addTarget:self action:@selector(shootButtonClick) forControlEvents:UIControlEventTouchUpInside];
    recordBtn.layer.cornerRadius = 38;
    recordBtn.layer.borderColor = UIColorFromRGB(0x28292b).CGColor;
    recordBtn.layer.borderWidth = 3;
    
    [btView addSubview:recordBtn];
    
//    finishBt = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
//    finishBt.center = CGPointMake(SCREEN_WIDTH-35, preLayerHeight+20+45);
//    finishBt.adjustsImageWhenHighlighted = NO;
//    [finishBt setBackgroundImage:[UIImage imageNamed:@"shootFinish"] forState:UIControlStateNormal];
//    [finishBt addTarget:self action:@selector(finishBtTap) forControlEvents:UIControlEventTouchUpInside];
//    finishBt.hidden = YES;
//    [self addSubview:finishBt];
    
    //初始化会话
    _captureSession=[[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {//设置分辨率
        _captureSession.sessionPreset=AVCaptureSessionPreset640x480;
    }
    
    //获得视频输入设备
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    //添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    NSError *error=nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    NSLog(@"..cap:%@, error:%@", _captureDeviceInput, error);
    error = nil;
    
    AVCaptureDeviceInput *audioCaptureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
    NSLog(@"..cap:%@, error:%@", audioCaptureDeviceInput, error);
    
    //初始化设备输出对象，用于获得输出数据
    _captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {// 如果可以添加设备
        [_captureSession addInput:_captureDeviceInput]; // 将视频设备添加进session
        [_captureSession addInput:audioCaptureDeviceInput]; // 将音频设备添加进session
        
        // 标识视频录入时稳定音频流的接收，我们这里设置为自动
        AVCaptureConnection *captureConnection=[_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }
    
    //创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer=[[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    
    CALayer *layer= self.viewContainer.layer;
    layer.masksToBounds=YES;
    
    _captureVideoPreviewLayer.frame=  CGRectMake(0, 0, preLayerWidth, preLayerHeight);
    _captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    [layer insertSublayer:_captureVideoPreviewLayer below:self.focusCursor.layer];
    
    [self addGenstureRecognizer];// 添加点击手势（聚焦）
    
    //进度条
    progressPreView = [[UIView alloc]initWithFrame:CGRectMake(0, preLayerHeight, 0, 4)];
    progressPreView.backgroundColor = UIColorFromRGB(0xffc738);
    progressPreView.layer.cornerRadius = 2;
    
    [self.viewContainer addSubview:progressPreView];
    
    flashBt = [[UIButton alloc]initWithFrame:CGRectMake(QR_SCREENWIDTH-90, 5, 34, 34)];
    [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
    flashBt.layer.cornerRadius = 17;
    
    [flashBt addTarget:self action:@selector(flashBtTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewContainer addSubview:flashBt];
    
    cameraBt = [[UIButton alloc]initWithFrame:CGRectMake(QR_SCREENWIDTH-40, 5, 34, 34)];
    [cameraBt setBackgroundImage:[UIImage imageNamed:@"changeCamer"] forState:UIControlStateNormal];
    cameraBt.layer.cornerRadius = 17;
    
    [cameraBt addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewContainer addSubview:cameraBt];
    
}

-(void)flashBtTap:(UIButton*)bt{
    
    if (bt.selected == YES) {
        bt.selected = NO;
        //关闭闪光灯
        [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
        [self setTorchMode:AVCaptureTorchModeOff];
    }else{
        bt.selected = YES;
        //开启闪光灯
        [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
        [self setTorchMode:AVCaptureTorchModeOn];
    }
}

-(void)startTimer{
    recordBtn.backgroundColor = UIColorFromRGB(0xf8ad6a);
    
    countTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [countTimer fire];
}

-(void)stopTimer{
    recordBtn.backgroundColor = UIColorFromRGB(0xfa5f66);
    
    [countTimer invalidate];
    countTimer = nil;
    
}
- (void)onTimer:(NSTimer *)timer
{
    currentTime += TIMER_INTERVAL;
    float progressWidth = progressPreView.frame.size.width+progressStep;
    [progressPreView setFrame:CGRectMake(0, preLayerHeight, progressWidth, 4)];
    
//    if (currentTime>2) {
//        finishBt.hidden = NO;
//    }
    
    //11:09:49.227
    //
    NSLog(@"..:%f", currentTime);
    
    //时间到了停止录制视频（当前设置的是10秒）
    if (currentTime>=self.totalTime) {
        [countTimer invalidate];
        countTimer = nil;
        [_captureMovieFileOutput stopRecording];
    }
}

//-(void)finishBtTap{
//    currentTime=self.totalTime+10;
//    [countTimer invalidate];
//    countTimer = nil;
//    
//    //正在拍摄
//    if (_captureMovieFileOutput.isRecording) {
//        [_captureMovieFileOutput stopRecording];
//    }else{//已经暂停了
//        [self mergeAndExportVideosAtFileURLs:urlArray outputFileURL:<#(NSURL *)#>];
//    }
//}

#pragma mark 视频录制
- (void)shootButtonClick {
    
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording]) { // 如果没有再录制视频
        recordBtn.backgroundColor = UIColorFromRGB(0xfa5f66);
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        
        // 往路径的 URL 开始写入录像 Buffer ,边录边写
        [self.captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self getVideoSaveFilePathString]] recordingDelegate:self];
        
    } else {
        
        [self stopTimer];
        [self.captureMovieFileOutput stopRecording];//停止录制
    }
}
#pragma mark 切换前后摄像头
- (void)changeCamera:(UIButton*)bt {
    AVCaptureDevice *currentDevice=[self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition=AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition=AVCaptureDevicePositionBack;
        flashBt.hidden = NO;
    }else{
        flashBt.hidden = YES;
    }
    toChangeDevice=[self getCameraDeviceWithPosition:toChangePosition];
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];
    //移除原有输入对象
    [self.captureSession removeInput:self.captureDeviceInput];
    //添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        [self.captureSession addInput:toChangeDeviceInput];
        self.captureDeviceInput=toChangeDeviceInput;
    }
    //提交会话配置
    [self.captureSession commitConfiguration];
    
    //关闭闪光灯
    flashBt.selected = NO;
    [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
    [self setTorchMode:AVCaptureTorchModeOff];
    
}

#pragma mark - 视频输出代理
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
    [self startTimer];
}
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"时间到了");
    [urlArray addObject:outputFileURL];
    //时间到了
    if (currentTime >= self.totalTime) {
        [self mergeAndExportVideosAtFileURLs:urlArray outputFileURL:outputFileURL];
    }
}


- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray outputFileURL:(NSURL *)outputFileURL
{
    NSError *error = nil;
    
    CGSize renderSize = CGSizeMake(0, 0);
    
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    CMTime totalDuration = kCMTimeZero;
    
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileURLArray) {
        
        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        [assetArray addObject:asset];
        
        NSArray* tmpAry =[asset tracksWithMediaType:AVMediaTypeVideo];
        if (tmpAry.count>0) {
            AVAssetTrack *assetTrack = [tmpAry objectAtIndex:0];
            [assetTrackArray addObject:assetTrack];
            renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.height);
            renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.width);
        }
    }
    
    CGFloat renderW = MIN(renderSize.width, renderSize.height);
    
    for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
        
        AVAsset *asset = [assetArray objectAtIndex:i];
        AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
        
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSArray*dataSourceArray= [asset tracksWithMediaType:AVMediaTypeAudio];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:([dataSourceArray count]>0)?[dataSourceArray objectAtIndex:0]:nil
                             atTime:totalDuration
                              error:nil];
        
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:assetTrack
                             atTime:totalDuration
                              error:&error];
        
        AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
        
        CGFloat rate;
        rate = renderW / MIN(assetTrack.naturalSize.width, assetTrack.naturalSize.height);
        
        CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
        layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0+preLayerHWRate*(preLayerHeight-preLayerWidth)/2));
        layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
        
        [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
        [layerInstruciton setOpacity:0.0 atTime:totalDuration];
        
        [layerInstructionArray addObject:layerInstruciton];
    }
    
    NSString *path = [self getVideoMergeFilePathString];
    NSURL *mergeFileURL = [NSURL fileURLWithPath:path];
    
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 100);
    mainCompositionInst.renderSize = CGSizeMake(renderW, renderW*preLayerHWRate);
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // 删除掉原视频，因为原视频太大
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtURL:outputFileURL error:nil];
            
            if ([self.delegate respondsToSelector:@selector(videoView:didfinishRecordingVideo:)]) {
                [self.delegate videoView:self didfinishRecordingVideo:mergeFileURL];
            }
            
            [self.captureSession stopRunning];
        
            //还原数据-----------
//            [self deleteAllVideos];
            currentTime = 0;
            [progressPreView setFrame:CGRectMake(0, preLayerHeight, 0, 4)];
            recordBtn.backgroundColor = UIColorFromRGB(0xfa5f66);
//            finishBt.hidden = YES;
            
        });
    }];
    
}
//最后合成为 mp4
- (NSString *)getVideoMergeFilePathString
{
    NSString *path = _videoDirectoryPath;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"merge.mp4"];
    
    return fileName;
}

//录制保存的时候要保存为 mov
- (NSString *)getVideoSaveFilePathString
{
    NSString *path = _videoDirectoryPath;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mov"];
    
    return fileName;
}

- (void)createVideoFolderIfNotExist
{
    NSString *path = _videoDirectoryPath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建保存视频文件夹失败");
        }
    }
}
//- (void)deleteAllVideos
//{
//    for (NSURL *videoFileURL in urlArray) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            NSString *filePath = [[videoFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
//            NSFileManager *fileManager = [NSFileManager defaultManager];
//            if ([fileManager fileExistsAtPath:filePath]) {
//                NSError *error = nil;
//                [fileManager removeItemAtPath:filePath error:&error];
//                
//                if (error) {
//                    NSLog(@"delete All Video 删除视频文件出错:%@", error);
//                }
//            }
//        });
//    }
//    [urlArray removeAllObjects];
//}

#pragma mark - 私有方法
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

-(void)setTorchMode:(AVCaptureTorchMode )torchMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isTorchModeSupported:torchMode]) {
            [captureDevice setTorchMode:torchMode];
        }
    }];
}

-(void)setFocusMode:(AVCaptureFocusMode )focusMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}

-(void)setExposureMode:(AVCaptureExposureMode)exposureMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
    }];
}

-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

-(void)addGenstureRecognizer{
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.viewContainer addGestureRecognizer:tapGesture];
}
-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    CGPoint point= [tapGesture locationInView:self.viewContainer];
    CGPoint cameraPoint= [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point]; // 将UI坐标转化为摄像头坐标
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursor.center=point;
    self.focusCursor.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha=0;
        
    }];
}

/*
 * 判断指定的路径是否存在，如果存在返回并且是文件夹就返回yes，否则返回no。
 *
 * path: 指定的路径
 */
- (BOOL)isPathExit:(NSString *)path {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    
    if(!isDirExist || !isDir) { // 如果路径不存在或者路径不是文件夹就返回NO
        
        return NO;
    }
    
    return YES;
}


#pragma mark -setter
- (void)setProgressViewColor:(UIColor *)progressViewColor {
    progressPreView.backgroundColor = progressViewColor;
}

- (void)setRecordBtnOutCircleColor:(UIColor *)recordBtnOutCircleColor {
    btView.backgroundColor = recordBtnOutCircleColor;
}

- (void)setRecordBtnBorderColor:(UIColor *)recordBtnBorderColor {
    recordBtn.layer.borderColor = recordBtnBorderColor.CGColor;
}

- (void)setRecordBtnBackGroundColor:(UIColor *)recordBtnBackGroundColor {
    recordBtn.backgroundColor = recordBtnBackGroundColor;
}

- (void)setRecordBtnBorderWidth:(CGFloat)recordBtnBorderWidth {
    recordBtn.layer.borderWidth = recordBtnBorderWidth;
}

@end