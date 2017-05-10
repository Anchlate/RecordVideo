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
    
    UIImageView* playImg;
    
}

@property (nonatomic, strong) NSURL *videoURL;


@end

@implementation QRPlayView

- (id)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL {
    
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor blackColor];
        
        float videoWidth = frame.size.width;
        float videoHeight = frame.size.height;
        
        AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        player = [AVPlayer playerWithPlayerItem:playerItem];
        
        playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        playerLayer.frame = CGRectMake(0, 0, videoWidth, videoHeight);
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.layer addSublayer:playerLayer];
        
        UITapGestureRecognizer *playTap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playOrPause)];
        [self addGestureRecognizer:playTap];
        
        [self pressPlayButton];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        playImg = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
        playImg.center = CGPointMake(videoWidth/2, videoWidth/2);
        [playImg setImage:[UIImage imageNamed:@"videoPlay"]];
        [playerLayer addSublayer:playImg.layer];
        playImg.hidden = YES;
        
    }
    return self;
}

-(void)playOrPause{
    if (playImg.isHidden) {
        playImg.hidden = NO;
        [player pause];
        
    }else{
        playImg.hidden = YES;
        [player play];
    }
}

- (void)pressPlayButton
{
    [playerItem seekToTime:kCMTimeZero];
    [player play];
}

- (void)playingEnd:(NSNotification *)notification
{
    if (playImg.isHidden) {
        [self pressPlayButton];
    }
}

@end
