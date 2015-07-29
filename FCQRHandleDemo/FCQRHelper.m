//
//  FCQRHelper.m
//  FCQRHandleDemo
//
//  Created by zhisheshe on 15/7/27.
//  Copyright (c) 2015年 fcihpy. All rights reserved.
//

#import "FCQRHelper.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


typedef void(^complationBlock)(NSString *);

@interface FCQRHelper ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic,copy)complationBlock successBlock;

@property (strong, nonatomic) UIView *boxView;

@property (strong, nonatomic) CALayer *scanLayer;

@property (weak, nonatomic) UIView *viewPreview;


//捕捉会话
@property (nonatomic, strong) AVCaptureSession *captureSession;

//展示layer
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;



@end

@implementation FCQRHelper

#pragma mark - 根据字符串创建一个二维码
+ (UIImage *)qrImageWithString:(NSString *)qrString
                           imageSize:(CGFloat)size{
    
    UIImage *qrImage;
    
    CIImage *qrCIImage = [self createQRWithString:qrString];
    
    qrImage = [self qrImageWithCIImage:qrCIImage withSize:size];
   
    return qrImage;
}

#pragma mark - 根据字符串创建一个特定大小的、有颜色的二维码
+ (UIImage *)qrImageWithString:(NSString *)qrString
                           imageSize:(CGFloat)size
                            red:(CGFloat)red
                          green:(CGFloat)green
                           blue:(CGFloat)blue{
    UIImage *qrImage;
   
    UIImage *sourceImage = [self qrImageWithString:qrString imageSize:size];
    
    qrImage = [self coverImageColorWithImage:sourceImage red:red green:green blue:blue];
    
    return qrImage;
}


#pragma mark 创建含有头像的二维码
+ (UIImage *)qrImageWithString:(NSString *)qrString
                     imageSize:(CGFloat)size
                avatarImageStr:(NSString *)str
                           red:(CGFloat)red
                         green:(CGFloat)green
                          blue:(CGFloat)blue{
    UIImage *qrImage;
    
    UIImage *sourceimage = [self  qrImageWithString:qrString imageSize:size red:red green:green blue:blue];

    // two-dimension code 二维码
    
    CGSize size1 = sourceimage.size;
    
    CGSize size2 =CGSizeMake(1.0 / 5.5 * size1.width, 1.0 / 5.5 * size1.height);
    
    UIGraphicsBeginImageContext(size1);
    
    [sourceimage drawInRect:CGRectMake(0, 0, size1.width, size1.height)];
    

    UIImage *avatrarImage = nil;
    //判断是否是网络图片
    NSRange rang = [str rangeOfString:@"http"];
    if (rang.location != NSNotFound) {
        //此处可以使用sdwebimage加载网络图片
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:str]];
        avatrarImage = [UIImage imageWithData:imageData];

    }else{
        avatrarImage = [UIImage imageNamed:str];
    }
    [[self avatarImage:avatrarImage] drawInRect:CGRectMake((size1.width - size2.width) / 2.0, (size1.height - size2.height) / 2.0, size2.width, size2.height)];

    UIImage *resultingImage =UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resultingImage;
    
    return qrImage;
    
}


+ (UIImage *) avatarImage:(UIImage *)avatarImage{
 
    CGSize size = avatarImage.size;
    
    UIGraphicsBeginImageContext(size);
   
    [avatarImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *resultingImage =UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resultingImage;
    
}

#pragma mark ----------------------生成二维码------------------
#pragma mark - QRCodeGenerator
//根据传入的字符中，使用CIFilter生成二维码
+ (CIImage *)createQRWithString:(NSString *)qrString {
    
    // 转换string为UTF-8
    NSData *stringData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 创建filter
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 设置内容和纠错级别
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    // 返回CIImage对象
    return qrFilter.outputImage;
}

#pragma mark - InterpolatedUIImage
//将生成的二维码对象转换成需要大小的UIImage对象
+ (UIImage *)qrImageWithCIImage:(CIImage *)image
                                            withSize:(CGFloat) size {
    
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 创建bitmap
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
//    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(true)}];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    // Cleanup
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    return [UIImage imageWithCGImage:scaledImage];
}



#pragma mark - imageToTransparent
void ProviderReleaseData (void *info, const void *data, size_t size){
    free((void*)data);
}

//使用CGContext对二维码对象进行颜色修改
+ (UIImage*)coverImageColorWithImage:(UIImage*)image
                                 red:(CGFloat)red
                               green:(CGFloat)green
                                blue:(CGFloat)blue{
    
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    // create context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    
    // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++){
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900){
            
            // 将白色变成需要的颜色
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = red; //0~255
            ptr[2] = green;
            ptr[1] = blue;
            
        }else{
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
    }
    // 输出image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,
                                        kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef];
    
    // 清理空间
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return resultUIImage;
}



