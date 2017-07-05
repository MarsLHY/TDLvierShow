//
//  TDPlayViewController.h
//  TDLiveShow
//
//  Created by TD on 2017/7/5.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "BaseViewController.h"
#import "TXRTMPSDK/TXLivePlayer.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TDPlayDecorateView.h"
#import "TCLiveListModel.h"
#import "TCPlayUGCDecorateView.h"
#import "TXRTMPSDK/TXUGCRecordTypeDef.h"
#import "TXRTMPSDK/TXUGCRecordListener.h"

#define FULL_SCREEN_PLAY_VIDEO_VIEW     10000

/**
 *  播放模块主控制器，里面承载了渲染view，逻辑view，以及播放相关逻辑，同时也是SDK层事件通知的接收者
 */
extern NSString *const kTCLivePlayError;

@interface TDPlayViewController : BaseViewController<UITextFieldDelegate, TXLivePlayListener,TDPlayDecorateDelegate, TCPlayUGCDecorateViewDelegate, TXVideoRecordListener>

typedef void(^videoIsReadyBlock)();

@property (nonatomic, assign) BOOL  enableLinkMic;
@property (nonatomic, assign) BOOL  log_switch;
@property (nonatomic, retain) TDPlayDecorateView *logicView;

-(id)initWithPlayInfo:(TCLiveInfo *)info  videoIsReady:(videoIsReadyBlock)videoIsReady;

-(BOOL)startRtmp;

- (void)stopRtmp;

- (void)onAppDidEnterBackGround:(UIApplication*)app;

- (void)onAppWillEnterForeground:(UIApplication*)app;

@end
