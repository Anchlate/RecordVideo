//
//  ViewController.m
//  RecordVideo
//
//  Created by Qianrun on 16/6/2.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "ViewController.h"
#import "BPClearCach.h"
#import "QRPlayView.h"
#import "Masonry.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(noti:) name:@"video" object:nil];
    
}

- (void)noti:(NSNotification *)noti {
    
    NSDictionary *userInfo = noti.userInfo;
    NSLog(@"......:%@", userInfo);
    
    QRPlayView *videoPlay = [[QRPlayView alloc]initWithFrame:[UIScreen mainScreen].bounds videoURL:[userInfo objectForKey:@"url"]];
    
    [self.view addSubview:videoPlay];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
