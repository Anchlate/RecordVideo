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
#import "BPClearCach.h"
//#import "QRPlayView.h"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

typedef NS_ENUM(NSInteger, ANRecordButtonAction) {
    
    ANRecordButtonActionRecord = 1 << 1,
    ANRecordButtonActionFinish = 1 << 2,
    ANRecordButtonActionSend   = 1 << 3
    
};


#define TIMER_INTERVAL 1.0
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
@property (nonatomic, assign) int totalTime; //视频总长度 默认10秒
@property (nonatomic, assign) float bottomHeight; // 底部的高度
@property (nonatomic, strong) NSData *videoData; // 视频数据
@property (nonatomic, strong) NSURL *mergeVideoURL;

@property (nonatomic, strong) UIView *navView;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *changeCameraBtn;
@property (nonatomic, assign) ANRecordButtonAction recordBtnAction;

@property (nonatomic, strong) UILabel *currenTimeLabel;
@property (nonatomic, strong) UILabel *surplusTimeLabel;
@property (nonatomic, strong) UILabel *titleLabel;




@end

@implementation QRVideoView {
    
    NSMutableArray* urlArray;//保存视频片段的数组
    
    int currentTime; //当前视频长度
    
    NSTimer *countTimer; //计时器
    UIView* progressPreView; //进度条
    float progressStep; //进度条每次变长的最小单位
    
    float preLayerWidth;//镜头宽
    float preLayerHeight;//镜头高
    float preLayerHWRate; //高，宽比
    
    UIView* btView; //
    UIButton* recordBtn;//录制按钮
//    UIButton *sendBtn; // 确认按钮
//    UIButton *resetBtn; // 重拍
//    UIButton* finishBt;//结束按钮
//    UIButton *playBtn; // 播放按钮
//    QRPlayView *playView; // 播放View
    
    
//    UIButton* flashBt;//闪光灯
//    UIButton* cameraBt;//切换摄像头
    
    
    
    float QR_SCREENWIDTH;
    float QR_SCREENHEIGHT;
//    float btViewWidthRate;
//    float recordBtnWidthRate;
}

- (id)initWithFrame:(CGRect)frame totalTime:(int)totalTime videoDirectoryPath:(NSString *)videoDirectoryPath {
    
    if (self = [super initWithFrame:frame]) {
        
        _isAuthorizationed = YES;
        
        // 摄像头
        //        AVAuthorizationStatusNotDetermined = 0,// 未进行授权选择
        //        AVAuthorizationStatusRestricted,　　　　// 未授权，且用户无法更新，如家长控制情况下
        //        AVAuthorizationStatusDenied,　　　　　　 // 用户拒绝App使用
        //        AVAuthorizationStatusAuthorized,　　　　// 已授权，可使用
        
        // 麦克风
        //        AVAudioSessionRecordPermissionUndetermined,　　　　// 用户尚未被请求许可。
        //        AVAudioSessionRecordPermissionDenied,　　　　　　 // 用户已被要求并已拒绝许可。
        //        AVAudioSessionRecordPermissionGranted,　　　　// 用户已被要求并已授予权限。
        
        
#warning ------
//        AVAuthorizationStatus cameraAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
//        AVAudioSessionRecordPermission maicroPhoneAuthStatus = [[AVAudioSession sharedInstance] recordPermission];
//        
//        if (AVAuthorizationStatusRestricted == cameraAuthStatus || AVAuthorizationStatusDenied == cameraAuthStatus) {
//            //授权失败
//            _isAuthorizationed = NO;
//            NSLog(@"摄像头没有授权");
//            return self;
//        } else if ( maicroPhoneAuthStatus == AVAudioSessionRecordPermissionDenied) {
//            
//            _isAuthorizationed = NO;
//            NSLog(@"麦克风没有授权");
//            return self;
//        }
        
        self.recordBtnAction = ANRecordButtonActionRecord;
        QR_SCREENWIDTH = CGRectGetWidth(frame);
        QR_SCREENHEIGHT = CGRectGetHeight(frame);
        
        preLayerWidth = QR_SCREENWIDTH;
        preLayerHeight = (578.0 / 1334) * QR_SCREENHEIGHT;
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.bottomHeight = QR_SCREENHEIGHT - 44 - preLayerHeight - (128.0 / 1334) * QR_SCREENHEIGHT;
        
//        btViewWidthRate = 0.782;
//        recordBtnWidthRate = 0.884;
        
        //视频最大时长 默认10秒
        self.totalTime = totalTime;
        
        if (self.totalTime <= 0) {
            self.totalTime = 10;
        }
        
        // videoDirectoryPath
        _videoDirectoryPath = videoDirectoryPath;
        
        urlArray = [[NSMutableArray alloc]init];
        
        
        preLayerHWRate = preLayerHeight/preLayerWidth;
        
        progressStep = QR_SCREENWIDTH*TIMER_INTERVAL/self.totalTime;
        
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

        
#warning ------
//        AVAuthorizationStatus cameraAuthStatus2 = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
//        AVAudioSessionRecordPermission maicroPhoneAuthStatus2 = [[AVAudioSession sharedInstance] recordPermission];
//        
//        if (!(AVAuthorizationStatusAuthorized == cameraAuthStatus2)) {
//            //授权失败
//            _isAuthorizationed = NO;
//            NSLog(@"摄像头没有授权");
//            return self;
//        } else if (!(maicroPhoneAuthStatus2 == AVAudioSessionRecordPermissionGranted)) {
//            
//            _isAuthorizationed = NO;
//            NSLog(@"麦克风没有授权");
//            return self;
//        }
//        _isAuthorizationed = YES;
        
        
    }
    
    [self.captureSession startRunning];
    
    return self;
}

