//
//  FCQRHelper.h
//  FCQRHandleDemo
//
//  Created by zhisheshe on 15/7/27.
//  Copyright (c) 2015年 fcihpy. All rights reserved.
/**
    对外开放两种调用方法：delegate和block
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol FCQRHelperDelegate <NSObject>

- (void)handlerQRFinish:(NSString *)message;

@end

@interface FCQRHelper : NSObject

@property (nonatomic,assign) id<FCQRHelperDelegate> delegate;

/**
 *  根据字符串创建一个特定大小的二维码
 *
 */
+ (UIImage *)qrImageWithString:(NSString *)qrString
                           imageSize:(CGFloat)size;


/**
 *  根据字符串创建一个特定大小的、有颜色的二维码
 *
 */
+ (UIImage *)qrImageWithString:(NSString *)qrString
                           imageSize:(CGFloat)size
                            red:(CGFloat)red
                          green:(CGFloat)green
                           blue:(CGFloat)blue;


/**
 *  创建含有头像的二维码
 *
 */
+ (UIImage *)qrImageWithString:(NSString *)qrString
                     imageSize:(CGFloat)size
                      avatarImageStr:(NSString *)str
                           red:(CGFloat)red
                         green:(CGFloat)green
                          blue:(CGFloat)blue;


/**
 *  读取二维码
 */
- (void)readQRWithView:(UIView *)view
            complation:(void (^)(NSString * message))complation;


@end
