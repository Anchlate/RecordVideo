//
//  QRAnotherView.h
//  视频录制封装
//
//  Created by Qianrun on 16/6/1.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ANVideoViewPermission) {
    
    ANVideoViewPermissionCamera = 1 << 1,
    ANVideoViewPermissionMicroPhone = 1 << 2
    
};


@class QRVideoView;

@protocol QRVideoViewDelegate <NSObject>


- (void)goBack;

@optional
- (void)videoView:(QRVideoView *)videoView didfinishRecordingVideoURL:(NSURL *)videoURL;
- (void)videoView:(QRVideoView *)videoView didfinishRecordingVideo:(NSData *)videoData;
- (void)cameraAndMicroPhonePermission:(ANVideoViewPermission)permission;

@end

@interface QRVideoView : UIView

@property (nonatomic, strong) UIColor *progressViewColor; // 进度条颜色，默认为(0xffc738)
@property (nonatomic, copy, readonly) NSString *videoDirectoryPath; // 视频所在文件夹路径，只读
@property (nonatomic, strong) UIColor *recordBtnOutCircleColor;//0xeeeeee
@property (nonatomic, strong) UIColor *recordBtnBackGroundColor;//0xfa5f66
@property (nonatomic, strong) UIColor *recordBtnBorderColor;// 0x28292b
@property (nonatomic, assign) CGFloat recordBtnBorderWidth; // 3
@property (nonatomic, assign, readonly) BOOL isAuthorizationed; // 是否已经授权



@property (nonatomic, assign) id<QRVideoViewDelegate> delegate;

// 默认录制时长为10秒，如果传入totalTime的值小于或等于0，则为默认值10; videoDirectoryPath是视频的存放地址，默认存放在document下
//- (id)initWithFrame:(CGRect)frame totalTime:(float)totalTime videoDirectoryPath:(NSString *)videoDirectoryPath;
- (id)initWithFrame:(CGRect)frame totalTime:(int)totalTime videoDirectoryPath:(NSString *)videoDirectoryPath;


@end