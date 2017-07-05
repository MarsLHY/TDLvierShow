#import <Foundation/Foundation.h>
#import "TCPlayViewController_LinkMic.h"
#import "TDPlayDecorateView.h"
#import "TCPlayerModel.h"
#import "TCPusherModel.h"
#import "TXRTMPSDK/TXLivePush.h"
#import "TCLinkMicSmallPlayer.h"


#define VIDEO_VIEW_WIDTH            100
#define VIDEO_VIEW_HEIGHT           150
#define VIDEO_VIEW_MARGIN_BOTTOM    56
#define VIDEO_VIEW_MARGIN_RIGHT     8


@interface TCPlayViewController_LinkMic()<ITCLivePushListener, ITCLivePlayListener>
{
    TCLiveInfo*             _liveInfo;
    
    BOOL                    _isBeingLinkMic;
    BOOL                    _isWaitingResponse;
    
    NSString*               _playUrl;
    
    UITextView *            _waitingNotice;
    TDPlayDecorateView*     _logicView;
    UIButton*               _btnCamera;
    UIButton*               _btnLinkMic;
    
    TCLinkMicModel*           _tcLinkMicMgr;
    
    TCLivePushListenerImpl* _txLivePushListener;
    TXLivePushConfig *      _txLivePushConfig;
    TXLivePush *            _txLivePush;
    
    NSMutableArray*         _playItems;         //小画面播放列表
    NSArray*                _streamsNeedToPlay; //大主播在接受连麦时，返回的正在的大主播连麦的小主播列表
}@end


@implementation TCPlayViewController_LinkMic

