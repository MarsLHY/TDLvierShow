//
//  PublishController.m
//  RTMPiOSDemo
//
//  Created by 蓝鲸 on 16/4/1.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "TCPushViewController.h"
#import "TDPlayViewController.h"
#import <Foundation/Foundation.h>
#import "TXRTMPSDK/TXLiveSDKTypeDef.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import "TCMsgHandler.h"
#import "TCMsgModel.h"
#import "TCPusherModel.h"
#import "TCUserInfoModel.h"
#import "TXRTMPSDK/TXLivePlayer.h"
#import "TCConstants.h"
#import "NSString+Common.h"
#import <CWStatusBarNotification/CWStatusBarNotification.h>
#if POD_PITU
#import "MCCameraDynamicView.h"
#import "MCTip.h"
#import "MaterialManager.h"

@interface TCPushViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, MCCameraDynamicDelegate>

@property (nonatomic, strong) UIButton *filterBtn;
@property (nonatomic, assign) NSInteger currentFilterIndex;
@property (nonatomic, strong) MCCameraDynamicView *tmplBar;

@end

#endif

@implementation TCPushViewController
{
    BOOL _camera_switch;
    float  _beauty_level;
    float  _whitening_level;
    float  _eye_level;
    float  _face_level;
    BOOL _torch_switch;
    
    unsigned long long  _startTime;
    unsigned long long  _lastTime;
    
    NSString*       _logMsg;
    NSString*       _tipsMsg;
    NSString*       _testPath;
    BOOL            _isPreviewing;
    
    BOOL       _appIsInterrupt;
    
    TCLiveInfo *_liveInfo;
    
    BOOL        _firstAppear;
    
    TCPushDecorateView *_logicView;
    UIView             *_videoParentView;
    
    AVIMMsgHandler *_msgHandler;
    
    CWStatusBarNotification *_notification;
}

- (instancetype)initWithPublishInfo:(TCLiveInfo *)liveInfo {
    if (self = [super init]) {
        _liveInfo = liveInfo;
        _platformType = UMSocialPlatformType_UnKnown;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        _notification = [CWStatusBarNotification new];
        _notification.notificationLabelBackgroundColor = [UIColor redColor];
        _notification.notificationLabelTextColor = [UIColor whiteColor];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _firstAppear = YES;
    
    UIColor* bgColor = [UIColor blackColor];
    [self.view setBackgroundColor:bgColor];
    
    //视频画面的父view
    _videoParentView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_videoParentView];
    
    _logicView = [[TCPushDecorateView alloc] initWithFrame:self.view.frame];
    _logicView.delegate = self;
    [self.view addSubview:_logicView];
    
    _txLivePushonfig = [[TXLivePushConfig alloc] init];
    _txLivePushonfig.frontCamera = YES;
    _txLivePushonfig.enableAutoBitrate = NO;
    //由于iphone4s及以下机型前置摄像头不支持540p，故iphone4s及以下采用360p
    _txLivePushonfig.videoResolution = [self isSuitableMachine:5 ] ? VIDEO_RESOLUTION_TYPE_540_960 : VIDEO_RESOLUTION_TYPE_360_640;
    _txLivePushonfig.videoBitratePIN = 1000;
    _txLivePushonfig.enableHWAcceleration = YES;
    
    //background push
    _txLivePushonfig.pauseFps = 10;
    _txLivePushonfig.pauseTime = 300;
    _txLivePushonfig.pauseImg = [UIImage imageNamed:@"pause_publish.jpg"];
    
    //耳返
    _txLivePushonfig.enableAudioPreview = YES;
    
    _txLivePublisher = [[TXLivePush alloc] initWithConfig:_txLivePushonfig];
    
    // 创建群组
    TCUserInfoData  *profile = [[TCUserInfoModel sharedInstance] getUserProfile];
    _liveInfo.userinfo.headpic = profile.faceURL;
    _liveInfo.userinfo.nickname = profile.nickName;
    
    __weak typeof(self) weakSelf = self;
    _msgHandler = [[AVIMMsgHandler alloc] init];
    [_msgHandler createLiveRoom:^(int errCode, NSString *groupId) {
        if (errCode == 0)
        {
            _liveInfo.groupid = groupId;
            [[TCPusherModel sharedInstance] getPusherUrl:profile.identifier
                                                groupId:groupId
                                                title:_liveInfo.title
                                                coverPic:profile.coverURL
                                                nickName:profile.nickName
                                                headPic:profile.faceURL
                                                location:_liveInfo.userinfo.location
                                                handler:^(int errCode, NSString *pusherUrl, NSInteger timestamp) {
                                                    if (0 == errCode)
                                                    {
                                                        _liveInfo.playurl = pusherUrl;

                                                        TCPublishInfo *info = [[TCPublishInfo alloc] init];
                                                        info.liveInfo = _liveInfo;
                                                        info.msgHandler  =  _msgHandler;
                                                        [_logicView setPublishInfo:info];
                                                        
                                                        //状态初始化
                                                        _camera_switch = NO;
                                                        _beauty_level = 9;
                                                        _whitening_level = 3;
                                                        [_txLivePublisher setBeautyFilterDepth:_beauty_level setWhiteningFilterDepth:_whitening_level];
                                                        _torch_switch= NO;
                                                        _log_switch = NO;
                                                        
                                                        //启动rtmp
                                                        _rtmpUrl =  _liveInfo.playurl;
                                                        _liveInfo.timestamp = timestamp;
                                                        if (_platformType >= 0) {
                                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                                [weakSelf shareDataWithPlatform:_platformType];
                                                            });
                                                            
                                                        } else {
                                                            [weakSelf startRtmp];
                                                        }
                                                    }
                                                    else
                                                    {
                                                        [_logicView closeVCWithError:[NSString stringWithFormat:@"%@%d", kErrorMsgGetPushUrlFailed, errCode] Alert:YES Result:NO];
                                                    }
                                                    
                                                }];
        }
        else
        {
            [_logicView closeVCWithError:[NSString stringWithFormat:@"%@%d",kErrorMsgCreateGroupFailed, errCode]  Alert:YES Result:NO];
        }
    }];
    
    
