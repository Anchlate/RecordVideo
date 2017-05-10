//
//  BPClearCach.h
//  YunKang
//
//  Created by PENG BAI on 15/8/7.
//  Copyright (c) 2015年 bp1010. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BPClearCach : NSObject

+ (float)cachSizeAtPath:(NSString *)folderPath;
+ (void)clearCachesAtCachesFolder:(NSString *)folderPath;


@end
