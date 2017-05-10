//
//  ViewController.m
//  视频录制封装
//
//  Created by Qianrun on 16/5/31.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "ViewController.h"
#import "QRVideoView.h"
#import "QRVideoView.h"
#import "BPClearCach.h"
#import "QRAnotherView.h"


@interface ViewController ()<QRVideoViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
//    QRVideoView *viewww = [[[NSBundle mainBundle]loadNibNamed:@"QRVideoView" owner:nil options:nil] lastObject];
////    viewww.frame = self.view.bounds;
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    viewww.videoDirectoryPath = [paths objectAtIndex:0];
//    [self.view addSubview:viewww];
    
    
//    QRVideoView *myView = [[QRVideoView alloc]initWithFrame:self.view.bounds totalTime:10 videoDirectoryPath:nil];
//    myView.backgroundColor = UIColorFromRGB(0x1d1e20);
//    myView.delegate = self;
//    [self.view addSubview:myView];
    
    
    QRAnotherView *vie = [[QRAnotherView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:vie];
}

- (void)videoView:(QRVideoView *)videoView didfinishRecordingVideo:(NSURL *)videoURL {
    
    NSLog(@"videourl:%@", videoURL);
    float size = [BPClearCach cachSizeAtPath:[videoURL path]];
    NSLog(@"....压缩后的大小:%f", size);
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
