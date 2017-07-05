//
//  TDPlayViewController.m
//  TDLiveShow
//
//  Created by TD on 2017/7/5.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "TDPlayViewController.h"
#import "TXRTMPSDK/TXLivePlayListener.h"
#import "TXRTMPSDK/TXLivePlayConfig.h"
#import <mach/mach.h>
#import <UIImageView+WebCache.h>
#import "TDBaseAppDelegate.h"
#import "TCMsgHandler.h"
#import "TCMsgModel.h"
#import "TCPlayerModel.h"
#import "TCConstants.h"
#import <Accelerate/Accelerate.h>
#import "UMSocialUIManager.h"
#import <UMSocialCore/UMSocialCore.h>
#import "TCLoginModel.h"
#import "NSString+Common.h"
#import "TCVideoPublishController.h"


NSString *const kTCLivePlayError = @"kTCLivePlayError";

@interface TDPlayViewController ()

@end

@implementation TDPlayViewController
{
    TXLivePlayer *       _txLivePlayer;
    TXLivePlayConfig*    _config;
    TX_Enum_PlayType     _playType;
    TCPlayUGCDecorateView  *_videoRecordView;
    videoIsReadyBlock     _videoIsReady;
    TCLiveInfo           *_liveInfo;
    long long            _trackingTouchTS;
    BOOL                 _startSeek;
    BOOL                 _videoPause;
    BOOL                 _videoFinished;
    BOOL                 _appIsInterrupt;
    float                _sliderValue;
    BOOL                 _isLivePlay;
    BOOL                 _isInVC;
    NSString             *_logMsg;
    NSString             *_rtmpUrl;
    
    UIView               *_videoParentView;
    
    AVIMMsgHandler       *_msgHandler;
    BOOL                 _isNotifiedEnterGroup;
    BOOL                  _rotate;
    BOOL                 _isErrorAlert; //是否已经弹出了错误提示框，用于保证在同时收到多个错误通知时，只弹一个错误提示框
    
    BOOL                _isResetVideoRecord;
}
-(id)initWithPlayInfo:(TCLiveInfo *)info  videoIsReady:(videoIsReadyBlock)videoIsReady
{
    self = [super init];
    if (self) {
        _videoPause   = NO;
        _videoFinished = YES;
        _isInVC       = NO;
        _log_switch   = NO;
        _videoIsReady = videoIsReady;
        _liveInfo     = info;
        if (_liveInfo.type == TCLiveListItemType_Live) {
            _isLivePlay = YES;
        }else{
            _isLivePlay = NO;
        }
        
        if (_liveInfo.type == TCLiveListItemType_Record) {
            _rtmpUrl      = _liveInfo.hls_play_url;
        } else {
            _rtmpUrl      = _liveInfo.playurl;
        }
        if ([_rtmpUrl hasPrefix:@"http:"]) {
            _rtmpUrl = [_rtmpUrl stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
        }
        _rotate       = NO;
        _txLivePlayer = [[TXLivePlayer alloc] init];
        _txLivePlayer.enableHWAcceleration = YES;
        _msgHandler = [[AVIMMsgHandler alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        [self startPlay];
        _isNotifiedEnterGroup = NO;
        _isErrorAlert = NO;
        self.enableLinkMic = NO;
        
        _isResetVideoRecord = NO;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [self initLogicView];
    
    if (_videoPause && _txLivePlayer) {
        [_txLivePlayer resume];
        _videoPause =NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (!_videoPause && _txLivePlayer) {
        [_txLivePlayer pause];
        _videoPause = YES;
    }
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [self joinGroup];
    
    /*预加载UI*/
    //背景图
    
    UIImage *backImage =  _liveInfo.userinfo.frontcoverImage;
    UIImage *clipImage = nil;
    if (backImage) {
        CGFloat backImageNewHeight = self.view.height;
        CGFloat backImageNewWidth = backImageNewHeight * backImage.size.width / backImage.size.height;
        UIImage *gsImage = [self gsImage:backImage withGsNumber:10];
        UIImage *scaleImage = [self scaleImage:gsImage scaleToSize:CGSizeMake(backImageNewWidth, backImageNewHeight)];
        clipImage = [self clipImage:scaleImage inRect:CGRectMake((backImageNewWidth - self.view.width)/2, (backImageNewHeight - self.view.height)/2, self.view.width, self.view.height)];
    }
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundImageView.image = clipImage;
    backgroundImageView.contentMode = UIViewContentModeScaleToFill;
    backgroundImageView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:backgroundImageView];
    
    //视频画面父view
    _videoParentView = [[UIView alloc] initWithFrame:self.view.frame];
    _videoParentView.tag = FULL_SCREEN_PLAY_VIDEO_VIEW;
    [self.view addSubview:_videoParentView];
    
    [self setVideoView];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    _isInVC = YES;
}

//创建高斯模糊效果图片
-(UIImage *)gsImage:(UIImage *)image withGsNumber:(CGFloat)blur
{
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    int boxSize = (int)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    CGImageRef img = image.CGImage;
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    //从CGImage中获取数据
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    //设置从CGImage获取对象的属性
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate( outBuffer.data, outBuffer.width, outBuffer.height, 8, outBuffer.rowBytes, colorSpace, kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(pixelBuffer);
    CFRelease(inBitmapData);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    return returnImage;
}

/**
 *缩放图片
 */
-(UIImage*)scaleImage:(UIImage *)image scaleToSize:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

/**
 *裁剪图片
 */
-(UIImage *)clipImage:(UIImage *)image inRect:(CGRect)rect{
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    return newImage;
}

- (void)initLogicView {
    if (_logicView) {
        return;
    }
    
    //逻辑View
    _logicView = [[TDPlayDecorateView alloc] initWithFrame:self.view.frame liveInfo:_liveInfo withLinkMic: self.enableLinkMic];
    _logicView.delegate = self;
    [_logicView setMsgHandler:_msgHandler];
    
    _videoRecordView = [[TCPlayUGCDecorateView alloc] initWithFrame:self.view.frame];
    _videoRecordView.delegate = self;
    _videoRecordView.hidden = YES;
    
    [self.view addSubview:_logicView];
    [self.view addSubview:_videoRecordView];
}


//在低系统（如7.1.2）可能收不到这个回调，请在onAppDidEnterBackGround和onAppWillEnterForeground里面处理打断逻辑
- (void) onAudioSessionEvent: (NSNotification *) notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        if (_appIsInterrupt == NO) {
            if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
                if (!_videoPause) {
                    [_txLivePlayer pause];
                }
            }
            _appIsInterrupt = YES;
        }
    }else{
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            if (_appIsInterrupt == YES) {
                if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
                    if (!_videoPause) {
                        [_txLivePlayer resume];
                    }
                }
                _appIsInterrupt = NO;
            }
        }
    }
}