#if POD_PITU
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(packageDownloadProgress:) name:kMC_NOTI_ONLINEMANAGER_PACKAGE_PROGRESS object:nil];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_rtmpUrl && _platformType >= 0) {
        [self startRtmp];
        _platformType = UMSocialPlatformType_UnKnown;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] addObserver:_logicView selector:@selector(keyboardFrameDidChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
        });
    }
#if !TARGET_IPHONE_SIMULATOR
#if !POD_PITU
    if (!_firstAppear) {
        //是否有摄像头权限
        AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (statusVideo == AVAuthorizationStatusDenied) {
    //        [self toastTip:@"获取摄像头权限失败，请前往隐私-相机设置里面打开应用权限"];
            [_logicView closeVCWithError:kErrorMsgOpenCameraFailed Alert:YES Result:NO];
            return;
        }
        
        if (!_isPreviewing) {
            [_txLivePublisher startPreview:_videoParentView];
            _isPreviewing = YES;
        }
    } else {
        _firstAppear = NO;
    }
#endif
#endif

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onAppDidEnterBackGround:(UIApplication*)app {
    // 暂停背景音乐
    if (_txLivePublisher) {
        [_txLivePublisher pauseBGM];
    }

    if ([_txLivePublisher isPublishing]) {
        [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
//            [_txLivePublisher resumePush];
        }];
        [_txLivePublisher pausePush];
    }
}

- (void)onAppWillEnterForeground:(UIApplication*)app {
    if (_rtmpUrl && _platformType >= 0) {
        [self startRtmp];
        _platformType = UMSocialPlatformType_UnKnown;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] addObserver:_logicView selector:@selector(keyboardFrameDidChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
        });
        return;
    }
    // 恢复背景音乐
    if (_txLivePublisher) {
        [_txLivePublisher resumeBGM];
    }
    
    if ([_txLivePublisher isPublishing]) {
        [_txLivePublisher resumePush];
    }
}

- (void)onAppWillResignActive:(NSNotification*)notification
{
    [_txLivePublisher pausePush];
}

- (void)onAppDidBecomeActive:(NSNotification*)notification
{
    [_txLivePublisher resumePush];
}