-(id)initWithPlayInfo:(TCLiveInfo *)info  videoIsReady:(videoIsReadyBlock)videoIsReady {
    
    _liveInfo = info;
    _isBeingLinkMic = false;
    _isWaitingResponse = false;
    
    _tcLinkMicMgr = [TCLinkMicModel sharedInstance];
    _tcLinkMicMgr.listener = self;
    
    _txLivePushListener = [[TCLivePushListenerImpl alloc] init];
    _txLivePushListener.delegate = self;
    _txLivePushConfig = [[TXLivePushConfig alloc] init];
    _txLivePushConfig.frontCamera = YES;
    _txLivePushConfig.pauseFps = 10;
    _txLivePushConfig.pauseTime = 300;
    _txLivePushConfig.pauseImg = [UIImage imageNamed:@"pause_publish.jpg"];
    _txLivePushConfig.enableAudioPreview = YES;
    _txLivePush = [[TXLivePush alloc] initWithConfig:_txLivePushConfig];
    _txLivePush.delegate = _txLivePushListener;
    
    self = [super initWithPlayInfo:info videoIsReady:videoIsReady];
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    self.enableLinkMic = YES;
    [super viewWillAppear:animated];
    
    if (_liveInfo.type == TCLiveListItemType_Live) {
        if (_logicView == nil) {
            _logicView = [self findPlayDecorateView];
        }
        
        if (_btnLinkMic == nil) {
            if (_logicView != nil && _logicView.btnShare != nil) {
                int   icon_size = BOTTOM_BTN_ICON_WIDTH;
                float startSpace = 15;
                
                float icon_count = 8;
                float icon_center_interval = (_logicView.width - 2*startSpace - icon_size)/(icon_count - 1);
                float icon_center_y = _logicView.height - icon_size/2 - startSpace;
                
                CGRect rectBtnLog = _logicView.btnRecord.frame;
                //Button: 发起连麦
                _btnLinkMic = [UIButton buttonWithType:UIButtonTypeCustom];
                _btnLinkMic.center = CGPointMake(_logicView.btnRecord.center.x - icon_center_interval, icon_center_y);
                _btnLinkMic.bounds = CGRectMake(0, 0, CGRectGetWidth(rectBtnLog), CGRectGetHeight(rectBtnLog));
                [_btnLinkMic setImage:[UIImage imageNamed:@"linkmic_on"] forState:UIControlStateNormal];
                [_btnLinkMic addTarget:self action:@selector(clickBtnLinkMic:) forControlEvents:UIControlEventTouchUpInside];
                [_logicView addSubview:_btnLinkMic];
                
                //Button: 前置后置摄像头切换
                CGRect rectBtnLinkMic = _btnLinkMic.frame;
                _btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
                _btnCamera.center = CGPointMake(_btnLinkMic.center.x - icon_center_interval, icon_center_y);
                _btnCamera.bounds = CGRectMake(0, 0, CGRectGetWidth(rectBtnLinkMic), CGRectGetHeight(rectBtnLinkMic));
                [_btnCamera setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
                [_btnCamera addTarget:self action:@selector(clickBtnCamera:) forControlEvents:UIControlEventTouchUpInside];
                _btnCamera.hidden = YES;
                [_logicView addSubview:_btnCamera];
            }
        }
        
        //初始化连麦播放小窗口
        if (_playItems == nil) {
            _playItems = [NSMutableArray new];
            [self initPlayItem:1];
            [self initPlayItem:2];
            [self initPlayItem:3];
        }
        
        //logicView不能被连麦小窗口挡住
        [self.logicView removeFromSuperview];
        [self.view addSubview:self.logicView];
        
        //初始化连麦播放小窗口里的logView
        for (TCLinkMicSmallPlayer * item in _playItems) {
            if (item.logView == nil) {
                UIView * logView = [[UIView alloc] initWithFrame:item.videoView.frame];
                logView.backgroundColor = [UIColor clearColor];
                logView.hidden = YES;
                logView.backgroundColor = [UIColor whiteColor];
                logView.alpha  = 0.5;
                [self.view addSubview:logView];
                item.logView = logView;
            }
        }
    }
}

- (void) initPlayItem: (int)index {
    CGFloat width = self.view.size.width;
    CGFloat height = self.view.size.height;
    
    TCLinkMicSmallPlayer* playItem = [[TCLinkMicSmallPlayer alloc] init];
    playItem.videoView = [[UIView alloc] initWithFrame:CGRectMake(width - VIDEO_VIEW_WIDTH - VIDEO_VIEW_MARGIN_RIGHT, height - VIDEO_VIEW_MARGIN_BOTTOM - VIDEO_VIEW_HEIGHT * index, VIDEO_VIEW_WIDTH, VIDEO_VIEW_HEIGHT)];
    [self.view addSubview:playItem.videoView];
    
    playItem.livePlayListener = [[TCLivePlayListenerImpl alloc] init];
    playItem.livePlayListener.delegate = self;
    TXLivePlayConfig * playConfig = [[TXLivePlayConfig alloc] init];
    playItem.livePlayer = [[TXLivePlayer alloc] init];
    playItem.livePlayer.delegate = playItem.livePlayListener;
    [playItem.livePlayer setConfig: playConfig];
    [_playItems addObject:playItem];
}

- (void)onAppDidEnterBackGround:(UIApplication*)app {
    [super onAppDidEnterBackGround:app];
    if (_isBeingLinkMic) {
        [_txLivePush pausePush];
    }
}

- (void)onAppWillEnterForeground:(UIApplication*)app{
    [super onAppWillEnterForeground:app];
    if (_isBeingLinkMic) {
        [_txLivePush resumePush];
    }
}

-(void)closeVC:(BOOL)popViewController{
    [super closeVC:popViewController];
    [self stopLinkMic];
    [self hideWaitingNotice];
}

-(void)clickBtnLinkMic:(UIButton *)button {
    if (_isBeingLinkMic == NO) {
        //检查麦克风权限
        AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (statusAudio == AVAuthorizationStatusDenied) {
            [self toastTip:@"获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限"];
            return;
        }
        
        //是否有摄像头权限
        AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (statusVideo == AVAuthorizationStatusDenied) {
            [self toastTip:@"获取摄像头权限失败，请前往隐私-相机设置里面打开应用权限"];
            return;
        }
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            [self toastTip:@"系统不支持硬编码， 启动连麦失败"];            
            return;
        }
        
        [self startLinkMic];
    }
    else {
        [self stopLinkMic];
        [super startRtmp];
    }
}

