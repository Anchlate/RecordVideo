//
//  QRVideo.h
//  录像
//
//  Created by Qianrun on 16/5/30.
//  Copyright © 2016年 Qianrun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QRVideo : NSObject

/*
+ (void)videoImagePickerControllerSourceType:(UIImagePickerControllerSourceType)sourceType controller:(UIViewController *)controller usingDelegate: (id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate block:(void(^)(NSData *videoData))block;
*/

- (id)initWithMaxTime:(NSUInteger)maxTime;





@end
