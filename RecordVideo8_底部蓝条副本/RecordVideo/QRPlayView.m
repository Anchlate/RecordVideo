//
//  QRPlayView.m
//  视频录制封装
//
//  Created by Anchlate Lee on 16/5/31.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "QRPlayView.h"
//#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface QRPlayView ()<UITextFieldDelegate>
{
    
    AVPlayer *player;
    AVPlayerLayer *playerLayer;
    AVPlayerItem *playerItem;
    UIView *panView;
    
    
    BOOL _isPlaying;
    NSTimer *_timer;
    
    float _duration;
    float _currentTime;
}

@property (nonatomic, strong) UIView *navView;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *controlView;

@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UILabel *currenTimeLabel;
@property (nonatomic, strong) UILabel *surplusTimeLabel;
@property (nonatomic, strong) UISlider *slider;


@end

@implementation QRPlayView

- (id)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL {
    
    if (self = [super initWithFrame:frame]) {
        
        _isPlaying = YES;
        
        player = nil;
        playerLayer = nil;
        playerItem = nil;
//        playImg = nil;
        
        self.backgroundColor = [UIColor blackColor];
        
        // navView
        [self addSubview:self.navView];
        self.navView.frame = CGRectMake(0, 20, frame.size.width, 44);
        
        // backBtn
        [self.navView addSubview:self.backBtn];
        self.backBtn.frame = CGRectMake(0, 0, 44, 44);
        
        // titleLabel
        [self.navView insertSubview:self.titleLabel belowSubview:self.backBtn];
        self.titleLabel.frame = self.navView.bounds;
        
        //
        float videoWidth = frame.size.width;
        float videoHeight = CGRectGetMaxY(self.navView.frame) + (frame.size.height - 64) * (564.0 / 1334);
        
        AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        player = [AVPlayer playerWithPlayerItem:playerItem];
        
        float y = (128.0 / 1334) * (frame.size.height - 64) + CGRectGetMaxY(self.navView.frame);
        
        playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        playerLayer.frame = CGRectMake(0, y, videoWidth, videoHeight);
        playerLayer.videoGravity = AVLayerVideoGravityResize;//AVLayerVideoGravityResizeAspectFill;//AVLayerVideoGravityResizeAspect;AVLayerVideoGravityResize
        [self.layer addSublayer:playerLayer];
        
        [self pressPlayButton];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        // panView
        panView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(playerLayer.frame) - 4, CGRectGetWidth(playerLayer.frame), 4)];
        panView.backgroundColor = self.backgroundColor;
        [self addSubview:panView];
        panView.hidden = YES;
        
        
        y = CGRectGetMaxY(playerLayer.frame) + 368.0 / 1334 * (frame.size.height - 64);
        
        self.controlView.frame = CGRectMake(0, y, frame.size.width, 44);
        [self addSubview:self.controlView];
        
        // playBtn
        float x = 30.0 / 750 * frame.size.width;
        self.playBtn.frame = CGRectMake(x, 0, 44, 44);
        [self.controlView addSubview:_playBtn];
        
        // currentTimeLabel
        
        CGSize size = [self.currenTimeLabel.text sizeWithAttributes:@{NSFontAttributeName : self.currenTimeLabel.font}];
        self.currenTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.playBtn.frame) + 18 - 5, 0, size.width + 5, 44);
        [self.controlView addSubview:self.currenTimeLabel];
        
        size = [self.surplusTimeLabel.text sizeWithAttributes:@{NSFontAttributeName : self.surplusTimeLabel.font}];
        self.surplusTimeLabel.frame = CGRectMake(frame.size.width - size.width - x - 5, 0, size.width + 5, 44);
        [self.controlView addSubview:self.surplusTimeLabel];
        
        // slider
        self.slider.frame = CGRectMake(CGRectGetMaxX(self.currenTimeLabel.frame) + 12, 0, frame.size.width - (CGRectGetMaxX(self.currenTimeLabel.frame) + 12 * 2) - size.width - x, 44);
        [self.controlView addSubview:self.slider];
        
        [self startTimer];
        
        CMTime duration = player.currentItem.asset.duration;
        _duration = CMTimeGetSeconds(duration);
        self.slider.maximumValue = _duration;
        
        [self setSurplusTimeLabelText:(int)_duration];

    }
    return self;
}