-(void)initCapture{
    
    self.navView.frame = CGRectMake(0, 0, preLayerWidth, 44);
    [self addSubview:self.navView];
    
    [self.navView insertSubview:self.titleLabel belowSubview:self.backBtn];
    self.titleLabel.frame = self.navView.bounds;
    
    self.backBtn.frame = CGRectMake(0, 0, 44, 44);
    [self.navView addSubview:self.backBtn];
    
    self.changeCameraBtn.frame = CGRectMake(QR_SCREENWIDTH - 44, 0, 44, 44);
    [self.navView addSubview:self.changeCameraBtn];
    
    
    //视频高度加进度条（10）高度
    self.viewContainer.frame = CGRectMake(0, CGRectGetMaxY(self.navView.frame) + (128.0 / 1334) * QR_SCREENHEIGHT, preLayerWidth, preLayerHeight);
    [self addSubview:self.viewContainer];
    
    self.focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 50, 50)];
    [self.focusCursor setImage:[UIImage imageNamed:@"focusImg"]];
    self.focusCursor.alpha = 0;
    [self.viewContainer addSubview:self.focusCursor];
    
    
    // bootomView
    btView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.viewContainer.frame), QR_SCREENWIDTH, self.bottomHeight)];
    
    btView.backgroundColor = [UIColor blackColor];
    [self addSubview:btView];
    
    
    // currentTimeLabel
    [btView addSubview:self.currenTimeLabel];
    CGSize timeLabelSize = [self.currenTimeLabel.text sizeWithAttributes:@{NSFontAttributeName : self.currenTimeLabel.font}];
    self.currenTimeLabel.frame = CGRectMake(5, 10, QR_SCREENWIDTH / 2, timeLabelSize.height);
    
    
    // surplusTimeLabel
    [btView addSubview:self.surplusTimeLabel];
    self.surplusTimeLabel.frame = CGRectMake(QR_SCREENWIDTH / 2, 10, QR_SCREENWIDTH / 2 - 5, timeLabelSize.height);
    
    // recordBtn
    UIImage *recordImage = [UIImage imageNamed:@"record"];
//    recordBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, (188.0 / 750) * QR_SCREENWIDTH, (188.0 / 750) * QR_SCREENWIDTH)];
    recordBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, recordImage.size.width, recordImage.size.height)];
    
    [recordBtn setImage:recordImage forState:UIControlStateNormal];
    recordBtn.center = CGPointMake(CGRectGetWidth(btView.bounds) / 2, CGRectGetHeight(btView.bounds) / 2);
    
    recordBtn.backgroundColor = [UIColor clearColor];
    
    [recordBtn addTarget:self action:@selector(shootButtonClick) forControlEvents:UIControlEventTouchUpInside];

    
    [btView addSubview:recordBtn];
    
    //初始化会话
    _captureSession=[[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {//设置分辨率
//        _captureSession.sessionPreset=AVCaptureSessionPreset640x480;
        //AVCaptureSessionPreset960x540
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
    
    _captureVideoPreviewLayer.frame = CGRectMake(0, 0, self.viewContainer.frame.size.width, self.viewContainer.frame.size.height);//self.viewContainer.bounds;//CGRectMake(0, 0, preLayerWidth, preLayerHeight);
    _captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    //                                     AVLayerVideoGravityResizeAspectFill
    [layer insertSublayer:_captureVideoPreviewLayer below:self.focusCursor.layer];
    
    [self addGenstureRecognizer];// 添加点击手势（聚焦）
    
    //进度条
    progressPreView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 100, 3)];
    progressPreView.backgroundColor = UIColorFromRGB(0x00aaef);
    progressPreView.layer.cornerRadius = 2;
    
    [btView addSubview:progressPreView];
    
}

