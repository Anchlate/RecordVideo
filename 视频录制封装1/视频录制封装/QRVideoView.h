//
//  MyView.h
//  视频录制封装
//
//  Created by Qianrun on 16/5/31.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@class QRVideoView;

@protocol QRVideoViewDelegate <NSObject>

- (void)videoView:(QRVideoView *)videoView didfinishRecordingVideo:(NSURL *)videoURL;

@end


@interface QRVideoView : UIView

@property (nonatomic, strong) UIColor *progressViewColor; // 进度条颜色，默认为(0xffc738)
@property (nonatomic, copy, readonly) NSString *videoDirectoryPath; // 视频所在文件夹路径，只读
@property (nonatomic, strong) UIColor *recordBtnBorderColor;
@property (nonatomic, strong) UIColor *recordBtnBackGroundColor;
@property (nonatomic, assign) CGFloat recordBtnBorderWidth;

@property (nonatomic, assign) id<QRVideoViewDelegate> delegate;

// 默认录制时长为10秒，如果传入totalTime的值小于或等于0，则为默认值10; videoDirectoryPath是视频的存放地址，默认存放在document下
- (id)initWithFrame:(CGRect)frame totalTime:(float)totalTime videoDirectoryPath:(NSString *)videoDirectoryPath;

@end