-(void)clickBtnCamera:(UIButton *)button {
    if (_isBeingLinkMic) {
        [_txLivePush switchCamera];
    }
}

-(void)clickLog:(UIButton *)button{
    for (TCLinkMicSmallPlayer * item in _playItems) {
        [item showLogView:self.log_switch];
    }
    
    [super clickLog:button];
}

-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer{
    if (_isBeingLinkMic) {
        //手动聚焦
        CGPoint touchLocation = [gestureRecognizer locationInView: [self findFullScreenVideoView]];
        [_txLivePush setFocusPosition:touchLocation];
    }
    
    [super clickScreen:gestureRecognizer];
}

-(void) onWaitLinkMicResponseTimeOut {
    if (_isWaitingResponse == YES) {
        _isWaitingResponse = NO;
        [_btnLinkMic setImage:[UIImage imageNamed:@"linkmic_on"] forState:UIControlStateNormal];
        [_btnLinkMic setEnabled:YES];
        [self hideWaitingNotice];
        [self toastTip:@"连麦请求超时，主播没有做出回应"];
        
        //连麦超时，允许录制小视频
        [self.logicView.btnRecord setEnabled:YES];
    }
}

-(void)startLinkMic {
    if (_isBeingLinkMic || _isWaitingResponse) {
        return;
    }
    
    [_tcLinkMicMgr sendLinkMicRequest:_liveInfo.userid];
    _isWaitingResponse = YES;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onWaitLinkMicResponseTimeOut) object:nil];
    [self performSelector:@selector(onWaitLinkMicResponseTimeOut) withObject:nil afterDelay:10];
    
    [_btnLinkMic setImage:[UIImage imageNamed:@"linkmic_off"] forState:UIControlStateNormal];
    [_btnLinkMic setEnabled:NO];
    
    [_logicView.logViewEvt setText:@""];
    [_logicView.statusView setText:@""];
    
    [self showWaitingNotice:@"等待主播接受"];
    
    //开始连麦，不允许录制小视频
    [self.logicView.btnRecord setEnabled:NO];
}

-(void)stopLinkMic {
    //结束推流
    [_txLivePush stopPreview];
    [_txLivePush stopPush];
    
    //结束拉流
    for (TCLinkMicSmallPlayer* playItem in _playItems) {
        [playItem stopLoading];
        [playItem stopPlay];
        [playItem emptyPlayInfo];
    }
    
    [_btnLinkMic setImage:[UIImage imageNamed:@"linkmic_on"] forState:UIControlStateNormal];
    [_btnLinkMic setEnabled:YES];
    
    _btnCamera.hidden = YES;
    
    [_logicView.logViewEvt setText:@""];
    [_logicView.statusView setText:@""];
    
    if (_isBeingLinkMic == YES) {
        TCUserInfoData* userInfo = [[TCUserInfoModel sharedInstance] getUserProfile];
        [_tcLinkMicMgr sendMemberExitNotify:_liveInfo.userid withExiterID:userInfo.identifier];
    }
    _isBeingLinkMic = NO;
    _isWaitingResponse = NO;
    
    //结束连麦，允许录制小视频
    [self.logicView.btnRecord setEnabled:YES];
}

-(void)handleLinkMicFailed:(NSString*)message {
    [self toastTip:message];
    //结束连麦
    [self stopLinkMic];
    //重新从CDN开始拉流
    [super startRtmp];
}