- (void)addPlayViewWithURL:(NSURL *)videoURL {
    
    CGRect frame = self.viewContainer.bounds;
    frame.size.height = frame.size.height + 4;
    
//    playView = [[QRPlayView alloc]initWithFrame:self.viewContainer.bounds videoURL:videoURL];
//    playView.backgroundColor = self.backgroundColor;
    
}

//- (void)removePlayView {
//    if (!playView) {
//        return;
//    }
//    [playView removeFromSuperview];
//    playView = nil;
//    
//}

-(void)startTimer{
    
    countTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [countTimer fire];
    
}

-(void)stopTimer{
    
    [countTimer invalidate];
    countTimer = nil;
    
}

- (void)onTimer:(NSTimer *)timer
{
    currentTime += TIMER_INTERVAL;
    float progressWidth = progressPreView.frame.size.width+progressStep;
    [progressPreView setFrame:CGRectMake(0, 0, progressWidth, 3)];
    
    [self setCurrentTimeLabelText:currentTime];
    [self setSurplusTimeLabelText:(self.totalTime - currentTime)];
    
    //时间到了停止录制视频（当前设置的是10秒）
    if (currentTime>=self.totalTime) {
        [countTimer invalidate];
        countTimer = nil;
        [_captureMovieFileOutput stopRecording];
    }
    
    
}

#pragma mark - 视频输出代理
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
    [self startTimer];
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"时间到了");
    [urlArray addObject:outputFileURL];
    
    // 1. 重置当前时间
    currentTime = 0;
    
    // 2. 改变按钮的状态为 ”发送“
    self.recordBtnAction = ANRecordButtonActionSend;
    
    // 3. 切换前后摄像头的按钮显示
    self.changeCameraBtn.hidden = NO;
    
    // 4. 改变切换前后摄像头按钮的图片为重拍
    [self.changeCameraBtn setImage:[UIImage imageNamed:@"reset"] forState:UIControlStateNormal];
    
    // 5. 暂停
    [self.captureSession stopRunning];
    
    recordBtn.enabled = NO;
    
    // 6. 压缩视频
    [self mergeAndExportVideosAtFileURLs:urlArray outputFileURL:outputFileURL];
    
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
        layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0+preLayerHWRate*(preLayerHeight-preLayerWidth)/2.0));
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
            
            self.mergeVideoURL = mergeFileURL;
            
            NSLog(@"......:%f", [BPClearCach cachSizeAtPath:[self.mergeVideoURL path]]);
            
            // 删除掉原视频，因为原视频太大
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtURL:outputFileURL error:nil];
            
            self.videoData = [NSData dataWithContentsOfURL:mergeFileURL];
            
            //还原数据-----------
            [self deleteAllVideos];
            
            recordBtn.enabled = YES;
            
            
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
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mp4"];
    
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
- (void)deleteAllVideos
{
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
    [urlArray removeAllObjects];
}

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

- (void)recordVideo {
    
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording]) { // 如果没有再录制视频
//        recordBtn.backgroundColor = UIColorFromRGB(0xfa5f66);
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        
        // 往路径的 URL 开始写入录像 Buffer ,边录边写
        [self.captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self getVideoSaveFilePathString]] recordingDelegate:self];
        
    } else {
        
        [self stopTimer];
        [self.captureMovieFileOutput stopRecording];//停止录制
    }
    
}


// 切换前后摄像头
- (void)changeCamera {
    
    AVCaptureDevice *currentDevice=[self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition=AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition=AVCaptureDevicePositionBack;
//        flashBt.hidden = NO;
    }else{
//        flashBt.hidden = YES;
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
//    flashBt.selected = NO;
//    [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
    [self setTorchMode:AVCaptureTorchModeOff];
}


// 重拍视频
- (void)resetData {
    
    NSLog(@"......重拍视频");
    [self.captureSession startRunning];
    
    //还原数据-----------
    [self deleteAllVideos];
    
    // 删除掉原视频，因为原视频太大
    [self removeVideoFile:self.mergeVideoURL];
    self.mergeVideoURL = nil;
    
    self.videoData = nil;
    
    currentTime = 0;
    [progressPreView setFrame:CGRectMake(0, preLayerHeight, 0, 4)];
    
}

- (void)removeVideoFile:(NSURL *)videoURL {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:videoURL error:nil];
    
}