- (void)pressPlayButton
{
    [playerItem seekToTime:kCMTimeZero];
    [player play];
//    [self startTimer];
}

- (void)playingEnd:(NSNotification *)notification
{
    if (_isPlaying) {
        
        [self stopTimer];
        _isPlaying = NO;
        self.playBtn.selected = !_isPlaying;
        [playerItem seekToTime:kCMTimeZero];
        
        self.slider.value = self.slider.maximumValue;
//        [self setSurplusTimeLabelText:0];
//        [self setCurrentTimeLabelText:(int)_duration];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            self.slider.value = self.slider.minimumValue;
        });
        
        [self setSurplusTimeLabelText:_duration];
        [self setCurrentTimeLabelText:0];
        self.slider.value = self.slider.minimumValue;
    }
}

#pragma mark -Event
- (void)backBtnAction:(UIButton *)button {
    
    [player pause];
    [self removeFromSuperview];
    if ([self.delegate respondsToSelector:@selector(goBack)]) {
        [self.delegate goBack];
    }
    
}

- (void)playBtnAciton:(UIButton *)button {
    
    
    if (_isPlaying) {
        
        [player pause];
        [self stopTimer];
        _isPlaying = NO;
//        [self.playBtn setImage:[UIImage imageNamed:@"stopVideo"] forState:UIControlStateNormal];
        
    }else{
        
        
        [player play];
        [self startTimer];
        _isPlaying = YES;
//        [self.playBtn setImage:[UIImage imageNamed:@"playVideo"] forState:UIControlStateNormal];
    }
    
    self.playBtn.selected = !_isPlaying;
}

//- (void)touchExit:(UISlider *)slider {
//    NSLog(@"......end drag slider");

//    CMTime duration = player.currentItem.asset.duration;
//    float seconds = CMTimeGetSeconds(duration);
//    _duration = (int)seconds;
//    CMTime time =player.currentItem.asset.duration;
//    [player seekToTime:CMTimeMake(slider.value, time.timescale)];
    
//}

- (void)touchDown:(UISlider *)slider {
    NSLog(@"......touchDown");
    
    [player pause];
    _isPlaying = NO;
    self.playBtn.selected = YES;
    [self stopTimer];
    
}

- (void)valueChange:(UISlider *)slider {
    NSLog(@"......valueChange:%f", slider.value);
    
    [self setCurrentTimeLabelText:(int)roundf(slider.value)];
    [self setSurplusTimeLabelText:(int)roundf(_duration - slider.value)];
    [player seekToTime:CMTimeMake(slider.value, 1)];    
}

- (void)touchEnd:(UISlider *)slider {
    
    NSLog(@"......touchEnd:%f", slider.value);
    
    [self setCurrentTimeLabelText:(int)roundf(slider.value)];
    [self setSurplusTimeLabelText:(int)roundf(_duration - slider.value)];
    
    //    CMTime time =player.currentTime;
    //
    //    CMTimeGetSeconds(time);
    //
    //    NSLog(@"......changeBefore:%.2f", CMTimeGetSeconds(time));
    //
    ////    time.value = slider.value;
    //    NSLog(@"......slider:%.2f", slider.value);
    //    NSLog(@"......changeAfter:%d", time.timescale);
    
    
    [player seekToTime:CMTimeMake(slider.value, 1)];
    [player play];
    
    _isPlaying = YES;
    self.playBtn.selected = NO;
    
    [self startTimer];
    
}

