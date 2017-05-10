//
//  QRVideoView.h
//  视频录制封装
//
//  Created by Qianrun on 16/5/31.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import <UIKit/UIKit.h>

#define QR_SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define QR_SCREENHEIGHT [UIScreen mainScreen].bounds.size.height

#define QR_UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface QRVideoView : UIView

@property (nonatomic, copy) NSString *videoDirectoryPath;

@end
