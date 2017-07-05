//
//  TCPushViewController.h
//  RTMPiOSDemo
//
//  Created by 蓝鲸 on 16/4/1.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "TXRTMPSDK/TXLivePush.h"
#import "TCPushDecorateView.h"
#import "TCMsgHandler.h"
#import "TCLiveListModel.h"
#import "MediaPlayer/MediaPlayer.h"
#import <UMSocialCore/UMSocialCore.h>

/**
 *  推流模块主控制器，里面承载了渲染view，逻辑view，以及推流相关逻辑，同时也是SDK层事件通知的接收者
 */
@interface TCPushViewController : UIViewController<UITextFieldDelegate, TXLivePushListener,TCPushDecorateDelegate, MPMediaPickerControllerDelegate>

- (instancetype)initWithPublishInfo:(TCLiveInfo *)publishInfo;

@property NSString*         rtmpUrl;
@property TXLivePushConfig* txLivePushonfig;
@property TXLivePush*       txLivePublisher;
@property TCPushDecorateView *logicView;
@property BOOL              log_switch;

@property UMSocialPlatformType platformType;

-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer;
- (void) toastTip:(NSString*)toastInfo;
-(BOOL)isSuitableMachine:(int)targetPlatNum;

- (void)onAppDidEnterBackGround:(UIApplication*)app;

- (void)onAppWillEnterForeground:(UIApplication*)app;

-(BOOL)startRtmp;

@end
