//
//  ViewController.m
//  录视频
//
//  Created by Qianrun on 16/5/31.
//  Copyright © 2016年 Qianrun. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PlayVideoViewController.h"

#import "Masonry.h"

#define TIMER_INTERVAL 0.05
#define VIDEO_FOLDER @"videoFolder"

@interface ViewController ()<AVCaptureFileOutputRecordingDelegate>
{
    float preLayerWidth;//镜头宽
    float preLayerHeight;//镜头高
    float preLayerHWRate; //高，宽比
    
    NSTimer *_timer;
    float currentTime;
}
@property (strong,nonatomic) AVCaptureSession *captureSession;//负责输入和输出设置之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入视频数据
@property (strong,nonatomic) AVCaptureDeviceInput *audioCaptureDeviceInput;//负责从AVCaptureDevice获得输入音频数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层
@property (nonatomic, strong) NSMutableArray *urlArray;//保存视频片段的数组

//@property (strong,nonatomic)  UIView *viewContainer;//视频容器
@property (weak, nonatomic) IBOutlet UIView *viewContainer;//视频容器
@property float totalTime; //视频总长度 默认10秒

- (IBAction)tapeVideo:(UIButton *)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    
    preLayerWidth = SCREEN_WIDTH;
    preLayerHeight = SCREEN_WIDTH;
    preLayerHWRate = preLayerHeight/preLayerWidth;
    [self createVideoFolderIfNotExist];
    
    //将设备输入添加到会话中
    if ([self.captureSession canAddInput:self.captureDeviceInput] && [self.captureSession canAddInput:self.audioCaptureDeviceInput]) {// 如果可以添加设备
        [self.captureSession addInput:self.captureDeviceInput]; // 将视频设备添加进session
        [self.captureSession addInput:self.audioCaptureDeviceInput]; // 将音频设备添加进session
        
        // 标识视频录入时稳定音频流的接收，我们这里设置为自动
        AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    //将设备输出添加到会话中
    if ([self.captureSession canAddOutput:self.captureMovieFileOutput]) {
        [self.captureSession addOutput:self.captureMovieFileOutput];
    }
   
    self.view.backgroundColor = UIColorFromRGB(0x1d1e20);
    
    CALayer *layer= self.viewContainer.layer;
    layer.masksToBounds=YES;
    
    self.captureVideoPreviewLayer.frame=  CGRectMake(0, 0, preLayerWidth, preLayerHeight);
    self.captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
//    [layer insertSublayer:_captureVideoPreviewLayer below:self.focusCursor.layer];
    [layer addSublayer:self.captureVideoPreviewLayer];
    
    //视频最大时长 默认10秒
    if (self.totalTime == 0) {
        self.totalTime = 10;
    }
    
    
    [self.captureSession startRunning];
    
    
    
    UIView *view = [[UIView alloc]init];
    [self.view addSubview:view];
    view.backgroundColor = [UIColor redColor];
    
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.equalTo(self.view);
        
    }];
    
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    
}

#pragma mark -Delegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    
    NSLog(@"........开始播放");
    [self settupTimer];
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    NSLog(@"........完成录制");
    [self.urlArray addObject:outputFileURL];
    
    NSLog(@"..:%@", self.urlArray);
    
    //时间到了
    if (currentTime >= self.totalTime) {
        [self mergeAndExportVideosAtFileURLs:self.urlArray];
    }
}



#pragma mark -EventMethod
- (IBAction)tapeVideo:(UIButton *)sender {
    
    NSLog(@"......");
    
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording]) { // 如果没有再录制视频
//        shootBt.backgroundColor = UIColorFromRGB(0xfa5f66);
        
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        
        // 往路径的 URL 开始写入录像 Buffer ,边录边写
        [self.captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self getVideoSaveFilePathString]] recordingDelegate:self];
        
    } else {
        
        [self removeTimer];
        [self.captureMovieFileOutput stopRecording];//停止录制
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -PrivateMethod
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

- (void)settupTimer {
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [_timer fire];
    
}

- (void)onTimer:(NSTimer *)timer
{
    currentTime += TIMER_INTERVAL;
//    float progressWidth = progressPreView.frame.size.width+progressStep;
//    [progressPreView setFrame:CGRectMake(0, preLayerHeight, progressWidth, 4)];
    
    if (currentTime>2) {
//        finishBt.hidden = NO;
    }
    
    NSLog(@"..录制了:%f", currentTime);
    
    //时间到了停止录制视频（当前设置的是10秒）
    if (currentTime >= self.totalTime) {
        NSLog(@"..录制时间完毕");
        [self removeTimer];
        [self.captureMovieFileOutput stopRecording];
    }
}

- (void)removeTimer {
    
    [_timer invalidate];
    _timer = nil;
}

//最后合成为 mp4
- (NSString *)getVideoMergeFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSLog(@"...path:%@", path);
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"merge.mp4"];
    
    return fileName;
}

//录制保存的时候要保存为 mov
- (NSString *)getVideoSaveFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mov"];
    
    return fileName;
}

- (void)createVideoFolderIfNotExist
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建保存视频文件夹失败");
        }
    }
    
    NSString *path1 = folderPath; // 要列出来的目录
    
    NSFileManager *myFileManager=[NSFileManager defaultManager];
    
    NSDirectoryEnumerator *myDirectoryEnumerator;
    
    myDirectoryEnumerator=[myFileManager enumeratorAtPath:path1];
    
    //列举目录内容，可以遍历子目录
    
    NSLog(@"用enumeratorAtPath:显示目录%@的内容：", path1);
    
    while((path1 = [myDirectoryEnumerator nextObject])!=nil)
        
    {
        
        NSLog(@"%@",path1);
        
    }
    NSLog(@"......");
}

- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray
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
            
            PlayVideoViewController* view = [[PlayVideoViewController alloc]init];
            view.videoURL =mergeFileURL;
            [self.navigationController pushViewController:view animated:YES];
            
        });
    }];
}


#pragma mark -Getter
- (AVCaptureSession *)captureSession {
    
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc]init];
    }
    return _captureSession;
}

- (AVCaptureDeviceInput *)captureDeviceInput {
    
    // 获取视频输入设备（后摄像头）
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    
    if (!_captureDeviceInput) {
        _captureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:nil];
    }
    return _captureDeviceInput;
}

- (AVCaptureDeviceInput *)audioCaptureDeviceInput {
    
    // 添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    if (!_audioCaptureDeviceInput) {
        _audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:nil];
    }
    
    return _audioCaptureDeviceInput;
}

- (AVCaptureMovieFileOutput *)captureMovieFileOutput {
    
    //初始化设备输出对象，用于获得输出数据
    if (!_captureMovieFileOutput) {
        _captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];
    }
    return _captureMovieFileOutput;
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    
    if (!_captureVideoPreviewLayer) {
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    }
    return _captureVideoPreviewLayer;
}

- (NSMutableArray *)urlArray {
    if (!_urlArray) {
        _urlArray = [NSMutableArray array];
    }
    return _urlArray;
}

@end