- (void)clearLog {
    _tipsMsg = @"";
    _logMsg = @"";
    [_logicView.statusView setText:@""];
    [_logicView.logViewEvt setText:@""];
    _startTime = [[NSDate date]timeIntervalSince1970]*1000;
    _lastTime = _startTime;
}


-(BOOL)startRtmp{
    [self clearLog];
    if (_rtmpUrl.length == 0) {
        _rtmpUrl = RTMP_PUBLISH_URL;
    }
    
    if (!([_rtmpUrl hasPrefix:@"rtmp://"] )) {
        [self toastTip:@"推流地址不合法，目前支持rtmp推流!"];
        return NO;
    }
    
    //是否有摄像头权限
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusDenied) {
//        [self toastTip:@"获取摄像头权限失败，请前往隐私-相机设置里面打开应用权限"];
        [_logicView closeVCWithError:kErrorMsgOpenCameraFailed Alert:YES Result:NO];
        return NO;
    }
    
    //是否有麦克风权限
    AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (statusAudio == AVAuthorizationStatusDenied) {
//        [self toastTip:@"获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限"];
        [_logicView closeVCWithError:kErrorMsgOpenMicFailed Alert:YES Result:NO];
        return NO;
    }
    
    NSArray* ver = [TXLivePlayer getSDKVersion];
    if ([ver count] >= 4) {
        _logMsg = [NSString stringWithFormat:@"rtmp sdk version: %@.%@.%@.%@",ver[0],ver[1],ver[2],ver[3]];
        [_logicView.logViewEvt setText:_logMsg];
    }
    
    if(_txLivePublisher != nil)
    {
        _txLivePublisher.delegate = self;
        [self.txLivePublisher setVideoQuality:VIDEO_QUALITY_HIGH_DEFINITION];
        if (!_isPreviewing) {
            [_txLivePublisher startPreview:_videoParentView];
            _isPreviewing = YES;
        }
        if ([_txLivePublisher startPush:_rtmpUrl] != 0) {
            NSLog(@"推流器启动失败");
            return NO;
        }
        [_txLivePublisher setEyeScaleLevel:_eye_level];
        [_txLivePublisher setFaceScaleLevel:_face_level];
        [_txLivePublisher setMirror:YES];
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    return YES;
}
#if POD_PITU

//#warning step 1.3 切换动效素材
#pragma mark - MCCameraDynamicDelegate