#pragma mark- TCLinkMicListener
-(void) onReceiveLinkMicResponse:(NSString*)userID withType:(TCLinkMicResponseType)rspType andParam:(NSDictionary*)param {
    DebugLog(@"onReceiveLinkMicResponse: isWaitingResponse = %d result = %d", _isWaitingResponse, rspType);

    if (_isWaitingResponse == NO) {
        return;
    }
    _isWaitingResponse = NO;
    [_btnLinkMic setEnabled:YES];
    [self hideWaitingNotice];
    
    if (LINKMIC_RESPONSE_TYPE_ACCEPT == rspType) {
        
        _isBeingLinkMic = YES;
        [_btnLinkMic setImage:[UIImage imageNamed:@"linkmic_off"] forState:UIControlStateNormal];
        [self toastTip:@"主播接受了您的连麦请求，开始连麦"];
        
        //请求推流地址
        TCUserInfoData * profile = [[TCUserInfoModel sharedInstance] getUserProfile];
        [[TCPusherModel sharedInstance] getPushUrlForLinkMic:profile.identifier title:@"连麦" coverPic: profile.coverURL nickName:profile.nickName headPic:profile.faceURL location:@"" handler:^(int errCode, NSString* pusherUrl, NSInteger timestamp, NSString* playUrl) {
            if (errCode == 0 && pusherUrl != nil && pusherUrl.length > 0) {
                _playUrl = playUrl;
                
                //兼容大主播是旧版本，小主播是新版本的情况：“新版本小主播推流地址后面加上混流参数mix=layer:s;session_id:xxx;t_id:1”
                //1、如果连麦的大主播是旧版本，保证和旧版本大主播连麦时，能够互相拉取到对方的低时延流，也能够保证混流成功
                //2、如果连麦的大主播是新版本，那么大主播推流地址后面带的是&mix=session_id:xxx，这种情况下可以互相拉取低时延流，也可以混流成功（不会触发自动混流，由大主播通过CGI调用的方式启动混流）
                NSString * sessionID = @"";
                if (param) {
                    sessionID = param[@"sessionID"];
                }
                if (sessionID && sessionID.length > 0) {
                    pusherUrl = [NSString stringWithFormat:@"%@&mix=layer:s;session_id:%@;t_id:1", pusherUrl, sessionID];
                }
                
                //结束从CDN拉流
                [self stopRtmp];
                
                //开始连麦，启动推流
                _txLivePushListener.pushUrl = pusherUrl;
                [_txLivePush setVideoQuality:VIDEO_QUALITY_LINKMIC_SUB_PUBLISHER];
                [_txLivePush startPreview:[self findFullScreenVideoView]];
                [_txLivePush setBeautyFilterDepth:5 setWhiteningFilterDepth:0];
                [_txLivePush startPush:pusherUrl];
                
                //推流允许前后切换摄像头
                _btnCamera.hidden = NO;
                
                //查找空闲的TCLinkMicSmallPlayer, 开始loading
                for (TCLinkMicSmallPlayer * playItem in _playItems) {
                    if (playItem.userID == nil || playItem.userID.length == 0) {
                        playItem.pending = YES;
                        playItem.userID = _liveInfo.userid;
                        [playItem startLoading];
                        break;
                    }
                }
                
                //当前正在和大主播连麦的小主播列表
                if (param) {
                    _streamsNeedToPlay = param[@"streams"];
                }
            }
            else {
                [self toastTip:@"拉取连麦推流地址失败"];
                _isBeingLinkMic = NO;
                _isWaitingResponse = NO;
                [_btnLinkMic setImage:[UIImage imageNamed:@"linkmic_on"] forState:UIControlStateNormal];
            }
        }];
    }
    else if (LINKMIC_RESPONSE_TYPE_REJECT == rspType) {
        _isBeingLinkMic = NO;
        NSString * reason = @"";
        if (param) {
            reason = param[@"reason"];
        }
        if (reason && reason.length > 0) {
            [self toastTip:reason];
        }
        [_btnLinkMic setImage:[UIImage imageNamed:@"linkmic_on"] forState:UIControlStateNormal];
        
        //主播不接受连麦，允许录制小视频
        [self.logicView.btnRecord setEnabled:YES];
    }
}

-(void) onReceiveMemberJoinNotify:(NSString*)joinerID withPlayUrl:(NSString*)playUrl {
    if (_isBeingLinkMic != YES && _isWaitingResponse != YES) {
        return;
    }
    
    if (joinerID && [joinerID isEqualToString:_liveInfo.userid]) {
        return;
    }
    
    [self startPlayVideoStream:joinerID withPlayUrl:playUrl];
}