#pragma mark -Private
- (NSString *)timeStringFromSeconds:(int)seconds {
    
    NSString *minuteStr = nil;
    NSString *secondStr = nil;
    
    int minute = seconds / 60;
    int second = seconds % 60;
    
    if (minute < 10) {
        
        minuteStr = [NSString stringWithFormat:@"0%d", minute];
        
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

-(void)startTimer{
    NSLog(@"......startTimer");
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [_timer fire];
    
}

-(void)stopTimer{
    NSLog(@"......stopTimer");
    [_timer invalidate];
    _timer = nil;
    
}

- (void)onTimer:(NSTimer *)timer
{
    /*
//    currentTime += TIMER_INTERVAL;
//    float progressWidth = progressPreView.frame.size.width+progressStep;
//    [progressPreView setFrame:CGRectMake(0, 0, progressWidth, 3)];
//    
//    [self setCurrentTimeLabelText:currentTime];
//    [self setSurplusTimeLabelText:(self.totalTime - currentTime)];
//    
//    //时间到了停止录制视频（当前设置的是10秒）
//    if (currentTime>=self.totalTime) {
//        [countTimer invalidate];
//        countTimer = nil;
//        [_captureMovieFileOutput stopRecording];
//    }
    */
    CMTime duration = player.currentTime;
    float seconds = CMTimeGetSeconds(duration);
    
    NSLog(@"begin running time float:%.2f", seconds);
    NSLog(@"..:%d", (int)seconds);
    NSLog(@"_currentTime:%d", (int)(_duration - seconds));
    
    [self setCurrentTimeLabelText:(int)roundf(seconds)];
    [self setSurplusTimeLabelText:(int)roundf(_duration - seconds)];
    
    self.slider.value = seconds;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    panView.backgroundColor = backgroundColor;
}


#pragma mark -Getter
- (UIView *)navView {
    if (!_navView) {
        _navView = [[UIView alloc]init];
        _navView.backgroundColor = [UIColor blackColor];
    }
    return _navView;
}

- (UIButton *)backBtn {
    
    if (!_backBtn) {
        
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"closeVideo"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
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

- (UIView *)controlView {
    if (!_controlView) {
        _controlView = [[UIView alloc]init];
        _controlView.backgroundColor = [UIColor clearColor];
    }
    return _controlView;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"playVideo"] forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage imageNamed:@"stopVideo"] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(playBtnAciton:) forControlEvents:UIControlEventTouchUpInside];
        _playBtn.selected = NO;
    }
    return _playBtn;
}

- (UILabel *)currenTimeLabel {
    
    if (!_currenTimeLabel) {
        _currenTimeLabel = [[UILabel alloc]init];
        _currenTimeLabel.font = [UIFont systemFontOfSize:12];
        _currenTimeLabel.textColor = [UIColor whiteColor];
        _currenTimeLabel.text = @"00:00";
        _currenTimeLabel.textAlignment = NSTextAlignmentRight;
        _currenTimeLabel.backgroundColor = [UIColor clearColor];
//        _currenTimeLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _currenTimeLabel;
}

- (UILabel *)surplusTimeLabel {
    
    if (!_surplusTimeLabel) {
        _surplusTimeLabel = [[UILabel alloc]init];
        _surplusTimeLabel.font = [UIFont systemFontOfSize:12];
        _surplusTimeLabel.textColor = [UIColor whiteColor];
        _surplusTimeLabel.text = @"-00:00";
        _surplusTimeLabel.textAlignment = NSTextAlignmentLeft;
        _surplusTimeLabel.backgroundColor = [UIColor clearColor];
//        _surplusTimeLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _surplusTimeLabel;
}

- (UISlider *)slider {
    
    if (!_slider) {
        _slider = [[UISlider alloc]init];
        _slider.minimumValue = 0;
        [_slider addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
        [_slider addTarget:self action:@selector(touchEnd:) forControlEvents:UIControlEventTouchUpInside];
        [_slider addTarget:self action:@selector(touchEnd:) forControlEvents:UIControlEventTouchUpOutside];
        [_slider addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}

@end