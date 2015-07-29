
//  ViewController.m
//  FCQRHandleDemo
//
//  Created by zhisheshe on 15/7/24.
//  Copyright (c) 2015年 fcihpy. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "FCQRHelper.h"


@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

//    self.qrCodeView.image = [FCQRHelper qrImageWithString:@"我是中国人" imageSize:250.0f red:113 green:132 blue:233];
//    
//    self.qrCodeView.image = [FCQRHelper qrImageWithString:@"http://www.sina.com" imageSize:200.0f];
//    self.qrCodeView.image = [FCQRHelper qrImageWithString:@"http://www.sohu.com" imageSize:100.0f red:223 green:113 blue:231];
    
    self.qrCodeView.image = [FCQRHelper qrImageWithString:@"http://www.163.com" imageSize:200.0f avatarImageStr:@"http://appwx.25ren.com/data/upload/20150729/55b87aac2e557.png" red:100 green:200 blue:100];

}


- (IBAction)startStop:(id)sender {
  
    FCQRHelper *helper = [[FCQRHelper alloc]init];
    
    [helper readQRWithView:self.view complation:^(NSString *message) {
        
        NSLog(@"34444444444444444t %@",message);
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:message]];

    }];
 
}





@end