-(void) onReceiveMemberExitNotify:(NSString*)exiterID {
    if (exiterID && [exiterID isEqualToString:_liveInfo.userid]) {
        return;
    }
    
    [self stopPlayVideoStream:exiterID];
}

-(void) onReceiveKickoutNotify
{
    [self toastTip:@"不好意思，您被主播踢开"];
    //结束连麦
    [self stopLinkMic];
    //重新从CDN拉流播放
    [self startRtmp];
}


#pragma mark- ITCLivePushListener
-(void)onLivePushEvent:(NSString*) pushUrl withEvtID:(int)event andParam:(NSDictionary*)param {
    if (event == PUSH_EVT_PUSH_BEGIN) {             //开始推流事件通知
        //1.拉取主播的低时延流
        TCUserInfoData * profile = [[TCUserInfoModel sharedInstance] getUserProfile];
        [[TCPlayerModel sharedInstance] getPlayUrlWithSignature:profile.identifier originPlayUrl:_liveInfo.playurl handler:^(int errCode, NSString *playUrl) {
            if (errCode == 0 && playUrl != nil && playUrl.length > 0) {
                TCLinkMicSmallPlayer * playItem = [self getPlayItemByUserID:_liveInfo.userid];
                if (playItem) {
                    [playItem startPlay:playUrl];
                }
            }
            else {
                [self handleLinkMicFailed:@"获取防盗链key失败，结束连麦"];
            }
        }];
        
        //2.通知主播拉取自己的流
        [_tcLinkMicMgr sendMemberJoinNotify:_liveInfo.userid withJoinerID:profile.identifier andJoinerPlayUrl:_playUrl];
        
        //3.拉取其它正在和大主播连麦的小主播的视频流
        for (NSDictionary* item in _streamsNeedToPlay) {
            [self startPlayVideoStream:item[@"userID"] withPlayUrl:item[@"playUrl"]];
        }
    }
    else if (event == PUSH_ERR_NET_DISCONNECT) {    //推流失败事件通知
        [self handleLinkMicFailed:@"推流失败，结束连麦"];
    }
    else if (event == PUSH_WARNING_HW_ACCELERATION_FAIL) {
        [self handleLinkMicFailed:@"启动硬编码失败，结束连麦"];
    }
    
    [super onPlayEvent:event withParam:param];
}

-(void)onLivePushNetStatus:(NSString*) pushUrl withParam: (NSDictionary*) param {
    [super onNetStatus:param];
}


#pragma mark- ITCLivePlayListener
-(void)onLivePlayEvent:(NSString*) playUrl withEvtID:(int)event andParam:(NSDictionary*)param {
    TCLinkMicSmallPlayer * playItem = [self getPlayItemByStreamUrl:playUrl];
    if (playItem == nil) {
        return;
    }
    
    if (event == PLAY_EVT_PLAY_BEGIN) {
        [playItem stopLoading];
    }
    else if (event == PLAY_ERR_NET_DISCONNECT || event == PLAY_EVT_PLAY_END || event == PLAY_ERR_GET_RTMP_ACC_URL_FAIL) {
        if ([playItem.userID isEqualToString:_liveInfo.userid] == YES) {
            [self handleLinkMicFailed:@"主播的流拉取失败，结束连麦"];
        }
        else {
            [self stopPlayVideoStream:playItem.userID];
        }
    }
    else if (event == PLAY_WARNING_HW_ACCELERATION_FAIL) {
        if ([playItem.userID isEqualToString:_liveInfo.userid] == YES) {
            [self handleLinkMicFailed:@"启动硬解码失败，结束连麦"];
        }
        else {
            [self stopPlayVideoStream:playItem.userID];
        }
    }
    
    [playItem appendEventMsg:event andParam:param];
}