- (NSString *)timeStringFromSeconds:(int)seconds {
    
    NSString *minuteStr = nil;
    NSString *secondStr = nil;
    
    int minute = seconds / 60;
    int second = seconds % 60;
    
    if (minute < 10) {
        
        minuteStr = [NSString stringWithFormat:@"0%d", minute];
        NSLog(@"..??...??...????<,,???:%d", minute);
        
    } else {
        minuteStr = [NSString stringWithFormat:@"%d", minute];
    }
    
    if (second < 10) {
        
        secondStr = [NSString stringWithFormat:@"0%d", second];
        
    } else {
        secondStr = [NSString stringWithFormat:@"%d", second];
    }
    
    return [NSString stringWithFormat:@"%@:%@", minuteStr, secondStr];
}

- (void)setCurrentTimeLabelText:(int)seconds {
    
    self.currenTimeLabel.text = [self timeStringFromSeconds:seconds];
}

- (void)setSurplusTimeLabelText:(int)seconds {
    
    self.surplusTimeLabel.text = [NSString stringWithFormat:@"-%@", [self timeStringFromSeconds:seconds]];
}



#pragma mark -Event
- (void)backBtnAction:(UIButton *)button {
    
    NSLog(@"......返回");
//    self.recordBtnAction = ANRecordButtonActionFinish;
    
    [self removeVideoFile:self.mergeVideoURL];
    [self stopTimer];
    [self.captureSession stopRunning];
    [progressPreView setFrame:CGRectMake(0, 0, 0, 3)];
    
    // 4. 显示时间设置为0
    [self setCurrentTimeLabelText:0];
    [self setSurplusTimeLabelText:0];
    
    if ([self.delegate respondsToSelector:@selector(goBack)]) {
        
        [self.delegate goBack];
    }
}

- (void)changeCameraBtnAction:(UIButton *)button {
    
    recordBtn.enabled = YES;
    NSLog(@"......切换摄像头");
//    self.recordBtnAction = ANRecordButtonActionSend;
    
    switch (self.recordBtnAction) {
        case ANRecordButtonActionRecord:
            
            // 录制按钮为“录制”，说明还没有开始录制，所以应该是切换前后摄像头
            [self changeCamera];
            
            break;
            
        case ANRecordButtonActionSend:
            
            // 1. 录制按钮为“完成”，说明还录制已经完成，所以应该是重新录制
            [self resetData];
            
            // 2. 变回“录制”
            self.recordBtnAction = ANRecordButtonActionRecord;
            
            // 3. 变回切换前后摄像头
            [self.changeCameraBtn setImage:[UIImage imageNamed:@"changeCamera"] forState:UIControlStateNormal];
            
            // 4. 显示时间设置为0
            [self setCurrentTimeLabelText:0];
            [self setSurplusTimeLabelText:0];
            
            
            break;
            
        default:
            break;
    }
}

