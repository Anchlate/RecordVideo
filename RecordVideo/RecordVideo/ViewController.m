//
//  ViewController.m
//  RecordVideo
//
//  Created by Qianrun on 16/6/2.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "ViewController.h"
#import "QRVideoView.h"
#import "BPClearCach.h"

@interface ViewController ()<QRVideoViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    QRVideoView *vie = [[QRVideoView alloc]initWithFrame:self.view.bounds totalTime:3 videoDirectoryPath:nil];
    vie.delegate = self;
    [self.view addSubview:vie];
    
}

- (void)videoView:(QRVideoView *)videoView didfinishRecordingVideo:(NSURL *)videoURL {
    
    NSLog(@"视频的URL:%@", videoURL);
    NSLog(@"视频存放路劲：%@", videoView.videoDirectoryPath);
    float size = [BPClearCach cachSizeAtPath:[videoURL path]];
    NSLog(@"./....压缩后的大小为:%f", size);
    
    
     NSString *path1 = [[videoURL path]stringByDeletingLastPathComponent];
     
     NSFileManager *myFileManager=[NSFileManager defaultManager];
     
     NSDirectoryEnumerator *myDirectoryEnumerator;
     
     myDirectoryEnumerator=[myFileManager enumeratorAtPath:path1];
     
     //列举目录内容，可以遍历子目录
     
     NSLog(@"用enumeratorAtPath:显示目录%@的内容：", path1);
     
     while((path1 = [myDirectoryEnumerator nextObject])!=nil)
     {
     
     NSLog(@"%@",path1);
     
     }
     
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
