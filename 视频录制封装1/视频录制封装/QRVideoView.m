
//
//  MyView.m
//  视频录制封装
//
//  Created by Qianrun on 16/5/31.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "QRVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "QRPlayView.h"


#define TIMER_INTERVAL 0.05

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface QRVideoView ()<AVCaptureFileOutputRecordingDelegate>
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

@property (strong,nonatomic)  UIView *viewContainer;//视频容器
@property float totalTime; //视频总长度 默认10秒
@property (nonatomic, strong) UIButton *recordBtn;

@property (nonatomic, strong) UIView *progressPreView; //进度条
@property (nonatomic, assign) float progressStep; //进度条每次变长的最小单位
@property (nonatomic, strong) UIImageView *videoImageView;
@property (nonatomic, copy) NSString *videoPath; // 视频路径
@property (nonatomic, strong) UIButton *cameraBtn; //切换摄像头


@end

@implementation QRVideoView

- (id)initWithFrame:(CGRect)frame totalTime:(float)totalTime videoDirectoryPath:(NSString *)videoDirectoryPath{
    
    if (self = [super initWithFrame:frame]) {
        
        //视频最大时长 默认10秒
        self.totalTime = totalTime;
        
        if (self.totalTime <= 0) {
            self.totalTime = 10;
        }
        
        preLayerWidth = SCREEN_WIDTH;
        preLayerHeight = SCREEN_WIDTH - 100;
        preLayerHWRate = preLayerHeight/preLayerWidth;
        self.progressStep = SCREEN_WIDTH * TIMER_INTERVAL / self.totalTime;
        
        self.backgroundColor = [UIColor blackColor];
        
        // 判断是否存在videoDirectoryPath这个文件夹
        if (videoDirectoryPath && [self isPathExit:videoDirectoryPath]) {
            
            _videoDirectoryPath = videoDirectoryPath;
            
        } else { // 如果不存在视频的默认存储位置为document下
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *path = [paths objectAtIndex:0];
            _videoDirectoryPath = path;
        }
        
        _videoPath = nil;
        
        
        /******
        NSString *path1 = _videoDirectoryPath;
        
        NSFileManager *myFileManager=[NSFileManager defaultManager];
        
        NSDirectoryEnumerator *myDirectoryEnumerator;
        
        myDirectoryEnumerator=[myFileManager enumeratorAtPath:path1];
        
        //列举目录内容，可以遍历子目录
        
        NSLog(@"用enumeratorAtPath:显示目录%@的内容：", path1);
        
        while((path1 = [myDirectoryEnumerator nextObject])!=nil)
        {
            
            NSLog(@"%@",path1);
            
        }
         */
        
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
        
        // viewContainer
        self.viewContainer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height - 100);
        [self addSubview:self.viewContainer];
        
        CALayer *layer= self.viewContainer.layer;
        layer.masksToBounds=YES;
        
        // recordBtn
        self.recordBtn.frame = CGRectMake(0, 0, 80, 80);
        self.recordBtn.center = CGPointMake(self.viewContainer.center.x, CGRectGetMaxY(self.viewContainer.frame) + 50);
        self.recordBtn.layer.cornerRadius = 40;
        
        [self addSubview:self.recordBtn];
        
        // captureVideoPreviewLayer
        self.captureVideoPreviewLayer.frame=  CGRectMake(0, 0, preLayerWidth, CGRectGetHeight(self.viewContainer.frame) - 4);
        self.captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
        [layer addSublayer:self.captureVideoPreviewLayer];
        
        // progressPreView
        self.progressPreView.frame = CGRectMake(0, CGRectGetHeight(self.viewContainer.frame) - 4, 0, 4);
        [self.viewContainer addSubview:self.progressPreView];
        
        // videoImageView
        self.videoImageView.frame = self.captureVideoPreviewLayer.bounds;
        [self.viewContainer addSubview:self.videoImageView];
        
        // cameraBtn
        self.cameraBtn.center = CGPointMake(self.recordBtn.center.x / 2, self.recordBtn.center.y);
        [self addSubview:self.cameraBtn];
        
        [self.captureSession startRunning];
    }
    return self;
}

#pragma mark -delegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"........开始播放");
    [self settupTimer];
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    [self.urlArray addObject:outputFileURL];
    
    self.videoImageView.image = [self getVideoImageWithVideoURL:outputFileURL];
    
    //时间到了
    if (currentTime >= self.totalTime) {
        
        currentTime = 0;
        self.progressPreView.frame = CGRectMake(0, CGRectGetMaxY(self.viewContainer.frame) - 4, 0, 4);
        
        [self mergeAndExportVideosAtFileURLs:self.urlArray outputFileURL:outputFileURL];
        
    }
}

#pragma mark -event
- (void)buttonClick:(UIButton *)button {
    
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording]) { // 如果没有再录制视频
        
        self.recordBtn.backgroundColor = UIColorFromRGB(0xfa5f66);
        self.videoImageView.image = nil;
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        
        // 往路径的 URL 开始写入录像 Buffer ,边录边写
        [self.captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self getVideoSaveFilePathString]] recordingDelegate:self];
        
    } else {
        
        [self removeTimer];
        [self.captureMovieFileOutput stopRecording];//停止录制
    }
}

- (void)changeCameraAction:(UIButton *)button {
    
    NSLog(@"改变前后摄像头");
    
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

#pragma mark -Private
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
    
    self.recordBtn.backgroundColor = UIColorFromRGB(0xf8ad6a);
    self.videoImageView.hidden = YES;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [_timer fire];
    
}