- (void)motionTmplSelected:(NSString *)materialID {
    if (materialID == nil) {
        [MCTip hideText];
    }
    if ([MaterialManager isOnlinePackage:materialID]) {
        [_txLivePublisher selectMotionTmpl:materialID inDir:[MaterialManager packageDownloadDir]];
    } else {
        NSString *localPackageDir = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Resource"];
        [_txLivePublisher selectMotionTmpl:materialID inDir:localPackageDir];
    }
}
- (void)packageDownloadProgress:(NSNotification *)notification {
    if ([[notification object] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *progressDic = [notification object];
        CGFloat progress = [progressDic[kMC_USERINFO_ONLINEMANAGER_PACKAGE_PROGRESS] floatValue];
        if (progress <= 0.f) {
            [MCTip showText:@"素材下载失败" inView:self.view afterDelay:2.f];
        }
    }
}
#endif

- (void)greenSelected:(NSURL *)mid {
    NSLog(@"green %@", mid);
    [_txLivePublisher setGreenScreenFile:mid];
}

- (void)filterSelected:(int)index {
    NSString* lookupFileName = @"";
    
    switch (index) {
        case FilterType_None:
            break;
        case FilterType_white:
            lookupFileName = @"filter_white";
            break;
        case FilterType_langman:
            lookupFileName = @"filter_langman";
            break;
        case FilterType_qingxin:
            lookupFileName = @"filter_qingxin";
            break;
        case FilterType_weimei:
            lookupFileName = @"filter_weimei";
            break;
        case FilterType_fennen:
            lookupFileName = @"filter_fennen";
            break;
        case FilterType_huaijiu:
            lookupFileName = @"filter_huaijiu";
            break;
        case FilterType_landiao:
            lookupFileName = @"filter_landiao";
            break;
        case FilterType_qingliang:
            lookupFileName = @"filter_qingliang";
            break;
        case FilterType_rixi:
            lookupFileName = @"filter_rixi";
            break;
        default:
            break;
    }
    NSString * path = [[NSBundle mainBundle] pathForResource:lookupFileName ofType:@"png"];
    if (path != nil && index != FilterType_None && _txLivePublisher != nil) {
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        [_txLivePublisher setFilter:image];
    } else if(_txLivePublisher != nil) {
        [_txLivePublisher setFilter:nil];
    }
}

- (void)stopRtmp {
    if(_txLivePublisher != nil)
    {
        _txLivePublisher.delegate = nil;
        [_txLivePublisher stopPreview];
        _isPreviewing = NO;
        [_txLivePublisher stopPush];
        _txLivePublisher.config.pauseImg = nil;
        _txLivePublisher = nil;
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

// RTMP 推流事件通知
#pragma - TXLivePushListener
-(void) appendLog:(NSString*) evt time:(NSDate*) date mills:(int)mil
{
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString* time = [format stringFromDate:date];
    NSString* log = [NSString stringWithFormat:@"[%@.%-3.3d] %@", time, mil, evt];
    if (_logMsg == nil) {
        _logMsg = @"";
    }
    _logMsg = [NSString stringWithFormat:@"%@\n%@", _logMsg, log];
    [_logicView.logViewEvt setText:_logMsg];
}

-(void) onPushEvent:(int)EvtID withParam:(NSDictionary*)param;
{
    NSDictionary* dict = param;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (EvtID >= 0) {
            if (EvtID == PUSH_WARNING_HW_ACCELERATION_FAIL)
            {
                _txLivePublisher.config.enableHWAcceleration = false;
            }
            else if (EvtID == PUSH_EVT_PUSH_BEGIN)
            {
                //该事件表示推流成功，可以通知业务server将该流置为上线状态
                [[TCPusherModel sharedInstance] changeLiveStatus:_liveInfo.userid status:TCLiveStatus_Online handler:^(int errCode) {
                    DebugLog(@"changeLiveStatus failed, err:%d", errCode);
                }];
            } else if (EvtID == PUSH_WARNING_NET_BUSY) {
                [_notification displayNotificationWithMessage:@"您当前的网络环境不佳，请尽快更换网络保证正常直播" forDuration:5];
            }
        } else {
            if (EvtID == PUSH_ERR_NET_DISCONNECT) {
                [_logicView closeVCWithError:kErrorMsgNetDisconnected Alert:YES Result:YES];
            } else if (EvtID == PUSH_ERR_OPEN_CAMERA_FAIL) {
                [_logicView closeVCWithError:kErrorMsgOpenCameraFailed Alert:YES Result:NO];
            } else if (EvtID == PUSH_ERR_OPEN_MIC_FAIL) {
                 [_logicView closeVCWithError:kErrorMsgOpenMicFailed Alert:YES Result:NO];
            }  else {
                if (EvtID != PUSH_ERR_VIDEO_ENCODE_FAIL) {
                [_logicView closeVCWithError:(NSString*)[dict valueForKey:EVT_MSG] Alert:NO Result:NO];
            }
        }
        }
        
        long long time = [(NSNumber*)[dict valueForKey:EVT_TIME] longLongValue];
        int mil = time % 1000;
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:time/1000];
        NSString* Msg = (NSString*)[dict valueForKey:EVT_MSG];
        [self appendLog:Msg time:date mills:mil];
    });
}

