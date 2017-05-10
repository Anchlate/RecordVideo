//
//  QRPlayView.h
//  视频录制封装
//
//  Created by Anchlate Lee on 16/5/31.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QRPlayView;

@protocol QRPlayViewDelegate <NSObject>

@optional
- (void)goBack;

@end

@interface QRPlayView : UIView

@property (nonatomic, assign) id<QRPlayViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL;

@end
