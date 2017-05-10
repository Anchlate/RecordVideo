//
//  ANVideoView.m
//  RecordVideo
//
//  Created by Qianrun on 16/6/21.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "ANVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Masonry.h"
#import "QRPlayView.h"


#define TIMER_INTERVAL 0.05

// weakself
#define WEAKSELF(weakSelf) __weak __typeof(&*self)weakSelf = self

// ox color
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

typedef NS_ENUM(NSInteger, ANRecordButtonAction) {
    
    ANRecordButtonActionRecord = 1 << 1,
    ANRecordButtonActionFinish = 1 << 2,
    ANRecordButtonActionSend   = 1 << 3
    
};

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface ANVideoView ()<AVCaptureFileOutputRecordingDelegate>
{
    float currentTime; //当前视频长度
    
    NSTimer *countTimer; //计时器
    
    float preLayerWidth;//镜头宽
    float preLayerHeight;//镜头高
    float preLayerHWRate; //高，宽比
    
    UIButton* cameraBt;//切换摄像头
    
    float QR_SCREENWIDTH;
    float QR_SCREENHEIGHT;
}

@property (nonatomic, strong) UIView *navView;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *changeCameraBtn;
@property (nonatomic, strong) UIView *viewContainer;
@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, strong) UILabel *currenTimeLabel;
@property (nonatomic, strong) UILabel *surplusTimeLabel;
@property (nonatomic, strong) UIButton *recordBtn;
@property (nonatomic, assign) ANRecordButtonAction recordBtnAction;



/******/

@property (strong,nonatomic) AVCaptureSession *captureSession;//负责输入和输出设置之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层

@property (nonatomic, assign) float totalTime; //视频总长度 默认10秒
@property (nonatomic, strong) NSData *videoData; // 视频数据
@property (nonatomic, strong) NSURL *mergeVideoURL;

@property (nonatomic, strong) NSMutableArray *urlArray;

/******/




@end

@implementation ANVideoView

- (id)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor blackColor];
        
        self.recordBtnAction = ANRecordButtonActionRecord;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths objectAtIndex:0];
        _videoDirectoryPath = path;
        
        [self addSubview:self.navView];
        [self.navView addSubview:self.backBtn];
        [self.navView addSubview:self.changeCameraBtn];
        [self addSubview:self.viewContainer];
        [self addSubview:self.bottomView];
        
        [self.bottomView addSubview:self.progressView];
        [self.bottomView addSubview:self.currenTimeLabel];
        [self.bottomView addSubview:self.surplusTimeLabel];
        [self.bottomView addSubview:self.recordBtn];
        
        [self layoutViews];
        
        
        /**********/
        
        //视频最大时长 默认10秒
        self.totalTime = 3;
        
        if (self.totalTime==0) {
            self.totalTime =3;
        }
        
        //
        [self initCapture];
        
    }
    
    [self.captureSession startRunning];
    return self;
}

- (void)layoutViews {
    
    WEAKSELF(weakSelf);
    [self.navView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(weakSelf).offset(20);
        make.leading.trailing.equalTo(weakSelf);
        make.height.mas_equalTo(@44);
        
    }];
    
    [self.viewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(weakSelf.navView.mas_bottom).offset(64);
        make.leading.trailing.equalTo(weakSelf);
        make.height.mas_equalTo(289);
        
    }];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.leading.top.bottom.equalTo(weakSelf.navView);
        make.width.mas_equalTo(@44);
        
    }];
    
    [self.changeCameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.trailing.bottom.equalTo(weakSelf.navView);
        make.width.equalTo(@44);
        
    }];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.leading.trailing.bottom.equalTo(weakSelf);
        make.top.equalTo(weakSelf.viewContainer.mas_bottom);
        
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.leading.equalTo(weakSelf.bottomView);
        make.height.mas_equalTo(@3);
        make.width.mas_equalTo(@0);
        
    }];
    
    [self.currenTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(weakSelf.bottomView).offset(10);
        make.leading.equalTo(weakSelf.bottomView).offset(5);
        
    }];
    
    [self.surplusTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(weakSelf.bottomView).offset(10);
        make.trailing.equalTo(weakSelf.bottomView).offset(-5);
        
    }];
    
    [self.recordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.center.equalTo(weakSelf.bottomView);
        
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _captureVideoPreviewLayer.frame = self.viewContainer.bounds;
    QR_SCREENWIDTH = CGRectGetWidth(self.bounds);
    QR_SCREENHEIGHT = CGRectGetHeight(self.bounds);
    preLayerWidth = QR_SCREENWIDTH;
    preLayerHeight = QR_SCREENHEIGHT; //镜头高
    
    preLayerHWRate = preLayerHeight/preLayerWidth;
    
}