- (void)onAppDidEnterBackGround:(UIApplication*)app {
    if (_appIsInterrupt == NO) {
        if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
            if (!_videoPause) {
                [_txLivePlayer pause];
            }
        }
        _appIsInterrupt = YES;
    }
}

- (void)onAppWillEnterForeground:(UIApplication*)app {
    if (_appIsInterrupt == YES) {
        if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
            if (!_videoPause) {
                [_txLivePlayer resume];
            }
        }
        _appIsInterrupt = NO;
    }
}
#pragma mark RTMP LOGIC

-(BOOL)checkPlayUrl:(NSString*)playUrl {
    if (!([playUrl hasPrefix:@"http:"] || [playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"rtmp:"] )) {
        [self toastTip:@"播放地址不合法，目前仅支持rtmp,flv,hls,mp4播放方式!"];
        return NO;
    }
    if (_isLivePlay) {
        if ([playUrl hasPrefix:@"rtmp:"]) {
            _playType = PLAY_TYPE_LIVE_RTMP;
        } else if (([playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"http:"]) && [playUrl rangeOfString:@".flv"].length > 0) {
            _playType = PLAY_TYPE_LIVE_FLV;
        } else{
            [self toastTip:@"播放地址不合法，直播目前仅支持rtmp,flv播放方式!"];
            return NO;
        }
    } else {
        if ([playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"http:"]) {
            if ([playUrl rangeOfString:@".flv"].length > 0) {
                _playType = PLAY_TYPE_VOD_FLV;
            } else if ([playUrl rangeOfString:@".m3u8"].length > 0){
                _playType= PLAY_TYPE_VOD_HLS;
            } else if ([playUrl rangeOfString:@".mp4"].length > 0){
                _playType= PLAY_TYPE_VOD_MP4;
            } else {
                [self toastTip:@"播放地址不合法，点播目前仅支持flv,hls,mp4播放方式!"];
                return NO;
            }
            
        } else {
            [self toastTip:@"播放地址不合法，点播目前仅支持flv,hls,mp4播放方式!"];
            return NO;
        }
    }
    
    return YES;
}

