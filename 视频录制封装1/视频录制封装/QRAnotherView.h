//
//  QRAnotherView.h
//  视频录制封装
//
//  Created by Qianrun on 16/6/1.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+Tools.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]




@interface QRAnotherView : UIView

@property float totalTime; //视频总长度 默认10秒

@end