#warning message
/***************************************************************************************************************/


-(void)initCapture{
    
#warning recordBtn
//    [recordBtn addTarget:self action:@selector(shootButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
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
//    [layer insertSublayer:_captureVideoPreviewLayer below:self.focusCursor.layer];
    [layer addSublayer:_captureVideoPreviewLayer];
    
    [self addGenstureRecognizer];// 添加点击手势（聚焦）
    
    
#warning flashBtn
//    [flashBt addTarget:self action:@selector(flashBtTap:) forControlEvents:UIControlEventTouchUpInside];
    
    cameraBt = [[UIButton alloc]initWithFrame:CGRectMake(QR_SCREENWIDTH-40, 5, 34, 34)];
    [cameraBt setBackgroundImage:[UIImage imageNamed:@"changeCamer"] forState:UIControlStateNormal];
    cameraBt.layer.cornerRadius = 17;
    
    [cameraBt addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewContainer addSubview:cameraBt];
    
#warning sendBtn
//    [sendBtn addTarget:self action:@selector(sendVideo:) forControlEvents:UIControlEventTouchUpInside];
    
#warning resetBtn
//    [resetBtn addTarget:self action:@selector(resetVideo:) forControlEvents:UIControlEventTouchUpInside];
    
#warning resetBtn
//    [playBtn addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)resetVideo:(UIButton *)button {
    
    NSLog(@"......重拍视频");
    
//    button.hidden = YES;
//    sendBtn.hidden = YES;
//    playBtn.hidden = YES;
    
    [self.captureSession startRunning];
    //还原数据-----------
    [self deleteAllVideos];
    currentTime = 0;
//    [progressPreView setFrame:CGRectMake(0, preLayerHeight, 0, 4)];
//    recordBtn.backgroundColor = UIColorFromRGB(0xfa5f66);
}

/*
- (void)playVideo:(UIButton *)button {
    
    NSLog(@"播放视频");
    [self removePlayView];
    [self addPlayViewWithURL:self.mergeVideoURL];
    
}

- (void)addPlayViewWithURL:(NSURL *)videoURL {
    
    CGRect frame = self.viewContainer.bounds;
    frame.size.height = frame.size.height + 4;
    
    playView = [[QRPlayView alloc]initWithFrame:self.viewContainer.bounds videoURL:videoURL];
    playView.backgroundColor = self.backgroundColor;
    [self.viewContainer insertSubview:playView belowSubview:sendBtn];
    
}
*/


/*
- (void)removePlayView {
    if (!playView) {
        return;
    }
    
    [playView removeFromSuperview];
    playView = nil;
    
}
*/



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
//    currentTime += TIMER_INTERVAL;
//    float progressWidth = progressPreView.frame.size.width+progressStep;
//    [progressPreView setFrame:CGRectMake(0, preLayerHeight, progressWidth, 4)];


    currentTime += TIMER_INTERVAL;
    float progressWidth = (currentTime / self.totalTime) * preLayerWidth;
    
    [self.progressView mas_updateConstraints:^(MASConstraintMaker *make) {
        
        make.width.mas_equalTo(@(progressWidth));
        
    }];
    
    //时间到了停止录制视频（当前设置的是10秒）
    if (currentTime>=self.totalTime) {
        [countTimer invalidate];
        countTimer = nil;
        [_captureMovieFileOutput stopRecording];
    }
}

#pragma mark 视频录制
- (void)shootButtonClick {
    
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording]) { // 如果没有再录制视频
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
    [self setTorchMode:AVCaptureTorchModeOff];
    
}

#pragma mark - 视频输出代理
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
    [self startTimer];
}