-(void) onNetStatus:(NSDictionary*) param
{
    NSDictionary* dict = param;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        int netspeed  = [(NSNumber*)[dict valueForKey:NET_STATUS_NET_SPEED] intValue];
        int vbitrate  = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_BITRATE] intValue];
        int abitrate  = [(NSNumber*)[dict valueForKey:NET_STATUS_AUDIO_BITRATE] intValue];
        int cachesize = [(NSNumber*)[dict valueForKey:NET_STATUS_CACHE_SIZE] intValue];
        int dropsize  = [(NSNumber*)[dict valueForKey:NET_STATUS_DROP_SIZE] intValue];
        int jitter    = [(NSNumber*)[dict valueForKey:NET_STATUS_NET_JITTER] intValue];
        int fps       = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_FPS] intValue];
        int width     = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_WIDTH] intValue];
        int height    = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_HEIGHT] intValue];
        float cpu_usage = [(NSNumber*)[dict valueForKey:NET_STATUS_CPU_USAGE] floatValue];
        int codecCacheSize = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_CACHE] intValue];
        int nCodecDropCnt = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_DROP_CNT] intValue];
        NSString *serverIP = [dict valueForKey:NET_STATUS_SERVER_IP];

        NSString* log = [NSString stringWithFormat:@"CPU:%.1f%%\tRES:%d*%d\tSPD:%dkb/s\nJITT:%d\tFPS:%d\tARA:%dkb/s\nQUE:%d|%d\tDRP:%d|%d\tVRA:%dkb/s\nSVR:%@\t",
                         cpu_usage*100,
                         width,
                         height,
                         netspeed,
                         jitter,
                         fps,
                         abitrate,
                         codecCacheSize,
                         cachesize,
                         nCodecDropCnt,
                         dropsize,
                         vbitrate,
                         serverIP];
        [_logicView.statusView setText:log];

    });
}

#pragma mark UI EVENT

-(void)closeRTMP {
    [self stopRtmp];
    
    if (_msgHandler)
    {
        [_msgHandler deleteLiveRoom:_liveInfo.groupid handler:^(int errCode) {
            
        }];
    }
    
    [[TCPusherModel sharedInstance] changeLiveStatus:_liveInfo.userid status:TCLiveStatus_Offline handler:^(int errCode) {
        
    }];
}

-(void)closeVC{
//    TCNavigationController TCMainTabViewController
//    NSLog(@"%@ %@", [self.presentingViewController class], [self.presentingViewController.presentingViewController class]);
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer{
    _logicView.vBeauty.hidden = YES;
    _logicView.vMusicPanel.hidden = YES;
    
    //手动聚焦
    CGPoint touchLocation = [gestureRecognizer locationInView:_videoParentView];
    [_txLivePublisher setFocusPosition:touchLocation];
}

-(void) clickCamera:(UIButton*) btn
{
    _camera_switch = !_camera_switch;
#if POD_PITU
    [_txLivePublisher setMirror:!_camera_switch];
#endif
    [_txLivePublisher switchCamera];
}

-(void) clickBeauty:(UIButton*) btn
{
    _logicView.vBeauty.hidden = NO;
}

- (void)clickMusicSelect:(UIButton *)btn {
    //创建播放器控制器
    MPMediaPickerController *mpc = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    mpc.delegate = self;
    mpc.editing = YES;
    [self presentViewController:mpc animated:YES completion:nil];
}

- (void)clickMusic:(UIButton *)button {
    _logicView.vMusicPanel.hidden = NO;
}

- (void)clickMusicClose:(UIButton *)button {
    _logicView.vMusicPanel.hidden = YES;
    
    [_txLivePublisher stopBGM];
}

//- (void)clickVolumeSwitch:(UIButton *)button {
//    if (button.tag == 0) {  // 背景音乐
//        if (button.selected) { // 关 --> 开
//            [_txLivePublisher setBGMVolume:(_logicView.sdBGMVol.value/_logicView.sdBGMVol.maximumValue)];
//        } else {  // 开 --> 关
//            [_txLivePublisher setBGMVolume:0];
//        }
//    } else if (button.tag == 1) {  // 麦克风
//        if (button.selected) { // 关 --> 开
//            [_txLivePublisher setMicVolume:(_logicView.sdMicVol.value/_logicView.sdMicVol.maximumValue)];
//        } else {  // 开 --> 关
//            [_txLivePublisher setMicVolume:0];
//        }
//    }
//}

/**
 @method 获取指定宽度width的字符串在UITextView上的高度
 @param textView 待计算的UITextView
 @param width 限制字符串显示区域的宽度
 @result float 返回的高度
 */
- (float) heightForString:(UITextView *)textView andWidth:(float)width{
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}
- (void) toastTip:(NSString*)toastInfo
{
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    __block UITextView * toastView = [[UITextView alloc] init];
    
    toastView.editable = NO;
    toastView.selectable = NO;
    
    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];
    
    toastView.frame = frameRC;
    
    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;
    
    [self.view addSubview:toastView];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(){
        [toastView removeFromSuperview];
        toastView = nil;
    });
}