#pragma mark ----------------------读取二维码------------------


#pragma mark 读取二维码

- (void)readQRWithView:(UIView *)view complation:(void (^)(NSString * message))complation{

    _viewPreview = view;
    [self startReading];
    
    self.successBlock= complation;
 
}


- (BOOL)startReading {
    
    NSError *error;
    
    //1.初始化捕捉设备（AVCaptureDevice），类型为AVMediaTypeVideo
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //2.用captureDevice创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        //判断输入流是否正常
        if (!input) {
            NSLog(@"%@", [error localizedDescription]);
            return NO;
        }
    
    //3.创建媒体数据输出流
   AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    //4.实例化捕捉会话
    _captureSession = [[AVCaptureSession alloc] init];
    
    //4.1.将输入流添加到会话
    if ([_captureSession canAddInput:input]) {
        [_captureSession addInput:input];
    }
    
    //4.2.将媒体输出流添加到会话中
    if ([_captureSession canAddOutput:captureMetadataOutput]) {
        [_captureSession addOutput:captureMetadataOutput];
    }
    
    
    //5.创建串行队列，并加媒体输出流添加到队列当中
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    
    //5.1.设置代理
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    
    //5.2.设置输出媒体数据类型为QRCode
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    //6.实例化预览图层
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    //7.设置预览图层填充方式
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //8.设置图层的frame
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    
    //9.将图层添加到预览view的图层上
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    //10.设置扫描范围
    captureMetadataOutput.rectOfInterest = CGRectMake(0.2f, 0.2f, 0.8f, 0.8f);
    
    //10.1.扫描框
    CGRect frame = CGRectMake(_viewPreview.bounds.size.width * 0.3f, _viewPreview.bounds.size.height * 0.3f, _viewPreview.bounds.size.width - _viewPreview.bounds.size.width * 0.4f, _viewPreview.bounds.size.width - _viewPreview.bounds.size.width * 0.4f);
    
    _boxView = [[UIView alloc] initWithFrame:frame];
    _boxView.layer.borderColor = [UIColor greenColor].CGColor;
    _boxView.layer.borderWidth = 1.0f;
    [_viewPreview addSubview:_boxView];
    
    //10.2.扫描线
    _scanLayer = [[CALayer alloc] init];
    _scanLayer.frame = CGRectMake(0, 0, _boxView.bounds.size.width, 5);
    _scanLayer.backgroundColor = [UIColor brownColor].CGColor;
    [_boxView.layer addSublayer:_scanLayer];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(moveScanLayer:) userInfo:nil repeats:YES];
    [timer fire];
    
    //10.开始扫描
    [_captureSession startRunning];
    return YES;
}

-(void)stopReading{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_scanLayer removeFromSuperlayer];
    [_boxView removeFromSuperview];
    [_videoPreviewLayer removeFromSuperlayer];
}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *stringValue;

    //判断是否有数据
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        
        AVMetadataMachineReadableCodeObject *metadataObj = metadataObjects [0];
        
        //判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            
            stringValue = [metadataObj stringValue];

            if (self.successBlock) {
                self.successBlock(stringValue);
            }
            if ([_delegate respondsToSelector:@selector(handlerQRFinish:)]) {
                [_delegate handlerQRFinish:stringValue];
            }
            
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
   
        }
    }
    [self stopReading];
}



- (void)moveScanLayer:(NSTimer *)timer
{
    CGRect frame = _scanLayer.frame;
    
    if (_boxView.frame.size.height < _scanLayer.frame.origin.y) {
        frame.origin.y = 0;
        _scanLayer.frame = frame;
        
    }else{
        
        frame.origin.y += 3;
        
        [UIView animateWithDuration:0.1 animations:^{
            _scanLayer.frame = frame;
        }];
    }
}


- (BOOL)shouldAutorotate
{
    return NO;
}


@end