-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"时间到了");
    [self.urlArray addObject:outputFileURL];
    //时间到了
    if (currentTime >= self.totalTime) {
        [self mergeAndExportVideosAtFileURLs:self.urlArray outputFileURL:outputFileURL];
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
        
        
        float f1 = -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0;
        
        CGFloat f = -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0+preLayerHWRate*(preLayerHeight-preLayerWidth)/2;
        
        
        
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
            
            self.mergeVideoURL = mergeFileURL;
            // 删除掉原视频，因为原视频太大
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtURL:outputFileURL error:nil];
            
            self.videoData = [NSData dataWithContentsOfURL:mergeFileURL];
            
            [self.captureSession stopRunning];
            
            //还原数据-----------
            [self deleteAllVideos];
            currentTime = 0;
//            [progressPreView setFrame:CGRectMake(0, preLayerHeight, 0, 4)];
//            recordBtn.backgroundColor = UIColorFromRGB(0xfa5f66);
//            //            finishBt.hidden = YES;
//            
//            sendBtn.hidden = NO;
//            resetBtn.hidden = NO;
//            playBtn.hidden = NO;
            
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
    [self.urlArray removeAllObjects];
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
//    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
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



#warning message
/***************************************************************************************************************/

#pragma mark -Event
- (void)backBtnAction:(UIButton *)button {
    
    NSLog(@"......返回");
    self.recordBtnAction = ANRecordButtonActionFinish;
    
}

- (void)changeCameraBtnAction:(UIButton *)button {
    
    NSLog(@"......切换摄像头");
    self.recordBtnAction = ANRecordButtonActionSend;
    
    [self addPlayViewWithURL:self.mergeVideoURL];
    
}

- (void)recordBtnAction:(UIButton *)button {
    
    switch (self.recordBtnAction) {
        case ANRecordButtonActionRecord:
            
            NSLog(@"......开始录制视频");
            
            // 1. 开始录制视频
            [self shootButtonClick];
            
            
            // 2. 改变按钮的状态为 “完成”
            self.recordBtnAction = ANRecordButtonActionFinish;
            
            break;
            
        case ANRecordButtonActionFinish:
            
            NSLog(@"......完成");
            
            // 1. 停止播放视频
            
            // 2. 改变按钮的状态为 ”发送“
            self.recordBtnAction = ANRecordButtonActionSend;
            break;
            
        case ANRecordButtonActionSend:
            
            NSLog(@"......发送");
            
            // 1. 发送视频
            
            
            // 2. 改变按钮的状态为 “录制”
            [self.recordBtn setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
    
}

#pragma mark -Private


#pragma mark -Setter
- (void)setRecordBtnAction:(ANRecordButtonAction)recordBtnAction {
    
    _recordBtnAction = recordBtnAction;
    
    switch (_recordBtnAction) {
        case ANRecordButtonActionRecord:
            
            [self.recordBtn setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
            
            break;
            
        case ANRecordButtonActionSend:
            
            [self.recordBtn setImage:[UIImage imageNamed:@"send"] forState:UIControlStateNormal];
            break;
            
        case ANRecordButtonActionFinish:
        
            [self.recordBtn setImage:[UIImage imageNamed:@"finish"] forState:UIControlStateNormal];
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
        _viewContainer.backgroundColor = [UIColor blueColor];
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

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc]init];
        _bottomView.backgroundColor = [UIColor blackColor];
    }
    return _bottomView;
}

- (UIView *)progressView {
    if (!_progressView) {
        _progressView = [[UIView alloc]init];
        _progressView.backgroundColor = UIColorFromRGB(0x00aaef);
    }
    return _progressView;
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
    }
    return _surplusTimeLabel;
}

- (UIButton *)recordBtn {
    
    if (!_recordBtn) {
        _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_recordBtn setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
        [_recordBtn addTarget:self action:@selector(recordBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recordBtn;
}

- (NSMutableArray *)urlArray {
    
    if (!_urlArray) {
        _urlArray = [NSMutableArray array];
    }
    return _urlArray;
}

- (void)addPlayViewWithURL:(NSURL *)videoURL {
    
    QRPlayView *playView = [[QRPlayView alloc]initWithFrame:self.viewContainer.bounds videoURL:videoURL];
    playView.backgroundColor = [UIColor redColor];
    [self.viewContainer addSubview:playView];
    
}


@end