-(void) clickLog:(UIButton*) btn
{
    if (_log_switch == YES)
    {
        _logicView.statusView.hidden = YES;
        _logicView.logViewEvt.hidden = YES;
        [btn setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
        _logicView.cover.hidden = YES;
        _log_switch = NO;
    }
    else
    {
        _logicView.statusView.hidden = NO;
        _logicView.logViewEvt.hidden = NO;
        [btn setImage:[UIImage imageNamed:@"log2"] forState:UIControlStateNormal];
        _logicView.cover.alpha = 0.5;
        _logicView.cover.hidden = NO;
        _log_switch = YES;
    }

}

-(void) clickTorch:(UIButton*) btn
{
    if (_txLivePublisher) {
        _torch_switch = !_torch_switch;
        if (![_txLivePublisher toggleTorch:_torch_switch]) {
            _torch_switch = !_torch_switch;
            [self toastTip:@"闪光灯启动失败"];
        }
        
        if (_torch_switch == YES) {
            [_logicView.btnTorch setImage:[UIImage imageNamed:@"flash_hover"] forState:UIControlStateNormal];
        }
        else
        {
            [_logicView.btnTorch setImage:[UIImage imageNamed:@"flash"] forState:UIControlStateNormal];
        }
    }
}


-(void) sliderValueChange:(UISlider*) obj
{
    // todo
    if (obj.tag == 0) { //美颜
        _beauty_level = obj.value;
        [_txLivePublisher setBeautyFilterDepth:_beauty_level setWhiteningFilterDepth:_whitening_level];
    } else if (obj.tag == 1) { //美白
        _whitening_level = obj.value;
        [_txLivePublisher setBeautyFilterDepth:_beauty_level setWhiteningFilterDepth:_whitening_level];
    } else if (obj.tag == 2) { //大眼
        _eye_level = obj.value;
        [_txLivePublisher setEyeScaleLevel:_eye_level];
    } else if (obj.tag == 3) { //瘦脸
        _face_level = obj.value;
        [_txLivePublisher setFaceScaleLevel:_face_level];
    } else if (obj.tag == 4) {// 背景音乐音量
        [_txLivePublisher setBGMVolume:(obj.value/obj.maximumValue)];
    } else if (obj.tag == 5) { // 麦克风音量
        [_txLivePublisher setMicVolume:(obj.value/obj.maximumValue)];
    }
}

-(void) sliderValueChangeEx:(UISlider*) obj
{



}


-(void)selectEffect:(NSInteger)index
{
    [_txLivePublisher setReverbType:index];
}                                                                                                                                                                                                             

-(BOOL)isSuitableMachine:(int)targetPlatNum
{
    int mib[2] = {CTL_HW, HW_MACHINE};
    size_t len = 0;
    char* machine;
    
    sysctl(mib, 2, NULL, &len, NULL, 0);
    
    machine = (char*)malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString* platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    if ([platform length] > 6) {
        NSString * platNum = [NSString stringWithFormat:@"%C", [platform characterAtIndex: 6 ]];
        return ([platNum intValue] >= targetPlatNum);
    } else {
        return NO;
    }
    
}

#pragma mark - MPMediaPickerControllerDelegate 
//选中后调用
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection{
    NSArray *items = mediaItemCollection.items;
    MPMediaItem *item = [items objectAtIndex:0];
    
    NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    NSLog(@"MPMediaItemPropertyAssetURL = %@", url);
    
    if (mediaPicker.editing) {
        mediaPicker.editing = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_txLivePublisher stopBGM];
            [self saveAssetURLToFile: url];
        });
                       
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//点击取消时回调
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 将AssetURL(音乐)导出到app的文件夹并播放
- (void)saveAssetURLToFile:(NSURL *)assetURL {
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:songAsset presetName:AVAssetExportPresetAppleM4A];
    NSLog (@"created exporter. supportedFileTypes: %@", exporter.supportedFileTypes);
    exporter.outputFileType = @"com.apple.m4a-audio";
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *exportFile = [docDir stringByAppendingPathComponent:@"exported.m4a"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportFile]) {
        [[NSFileManager defaultManager] removeItemAtPath:exportFile error:nil];
    }
    exporter.outputURL = [NSURL fileURLWithPath:exportFile];
    
    // do the export
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = exporter.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed: {
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exporter.error);
                break;
            }
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@"AVAssetExportSessionStatusCompleted: %@", exporter.outputURL);
                
                // 播放背景音乐
                dispatch_async(dispatch_get_main_queue(), ^{
                    // _logicView.vMusicPanel.hidden = NO;   // 暂时不加这两个按钮
                    [_txLivePublisher playBGM:[exporter.outputURL absoluteString]];
                });
                break;
            }
            case AVAssetExportSessionStatusUnknown: { NSLog (@"AVAssetExportSessionStatusUnknown"); break;}
            case AVAssetExportSessionStatusExporting: { NSLog (@"AVAssetExportSessionStatusExporting"); break;}
            case AVAssetExportSessionStatusCancelled: { NSLog (@"AVAssetExportSessionStatusCancelled"); break;}
            case AVAssetExportSessionStatusWaiting: { NSLog (@"AVAssetExportSessionStatusWaiting"); break;}
            default: { NSLog (@"didn't get export status"); break;}
        }
    }];
}


