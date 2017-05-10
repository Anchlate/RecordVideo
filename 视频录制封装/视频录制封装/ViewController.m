//
//  ViewController.m
//  视频录制封装
//
//  Created by Qianrun on 16/5/31.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "ViewController.h"
#import "QRVideoView.h"
#import "MyView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    QRVideoView *viewww = [[[NSBundle mainBundle]loadNibNamed:@"QRVideoView" owner:nil options:nil] lastObject];
//    viewww.frame = self.view.bounds;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    viewww.videoDirectoryPath = [paths objectAtIndex:0];
    [self.view addSubview:viewww];
    
    
    //    MyView *myView = [[MyView alloc]initWithFrame:self.view.bounds];
    //    [self.view addSubview:myView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