-(void)onLivePlayNetStatus:(NSString*) playUrl withParam: (NSDictionary*) param {
    TCLinkMicSmallPlayer * playItem = [self getPlayItemByStreamUrl:playUrl];
    if (playItem) {
        [playItem freshStatusMsg:param];
    }
}

#pragma mark- MiscFunc
-(TCLinkMicSmallPlayer*) getPlayItemByUserID:(NSString*)userID {
    if (userID) {
        for (TCLinkMicSmallPlayer* playItem in _playItems) {
            if ([userID isEqualToString:playItem.userID]) {
                return playItem;
            }
        }
    }
    return nil;
}

-(TCLinkMicSmallPlayer*) getPlayItemByStreamUrl:(NSString*)streamUrl {
    if (streamUrl) {
        for (TCLinkMicSmallPlayer* playItem in _playItems) {
            if ([streamUrl isEqualToString:playItem.playUrl]) {
                return playItem;
            }
        }
    }
    return nil;
}

-(void) startPlayVideoStream: (NSString*)userID withPlayUrl:(NSString*)playUrl {
    if (userID == nil || userID.length == 0 || playUrl == nil || playUrl.length == 0) {
        return;
    }
    
    BOOL bExist = NO;
    for (TCLinkMicSmallPlayer * item in _playItems) {
        if ([userID isEqualToString:item.userID] /* || [playUrl isEqualToString:item.playUrl]*/) {
            bExist = YES;
            break;
        }
    }
    if (bExist == YES) {
        return;
    }
    
    for (TCLinkMicSmallPlayer * playItem in _playItems) {
        if (playItem.userID == nil || playItem.userID.length == 0) {
            playItem.userID = userID;
            [playItem startLoading];
            [playItem startPlay:playUrl];
            break;
        }
    }
}

-(void) stopPlayVideoStream: (NSString*)userID {
    TCLinkMicSmallPlayer * playItem = [self getPlayItemByUserID:userID];
    if (playItem) {
        [playItem stopLoading];
        [playItem stopPlay];
        [playItem emptyPlayInfo];
    }
}

-(TDPlayDecorateView*) findPlayDecorateView {
    for (id view in self.view.subviews) {
        if ([view isKindOfClass:[TDPlayDecorateView class]]) {
            return (TDPlayDecorateView*)view;
        }
    }
    return nil;
}

-(UIView*) findFullScreenVideoView {
    for (id view in self.view.subviews) {
        if ([view isKindOfClass:[UIView class]] && ((UIView*)view).tag == FULL_SCREEN_PLAY_VIDEO_VIEW) {
            return (UIView*)view;
        }
    }
    return nil;
}

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

-(void) freshWaitingNotice:(NSString*) notice withIndex: (NSNumber*)numIndex {
    if (_waitingNotice) {
        long index = [numIndex longValue];
        ++index;
        index = index % 4;
        
        NSString * text = notice;
        for (long i = 0; i < index; ++i) {
            text = [NSString stringWithFormat:@"%@.....", text];
        }
        [_waitingNotice setText:text];
        
        numIndex = [NSNumber numberWithLong:index];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^(){
            [self freshWaitingNotice:notice withIndex: numIndex];
        });
    }
}

-(void) showWaitingNotice: (NSString*)notice {
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    if (_waitingNotice == nil) {
        _waitingNotice = [[UITextView alloc] init];
        _waitingNotice.editable = NO;
        _waitingNotice.selectable = NO;
        
        frameRC.size.height = [self heightForString:_waitingNotice andWidth:frameRC.size.width];
        _waitingNotice.frame = frameRC;
        _waitingNotice.backgroundColor = [UIColor whiteColor];
        _waitingNotice.alpha = 0.5;
        
        [self.view addSubview:_waitingNotice];
    }
    
    _waitingNotice.text = notice;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^(){
        [self freshWaitingNotice:notice withIndex: [NSNumber numberWithLong:0]];
    });
}

-(void) hideWaitingNotice {
    if (_waitingNotice) {
        [_waitingNotice removeFromSuperview];
        _waitingNotice = nil;
    }
}

@end
