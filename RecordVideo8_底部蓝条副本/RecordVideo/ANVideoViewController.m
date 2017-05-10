//
//  QRVideoViewController.m
//  RecordVideo
//
//  Created by Qianrun on 16/6/21.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "ANVideoViewController.h"
#import "QRVideoView.h"
#import "Masonry.h"


#define WEAKSELF(weakSelf) __weak __typeof(&*self)weakSelf = self


@interface ANVideoViewController ()<QRVideoViewDelegate>

@property (nonatomic, strong) QRVideoView *videoView;

@end

@implementation ANVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect tmpRect = self.view.bounds;
    tmpRect.origin.y = 20;
    tmpRect.size.height = tmpRect.size.height - 20;
    
    self.videoView = [[QRVideoView alloc]initWithFrame:tmpRect totalTime:30 videoDirectoryPath:nil];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.videoView.delegate = self;
    [self.view addSubview:self.videoView];
    
    [self.view addSubview:self.videoView];
    
    [self layoutViews];
    
}

- (void)layoutViews {
    
    WEAKSELF(weakSelf);
    
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf.view);
    }];
    
}

#pragma mark -Delegate
#pragma mark -QRVideoViewDelegate
- (void)goBack {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)videoView:(QRVideoView *)videoView didfinishRecordingVideoURL:(NSURL *)videoURL {
    
    NSDictionary *usrInfo = @{@"url" : videoURL};
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"video" object:nil userInfo:usrInfo];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}








- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end