- (void)shareDataWithPlatform:(UMSocialPlatformType)platformType
{
    // 创建UMSocialMessageObject实例进行分享
    // 分享数据对象
    UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
    
    NSString *title = _liveInfo.title;
    
    NSString *url = [NSString stringWithFormat:@"%@?userid=%@&type=%@&fileid=%@&ts=%@&sdkappid=%@&acctype=%@",
                     kLivePlayShareAddr,
                     TC_PROTECT_STR([_liveInfo.userid stringByUrlEncoding]),
                     [NSString stringWithFormat:@"%d", _liveInfo.type],
                     TC_PROTECT_STR([_liveInfo.fileid stringByUrlEncoding]),
                     [NSString stringWithFormat:@"%d", _liveInfo.timestamp],
                     kTCIMSDKAppId,
                     kTCIMSDKAccountType];
    NSString *text = [NSString stringWithFormat:@"%@ 正在直播", _liveInfo.userinfo.nickname ? _liveInfo.userinfo.nickname : _liveInfo.userid];
    
    // 以下分享类型，开发者可根据需求调用 
    // 1、纯文本分享
    messageObject.text = @"开播啦，小伙伴火速围观～～～";
    
    
    
    // 2、 图片或图文分享
    // 图片分享参数可设置URL、NSData类型
    // 注意：由于iOS系统限制(iOS9+)，非HTTPS的URL图片可能会分享失败
    UMShareImageObject *shareObject = [UMShareImageObject shareObjectWithTitle:title descr:text thumImage:_liveInfo.userinfo.frontcover];
    [shareObject setShareImage:_liveInfo.userinfo.frontcoverImage];
    
    UMShareWebpageObject *share2Object = [UMShareWebpageObject shareObjectWithTitle:title descr:text thumImage:_liveInfo.userinfo.frontcoverImage];
    share2Object.webpageUrl = url;
    
    //新浪微博有个bug，放在shareObject里面设置url，分享到网页版的微博不显示URL链接，这里在text后面也加上链接
    if (platformType == UMSocialPlatformType_Sina) {
        messageObject.text = [NSString stringWithFormat:@"%@  %@",messageObject.text,share2Object.webpageUrl];
    }else{
        messageObject.shareObject = share2Object;
    }
    [[UMSocialManager defaultManager] shareToPlatform:platformType messageObject:messageObject currentViewController:self completion:^(id data, NSError *error) {
        // 如果应用未安装，则不会启动分享页面，那么不会触发onAppWillEnterForeground来调用startRtmp，所以应该在这里调用startRtmp
        if (error) {
            NSLog(@"shareToPlatform failed: %@", error);
            [self startRtmp];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_logicView name:UIKeyboardWillChangeFrameNotification object:nil];
}

@end