- (void)shootButtonClick {
    
    switch (self.recordBtnAction) {
        case ANRecordButtonActionRecord:
        {
            
            AVAuthorizationStatus cameraAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            
            if (cameraAuthStatus != AVAuthorizationStatusAuthorized) {
                
                
                if ([self.delegate respondsToSelector:@selector(cameraAndMicroPhonePermission:)]) {
                    
                    [self.delegate cameraAndMicroPhonePermission:ANVideoViewPermissionCamera];
                    return;
                }
            }
            
            
            AVAudioSessionRecordPermission maicroPhoneAuthStatus = [[AVAudioSession sharedInstance] recordPermission];
                
            if (maicroPhoneAuthStatus != AVAudioSessionRecordPermissionGranted) {
                
                if ([self.delegate respondsToSelector:@selector(cameraAndMicroPhonePermission:)]) {
                    
                    [self.delegate cameraAndMicroPhonePermission:ANVideoViewPermissionMicroPhone];
                    return;
                }
                
            }
            
            NSLog(@"......开始录制视频");
            // 1. 开始录制视频
            [self recordVideo];
            
            // 2. 改变按钮的状态为 “完成”
            self.recordBtnAction = ANRecordButtonActionFinish;
            
            // 3. 切换前后摄像头的按钮隐藏
            self.changeCameraBtn.hidden = YES;
            
        }
            break;
            
        case ANRecordButtonActionFinish:
            
            NSLog(@"......完成");
            
            // 1. 停止播放视频
            [self stopTimer];
            [self.captureMovieFileOutput stopRecording];
            
            // 2. 改变按钮的状态为 ”发送“
            self.recordBtnAction = ANRecordButtonActionSend;
            
            // 3. 切换前后摄像头的按钮显示
            self.changeCameraBtn.hidden = NO;
            
            // 4. 改变切换前后摄像头按钮的图片为重拍
            [self.changeCameraBtn setImage:[UIImage imageNamed:@"reset"] forState:UIControlStateNormal];
            
            break;
            
        case ANRecordButtonActionSend:
            
            NSLog(@"......发送");
            
            // 1. 发送视频
            if ([self.delegate respondsToSelector:@selector(videoView:didfinishRecordingVideo:)]) {
                [self.delegate videoView:self didfinishRecordingVideo:self.videoData];
            }
            
            if ([self.delegate respondsToSelector:@selector(videoView:didfinishRecordingVideoURL:)]) {
                [self.delegate videoView:self didfinishRecordingVideoURL:self.mergeVideoURL];
            }
            
//            if ([self.delegate respondsToSelector:@selector(goBack)]) {
//                
//                [self.delegate goBack];
//            }
            
            
            // 2. 改变按钮的状态为 “录制”
            self.recordBtnAction = ANRecordButtonActionRecord;
            
            // 3. 前后摄像头按钮图片改为相机图片
            [self.changeCameraBtn setImage:[UIImage imageNamed:@"changeCamera"] forState:UIControlStateNormal];
            
            // 4. 隐藏进度条
            [progressPreView setFrame:CGRectMake(0, 0, 0, 3)];
            
            
            // 5. 显示时间设置为0
            [self setCurrentTimeLabelText:0];
            [self setSurplusTimeLabelText:0];
            
            break;
            
        default:
            break;
    }
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

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
#warning message
//    self.viewContainer.backgroundColor = backgroundColor;
}

- (void)setRecordBtnAction:(ANRecordButtonAction)recordBtnAction {
    
    _recordBtnAction = recordBtnAction;
    
    switch (_recordBtnAction) {
        case ANRecordButtonActionRecord:
            
            [recordBtn setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
            
            break;
            
        case ANRecordButtonActionSend:
            
            [recordBtn setImage:[UIImage imageNamed:@"send"] forState:UIControlStateNormal];
            break;
            
        case ANRecordButtonActionFinish:
            
            [recordBtn setImage:[UIImage imageNamed:@"finish"] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
    
}

#pragma mark -Getter
- (UIView *)navView {
    if (!_navView) {
        _navView = [[UIView alloc]init];
        _navView.backgroundColor = [UIColor blackColor];
    }
    return _navView;
}

- (UIView *)viewContainer {
    if (!_viewContainer) {
        _viewContainer = [[UIView alloc]init];
        _viewContainer.backgroundColor = [UIColor redColor];
    }
    return _viewContainer;
}

- (UIButton *)backBtn {
    
    if (!_backBtn) {
        
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (UIButton *)changeCameraBtn {
    if (!_changeCameraBtn) {
        
        _changeCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_changeCameraBtn setImage:[UIImage imageNamed:@"changeCamera"] forState:UIControlStateNormal];
        [_changeCameraBtn addTarget:self action:@selector(changeCameraBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changeCameraBtn;
}

- (UILabel *)currenTimeLabel {
    
    if (!_currenTimeLabel) {
        _currenTimeLabel = [[UILabel alloc]init];
        _currenTimeLabel.font = [UIFont systemFontOfSize:12];
        _currenTimeLabel.textColor = UIColorFromRGB(0x989898);
        _currenTimeLabel.text = @"00:00";
        
    }
    return _currenTimeLabel;
}

- (UILabel *)surplusTimeLabel {
    
    if (!_surplusTimeLabel) {
        _surplusTimeLabel = [[UILabel alloc]init];
        _surplusTimeLabel.font = [UIFont systemFontOfSize:12];
        _surplusTimeLabel.textColor = UIColorFromRGB(0x989898);
        _surplusTimeLabel.text = @"-00:00";
        _surplusTimeLabel.textAlignment = NSTextAlignmentRight;
    }
    return _surplusTimeLabel;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        //        _titleLabel.font = [UIFont boldSystemFontOfSize:19];
        _titleLabel.font = [UIFont systemFontOfSize:19];
        _titleLabel.text = @"小视频";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}
@end