- (void)onTimer:(NSTimer *)timer
{
    currentTime += TIMER_INTERVAL;
    float progressWidth = self.progressPreView.frame.size.width+self.progressStep;
    [self.progressPreView setFrame:CGRectMake(0, CGRectGetMaxY(self.viewContainer.frame) - 4, progressWidth, 4)];
    
    if (currentTime>2) {
        //        finishBt.hidden = NO;
    }
    
    //时间到了停止录制视频（当前设置的是10秒）
    if (currentTime >= self.totalTime) {
        NSLog(@"..录制时间完毕");
        [self removeTimer];
        [self.captureMovieFileOutput stopRecording];
    }
}

- (void)removeTimer {
    
    self.recordBtn.backgroundColor = UIColorFromRGB(0xfa5f66);
//    self.videoImageView.image = nil;
    self.videoImageView.hidden = NO;
    
    [_timer invalidate];
    _timer = nil;
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

/*
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
    
}
*/

- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray outputFileURL:(NSURL *)outputFielURL
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
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtURL:outputFielURL error:nil];
            
            if ([self.delegate respondsToSelector:@selector(videoView:didfinishRecordingVideo:)]) {
                [self.delegate videoView:self didfinishRecordingVideo:mergeFileURL];
            }
            
        });
    }];
}

//最后合成为 mp4
- (NSString *)getVideoMergeFilePathString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[_videoDirectoryPath stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"merge.mp4"];
    
    return fileName;
}

//录制保存的时候要保存为 mov
- (NSString *)getVideoSaveFilePathString
{
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    */
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[_videoDirectoryPath stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mov"];
    
    return fileName;
}

- (UIImage *)getVideoImageWithVideoURL:(NSURL *)videoURL
{
    AVURLAsset *asset = [[AVURLAsset alloc]initWithURL:videoURL options:nil];
//    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    return thumb;
}

/*
// 压缩视频
- (void)compressVideo:(NSURL *)saveUrl
{
    // 通过文件的 url 获取到这个文件的资源
    AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:saveUrl options:nil];
    // 用 AVAssetExportSession 这个类来导出资源中的属性
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    // 压缩视频 AVAssetExportPresetLowQuality
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) { // 导出属性是否包含低分辨率
        // 通过资源（AVURLAsset）来定义 AVAssetExportSession，得到资源属性来重新打包资源 （AVURLAsset, 将某一些属性重新定义
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetLowQuality];
        // 设置导出文件的存放路径
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        NSDate    *date = [[NSDate alloc] init];
        NSString *outPutPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"output-%@.mp4",[formatter stringFromDate:date]]];
        exportSession.outputURL = [NSURL fileURLWithPath:outPutPath];
        
        // 是否对网络进行优化
        exportSession.shouldOptimizeForNetworkUse = true;
        
        // 转换成MP4格式
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        // 开始导出,导出后执行完成的block
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            // 如果导出的状态为完成
            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 更新一下显示包的大小
//                    self.videoSize.text = [NSString stringWithFormat:@"%f MB",[self getfileSize:outPutPath]];
                    
//                    + (float)cachSizeAtPath:(NSString *)folderPath;
                    
                    float size = [BPClearCach cachSizeAtPath:outPutPath];
                    NSLog(@"...outdd:%@", outPutPath);
                    NSLog(@"....压缩后的大小:%f", size);
                    
                    
                });
            }
        }];
    }
}
*/

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



#pragma mark -Setter
- (void)setProgressViewColor:(UIColor *)progressViewColor {
    
    _progressViewColor = progressViewColor;
    self.progressPreView.backgroundColor = progressViewColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    
    [super setBackgroundColor:backgroundColor];
    self.viewContainer.backgroundColor = backgroundColor;
}

- (void)setRecordBtnBorderColor:(UIColor *)recordBtnBorderColor {
    
    self.recordBtn.layer.borderColor = recordBtnBorderColor.CGColor;
}

- (void)setRecordBtnBorderWidth:(CGFloat)recordBtnBorderWidth {
    self.recordBtn.layer.borderWidth = recordBtnBorderWidth;
}

- (void)setRecordBtnBackGroundColor:(UIColor *)recordBtnBackGroundColor {
    self.recordBtn.backgroundColor = recordBtnBackGroundColor;
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

- (UIView *)viewContainer {
    if (!_viewContainer) {
        _viewContainer = [[UIView alloc]init];
    }
    return _viewContainer;
}

- (UIButton *)recordBtn {
    if (!_recordBtn) {
        
        _recordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _recordBtn.backgroundColor = UIColorFromRGB(0xf8ad6a);;
        _recordBtn.layer.borderColor = UIColorFromRGB(0x28292b).CGColor;
        _recordBtn.layer.borderWidth = 3;
        
        [_recordBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        _recordBtn.clipsToBounds = YES;
    }
    return _recordBtn;
}

- (UIButton *)cameraBtn {
    if (!_cameraBtn) {
        
        _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraBtn addTarget:self action:@selector(changeCameraAction:) forControlEvents:UIControlEventTouchUpInside];
        [_cameraBtn setBackgroundImage:[UIImage imageNamed:@"changeCamer"] forState:UIControlStateNormal];
        _cameraBtn.frame = CGRectMake(0, 0, 67, 67);
    }
    return _cameraBtn;
}

- (UIView *)progressPreView {
    if (!_progressPreView) {
        _progressPreView = [[UIView alloc]init];
        _progressPreView.backgroundColor = UIColorFromRGB(0xffc738);
        _progressPreView.layer.cornerRadius = 2;
    }
    return _progressPreView;
}

- (UIImageView *)videoImageView {
    
    if (!_videoImageView) {
        _videoImageView = [[UIImageView alloc]init];
        _videoImageView.contentMode = UIViewContentModeScaleAspectFill;
        _videoImageView.backgroundColor = [UIColor clearColor];
        _videoImageView.hidden = YES;
    }
    return _videoImageView;
}

@end