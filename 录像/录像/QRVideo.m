//
//  QRVideo.m
//  录像
//
//  Created by Qianrun on 16/5/30.
//  Copyright © 2016年 Qianrun. All rights reserved.
//

#import "QRVideo.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

static UIViewController *controller;
static id delegate;
static NSData *videoData;

@interface QRVideo ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation QRVideo

/*
+ (void)videoImagePickerControllerSourceType:(UIImagePickerControllerSourceType)sourceType controller:(UIViewController *)controller usingDelegate:(id<UIImagePickerControllerDelegate,UINavigationControllerDelegate>)delegate block:(void (^)(NSData *))block {
    
    [self startCameraControllerFromViewController:controller usingDelegate:delegate imagePickerControllerSourceType:sourceType];
    
    
    
    
    
}

+ (void) startCameraControllerFromViewController: (UIViewController*) controller
                                   usingDelegate: (id <UIImagePickerControllerDelegate,
                                                   UINavigationControllerDelegate>) delegate
                 imagePickerControllerSourceType:(UIImagePickerControllerSourceType)sourceType
{
    
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil))
        return;
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    //    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    cameraUI.sourceType = sourceType;
    
    // Displays a control that allows the user to choose picture or
    // movie capture, if both are available:
    //    cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:
    //                           UIImagePickerControllerSourceTypeCamera];
    cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    
    cameraUI.mediaTypes = @[(__bridge NSString*)kUTTypeMovie];
    
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = YES;
    
    cameraUI.delegate = delegate;
    
    [controller presentViewController:cameraUI animated:YES completion:nil];
}
*/





@end