- (void)clearLog {
    _logMsg = @"";
    [_logicView.statusView setText:@""];
    [_logicView.logViewEvt setText:@""];
}

- (void)setVideoView {
    [self clearLog];
    
    NSArray* ver = [TXLivePlayer getSDKVersion];
    if ([ver count] >= 4) {
        _logMsg = [NSString stringWithFormat:@"rtmp sdk version: %@.%@.%@.%@",ver[0],ver[1],ver[2],ver[3]];
        [_logicView.logViewEvt setText:_logMsg];
    }
    
    [_txLivePlayer setupVideoWidget:self.view.frame containView:_videoParentView insertIndex:0];
    if (_rotate) {
        [_txLivePlayer setRenderRotation:HOME_ORIENTATION_RIGHT];
    }
}

-(BOOL)startPlay {
    if (![self checkPlayUrl:_rtmpUrl]) {
        return NO;
    }
    
    NSArray* ver = [TXLivePlayer getSDKVersion];
    if ([ver count] >= 4) {
        _logMsg = [NSString stringWithFormat:@"rtmp sdk version: %@.%@.%@.%@",ver[0],ver[1],ver[2],ver[3]];
        [_logicView.logViewEvt setText:_logMsg];
    }
    
    if(_txLivePlayer != nil)
    {
        _txLivePlayer.delegate = self;
        int result = [_txLivePlayer startPlay:_rtmpUrl type:_playType];
        if (result == -1)
        {
            [self closeVCWithRefresh:YES popViewController:YES];
            return NO;
        }
        
        if( result != 0)
        {
            [self toastTip:[NSString stringWithFormat:@"%@%d", kErrorMsgRtmpPlayFailed, result]];
            [self closeVCWithRefresh:YES popViewController:YES];
            return NO;
        }
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    _startSeek = NO;
    
    return YES;
}

-(BOOL)startRtmp{
    [self setVideoView];
    return [self startPlay];
}

- (void)stopRtmp{
    if(_txLivePlayer != nil)
    {
        _txLivePlayer.delegate = nil;
        [_txLivePlayer stopPlay];
        [_txLivePlayer removeVideoWidget];
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - UI EVENT
-(void)closeVC:(BOOL)popViewController{
    [self closeVCWithRefresh:NO popViewController:popViewController];
    [UMSocialUIManager dismissShareMenuView];
}

- (void)closeVCWithRefresh:(BOOL)refresh popViewController: (BOOL)popViewController {
    [self stopRtmp];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_liveInfo) {
        
        if (_isNotifiedEnterGroup)
        {
            if (_msgHandler && TCLiveListItemType_Live == _liveInfo.type)
            {
                TCUserInfoData  *profile = [[TCUserInfoModel sharedInstance] getUserProfile];
                [_msgHandler sendQuitLiveRoomMessage:profile.identifier nickName:profile.nickName headPic:profile.faceURL];
                [_msgHandler releaseIMRef];
                
                [_msgHandler quitLiveRoom:_liveInfo.groupid handler:^(int errCode) {
                    
                }];
            }
            
            //通知业务服务器观众退群
            TCUserInfoData  *hostInfo = [[TCUserInfoModel sharedInstance] getUserProfile];
            NSString* realGroupId = _liveInfo.groupid;
            //录播文件由于group已经解散，故使用fileid替代groupid
            if (TCLiveListItemType_Record == _liveInfo.type)
                realGroupId = _liveInfo.fileid;
            
            [[TCPlayerModel sharedInstance] quitGroup:hostInfo.identifier type:_liveInfo.type liveUserId:_liveInfo.userid groupId:realGroupId handler:^(int errCode) {
                
            }];
        }
    }
    if (refresh) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kTCLivePlayError object:self];
        });
    }
    if (popViewController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)clickPlayVod{
    if (!_videoFinished) {
        if (_playType == PLAY_TYPE_VOD_FLV || _playType == PLAY_TYPE_VOD_HLS || _playType == PLAY_TYPE_VOD_MP4) {
            if (_videoPause) {
                [_txLivePlayer resume];
                [_logicView.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            } else {
                [_txLivePlayer pause];
                [_logicView.playBtn setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            }
            _videoPause = !_videoPause;
        }
    }
    else {
        [self startRtmp];
        [_logicView.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}

-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer{
    //todo
}

- (void)clickLog:(UIButton*)btn {
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

- (void)clickRecord:(UIButton *)button
{
    _logicView.hidden = YES;
    _videoRecordView.hidden = NO;
}

#pragma mark - TCPlayUGCDecorateViewDelegate
- (void)closeRecord
{
    _logicView.hidden = NO;
    _videoRecordView.hidden = YES;
    _isResetVideoRecord = YES;
}

- (void)recordVideo:(BOOL)isStart
{
    if (isStart) {
        [_txLivePlayer startRecord:RECORD_TYPE_STREAM_SOURCE];
    } else {
        [_txLivePlayer stopRecord];
        _isResetVideoRecord = NO;
    }
}

- (void)resetRecord
{
    [_txLivePlayer stopRecord];
    _isResetVideoRecord = YES;
}

#pragma mark - TXVideoRecordListener
-(void) onRecordProgress:(NSInteger)milliSecond
{
    if (!_videoRecordView.hidden) {
        float progress = (milliSecond/1000)/kMaxRecordDuration;
        [_videoRecordView setVideoRecordProgress:progress];
    }
}

-(void) onRecordComplete:(TXRecordResult*)result
{
    if (_isResetVideoRecord) return;
    
    if (result.retCode == RECORD_RESULT_FAILED || result.retCode == RECORD_RESULT_OK_INTERRUPT) {
        [self toastTip:result.descMsg];
    } else {
        TCVideoPublishController *vc = [[TCVideoPublishController alloc] init:_txLivePlayer recordType:kRecordType_Play RecordResult:result TCLiveInfo:_liveInfo];
        [self.navigationController pushViewController:vc animated:true];
    }
}

#pragma -- UISlider - play seek
-(void)onSeek:(UISlider *)slider{
    [_txLivePlayer seek:_sliderValue];
    _trackingTouchTS = [[NSDate date]timeIntervalSince1970]*1000;
    _startSeek = NO;
}

-(void)onSeekBegin:(UISlider *)slider{
    _startSeek = YES;
}

-(void)onDrag:(UISlider *)slider {
    float progress = slider.value;
    int intProgress = progress + 0.5;
    _logicView.playLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)intProgress / 3600,(int)(intProgress / 60), (int)(intProgress % 60)];
    _sliderValue = slider.value;
}


/**
 @method 获取指定宽度width的字符串在UITextView上的高度
 @param textView 待计算的UITextView
 @param Width 限制字符串显示区域的宽度
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

#pragma ###TXLivePlayListener
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

-(void) joinGroup {
    if ([[TIMManager sharedInstance] getLoginUser] == nil) {
        [[TCLoginModel sharedInstance] onForceOfflineAlert];
        return;
    }
    TCUserInfoData  *hostInfo = [[TCUserInfoModel sharedInstance] getUserProfile];
    // 使用imsdk接口加群
    NSString *groupid = @"@TGS#aB3KJZZET";
    if (TCLiveListItemType_Live == _liveInfo.type)
    {
        NSLog(@"%@",_liveInfo.groupid);
        [_msgHandler joinLiveRoom:groupid handler:^(int errCode) {
            if (0 == errCode)
            {
                [_msgHandler sendEnterLiveRoomMessage:hostInfo.identifier nickName:hostInfo.nickName headPic:hostInfo.faceURL];
            }
            else
            {
                if (!_isErrorAlert)
                {
                    _isErrorAlert = YES;
                    if (errCode == kError_GroupNotExist) {
                        [HUDHelper alertTitle:@"提示" message:kErrorMsgGroupNotExit cancel:@"确定" action:^{
                            [self closeVCWithRefresh:YES popViewController:YES];
                        }];
                    } else {
                        [HUDHelper alertTitle:@"提示" message:[NSString stringWithFormat:@"%@%d", kErrorMsgJoinGroupFailed, errCode] cancel:@"确定" action:^{
                            [self closeVCWithRefresh:YES popViewController:YES];
                        }];
                    }
                }
            }
        }];
    }
    
    //通知业务服务器有观众加群
    NSString* realGroupId = _liveInfo.groupid;
    //录播文件由于group已经解散，故使用fileid替代groupid
    if (TCLiveListItemType_Record == _liveInfo.type)
        realGroupId = _liveInfo.fileid;
    
    [[TCPlayerModel sharedInstance] enterGroup:hostInfo.identifier type:_liveInfo.type liveUserId:_liveInfo.userid groupId:realGroupId nickName:hostInfo.nickName headPic:hostInfo.faceURL handler:^(int errCode) {
        
        //初始化群成员列表（会主动从业务服务器拉取一次群成员列表）
        [_logicView initAudienceList];
    }];
    
    _isNotifiedEnterGroup = YES;
}

-(void) onPlayEvent:(int)EvtID withParam:(NSDictionary*)param
{
    NSDictionary* dict = param;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (EvtID == PLAY_EVT_RCV_FIRST_I_FRAME) {
            if (!_isInVC) {
                _videoIsReady();
            }
            _videoFinished = NO;
            _txLivePlayer.recordDelegate = self;
            
        }else if (EvtID == PLAY_EVT_PLAY_PROGRESS) {
            if (_startSeek) return ;
            // 避免滑动进度条松开的瞬间可能出现滑动条瞬间跳到上一个位置
            long long curTs = [[NSDate date]timeIntervalSince1970]*1000;
            if (llabs(curTs - _trackingTouchTS) < 500) {
                return;
            }
            _trackingTouchTS = curTs;
            
            float progress = [dict[EVT_PLAY_PROGRESS] floatValue];
            int intProgress = progress + 0.5;
            _logicView.playLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)(intProgress / 3600), (int)(intProgress / 60), (int)(intProgress % 60)];
            [_logicView.playProgress setValue:progress];
            
            float duration = [dict[EVT_PLAY_DURATION] floatValue];
            int intDuration = duration + 0.5;
            if (duration > 0 && _logicView.playProgress.maximumValue != duration) {
                [_logicView.playProgress setMaximumValue:duration];
                _logicView.playDuration.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)(intDuration / 3600), (int)(intDuration / 60 % 60), (int)(intDuration % 60)];
            }
            return ;
        } else if (EvtID == PLAY_ERR_NET_DISCONNECT || EvtID == PLAY_EVT_PLAY_END) {
            [self stopRtmp];
            _videoPause  = NO;
            _videoFinished = YES;
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            [_logicView.playProgress setValue:0];
            _logicView.playLabel.text = @"00:00:00";
            
            if (_isLivePlay)
            {
                if (!_isErrorAlert)
                {
                    _isErrorAlert = YES;
                    [HUDHelper alertTitle:@"提示" message:kErrorMsgNetDisconnected cancel:@"确定" action:^{
                        [self closeVCWithRefresh:YES popViewController:YES];
                    }];
                }
            }else{
                [_logicView.playBtn setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            }
            
        } else if (EvtID == PLAY_EVT_PLAY_LOADING){
            
        }
        
        NSLog(@"evt:%d,%@", EvtID, dict);
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
        NSString *serverIP = [dict valueForKey:NET_STATUS_SERVER_IP];
        int codecCacheSize = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_CACHE] intValue];
        int nCodecDropCnt = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_DROP_CNT] intValue];
        
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
        if (width > height && !_rotate) {
            [_txLivePlayer setRenderRotation:HOME_ORIENTATION_RIGHT];
            _rotate = YES;
        }
        
    });
}


- (void)clickShare:(UIButton *)button {
    __weak typeof(self) weakSelf = self;
    //显示分享面板
    [UMSocialUIManager showShareMenuViewInView:nil sharePlatformSelectionBlock:^(UMSocialShareSelectionView *shareSelectionView, NSIndexPath *indexPath, UMSocialPlatformType platformType) {
        //        [weakSelf disMissShareMenuView];
        [weakSelf shareDataWithPlatform:platformType];
        
    }];
}

-(void)onRecvGroupDeleteMsg {
    [self closeVC:NO];
    if (!_isErrorAlert) {
        _isErrorAlert = YES;
        [HUDHelper alert:kErrorMsgLiveStopped cancel:@"确定" action:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }
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
    
    
    /* 以下分享类型，开发者可根据需求调用 */
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
        
        
        NSString *message = nil;
        if (!error) {
            message = [NSString stringWithFormat:@"分享成功"];
        } else {
            if (error.code == UMSocialPlatformErrorType_Cancel) {
                message = [NSString stringWithFormat:@"分享取消"];
            } else if (error.code == UMSocialPlatformErrorType_NotInstall) {
                message = [NSString stringWithFormat:@"应用未安装"];
            } else {
                message = [NSString stringWithFormat:@"分享失败，失败原因(Code＝%d)\n",(int)error.code];
            }
            
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

@end
