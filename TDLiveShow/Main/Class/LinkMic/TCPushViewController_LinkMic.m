#import <Foundation/Foundation.h>
#import "TCPushViewController_LinkMic.h"
#import "TCLinkMicModel.h"
#import "TCPlayerModel.h"
#import "TCPusherModel.h"
#import <Foundation/NSDate.h>
#import "UIView+CustomAutoLayout.h"
#import "TCLinkMicSmallPlayer.h"


#define MAX_LINKMIC_MEMBER_SUPPORT  3

#define VIDEO_VIEW_WIDTH            100
#define VIDEO_VIEW_HEIGHT           150
#define VIDEO_VIEW_MARGIN_BOTTOM    56
#define VIDEO_VIEW_MARGIN_RIGHT     8


@interface TCPushViewController_LinkMic()<ITCLivePlayListener>
{
    NSString*               _sessionId;
    NSString*               _userIdRequest;
    NSMutableArray*         _playItems;
    NSMutableSet*           _setLinkMemeber;
    TCLinkMicModel*           _tcLinkMicMgr;

    BOOL                    _isSupprotHardware;
}
@end


@implementation TCPushViewController_LinkMic

- (instancetype)initWithPublishInfo:(TCLiveInfo *)liveInfo {
    _sessionId = [self getLinkMicSessionID];
    
    _playItems = [NSMutableArray array];

    _setLinkMemeber = [NSMutableSet set];

    _tcLinkMicMgr = [TCLinkMicModel sharedInstance];
    _tcLinkMicMgr.listener = self;
    
    _isSupprotHardware = ( [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0);

    return [super initWithPublishInfo:liveInfo];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //初始化连麦播放小窗口
    [self initPlayItem: 1];
    [self initPlayItem: 2];
    [self initPlayItem: 3];
    
    //logicView不能被连麦小窗口挡住
    [self.logicView removeFromSuperview];
    [self.view addSubview:self.logicView];
    
    //初始化连麦播放小窗口里的logView
    for (TCLinkMicSmallPlayer * item in _playItems) {
        UIView * logView = [[UIView alloc] initWithFrame:item.videoView.frame];
        logView.backgroundColor = [UIColor clearColor];
        logView.hidden = YES;
        logView.backgroundColor = [UIColor whiteColor];
        logView.alpha  = 0.5;
        [self.view addSubview:logView];
        item.logView = logView;
    }
    
    //初始化连麦播放小窗口里的踢人Button
    CGFloat width = self.view.size.width;
    CGFloat height = self.view.size.height;
    int index = 1;
    for (TCLinkMicSmallPlayer* playItem in _playItems) {
        playItem.btnKickout = [[UIButton alloc] initWithFrame:CGRectMake(width - BOTTOM_BTN_ICON_WIDTH/2 - VIDEO_VIEW_MARGIN_RIGHT - 5, height - VIDEO_VIEW_MARGIN_BOTTOM - VIDEO_VIEW_HEIGHT * index + 5, BOTTOM_BTN_ICON_WIDTH/2, BOTTOM_BTN_ICON_WIDTH/2)];
        [playItem.btnKickout addTarget:self action:@selector(onClickBtnKickout:) forControlEvents:UIControlEventTouchUpInside];
        [playItem.btnKickout setImage:[UIImage imageNamed:@"kickout"] forState:UIControlStateNormal];
        playItem.btnKickout.hidden = YES;
        [self.view addSubview:playItem.btnKickout];
        
        ++index;
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
    [playItem.livePlayer setRenderMode:RENDER_MODE_FILL_EDGE];
    playItem.pending = false;
    [_playItems addObject:playItem];
}

- (void) onClickBtnKickout:(UIButton *)btn {
    for (TCLinkMicSmallPlayer* playItem in _playItems) {
        if (playItem.btnKickout == btn) {
            //混流：减少一路
            [[TCStreamMergeMgr shareInstance] delSubVideoStream:playItem.playUrl];
            
            //通知其它小主播：有小主播退出连麦
            [self broadcastMemberExitNotify:playItem.userID];
            
            [_tcLinkMicMgr kickoutLinkMicMember:playItem.userID];
            [_setLinkMemeber removeObject:playItem.userID];
            [playItem stopPlay];
            [playItem emptyPlayInfo];
            if ([_setLinkMemeber count] == 0) {
                //无人连麦，设置视频质量：高清
                [self.txLivePublisher setVideoQuality:VIDEO_QUALITY_HIGH_DEFINITION];
            }
            break;
        }
    }
}

-(void) clickLog:(UIButton*) btn {
    for (TCLinkMicSmallPlayer * item in _playItems) {
        [item showLogView:self.log_switch];
    }
    
    [super clickLog:btn];
}

-(BOOL)startRtmp {
    //兼容大主播是新版本，小主播是旧版本的情况：“新版本大主播推流地址后面带上&mix=session_id:xxx”
    //1、采用这种方式，保证旧版本小主播可以拉到大主播的加速地址
    //2、新版本大主播拉小主播的加速地址，有没有session_id都没有影响
    //3、新版本混流由大主播调用CGI的方式启动混流，可以正常混流
    self.rtmpUrl = [NSString stringWithFormat:@"%@&mix=session_id:%@", self.rtmpUrl, _sessionId];
    
    [[TCStreamMergeMgr shareInstance] setMainVideoStream:self.rtmpUrl];
    return [super startRtmp];
}

-(void)closeRTMP {
    [super closeRTMP];

    for (TCLinkMicSmallPlayer* playItem in _playItems) {
        [playItem stopPlay];
    }
    
    //混流：清除状态
    [[TCStreamMergeMgr shareInstance] resetMergeState];
}

-(void) onLinkMicTimeOut:(NSString*)userID {
    if (userID) {
        TCLinkMicSmallPlayer* playItem = [self getPlayItemByUserID:userID];
        if (playItem && playItem.pending == YES){
            [_tcLinkMicMgr kickoutLinkMicMember:playItem.userID];
            [_setLinkMemeber removeObject:userID];
            [playItem stopPlay];
            [playItem emptyPlayInfo];
            [self toastTip: [NSString stringWithFormat: @"%@连麦超时", userID]];
            if ([_setLinkMemeber count] == 0) {
                //无人连麦，设置视频质量：高清
                [self.txLivePublisher setVideoQuality:VIDEO_QUALITY_HIGH_DEFINITION];
            }
        }
    }
}

-(void) handleLinkMicFailed:(NSString*)userID message:(NSString*)message {
    if (userID) {
        TCLinkMicSmallPlayer* playItem = [self getPlayItemByUserID:userID];
        if (playItem == nil){
            return;
        }
        
        if (playItem.pending == YES) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onLinkMicTimeOut:) object:userID];
        }

        [_tcLinkMicMgr kickoutLinkMicMember:userID];
        [_setLinkMemeber removeObject:userID];

        [playItem stopPlay];
        [playItem emptyPlayInfo];

        if (message != nil && message.length > 0) {
            [self toastTip:message];
        }
        
        if ([_setLinkMemeber count] == 0) {
            //无人连麦，设置视频质量：高清
            [self.txLivePublisher setVideoQuality:VIDEO_QUALITY_HIGH_DEFINITION];
        }
    }
}

#pragma mark- TCLinkMicListener
-(void) handleTimeOutRequest:(UIAlertView*)alertView {
    _userIdRequest = @"";
    if (alertView) {
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
    }
}

-(void) onReceiveLinkMicRequest:(NSString*)userID withNickName:(NSString*) nickName {
    if (!_isSupprotHardware) {
        [_tcLinkMicMgr sendLinkMicResponse:userID withType:LINKMIC_RESPONSE_TYPE_REJECT andParams:@{@"reason": @"主播不支持连麦"}];
        return;
    }
    
    if ([_setLinkMemeber count] >= MAX_LINKMIC_MEMBER_SUPPORT) {
        [_tcLinkMicMgr sendLinkMicResponse:userID withType:LINKMIC_RESPONSE_TYPE_REJECT andParams:@{@"reason": @"主播端连麦人数超过最大限制"}];
    }
    else if (_userIdRequest && _userIdRequest.length > 0) {
        [_tcLinkMicMgr sendLinkMicResponse:userID withType:LINKMIC_RESPONSE_TYPE_REJECT andParams:@{@"reason": @"请稍后，主播正在处理其它人的连麦请求"}];
    }
    else {
        _userIdRequest = userID;
        UIAlertView* _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:[NSString stringWithFormat:@"%@向您发起连麦请求", nickName]  delegate:self cancelButtonTitle:@"拒绝" otherButtonTitles:@"接受", nil];
        
        [_alertView show];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleTimeOutRequest:) object:_alertView];
        [self performSelector:@selector(handleTimeOutRequest:) withObject:_alertView afterDelay:10];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (_userIdRequest != nil && _userIdRequest.length > 0) {
        if (buttonIndex == 0) {
            //拒绝连麦
            [_tcLinkMicMgr sendLinkMicResponse:_userIdRequest withType:LINKMIC_RESPONSE_TYPE_REJECT andParams:@{@"reason": @"主播拒绝了您的连麦请求"}];
        }
        else if (buttonIndex == 1) {
            //接受连麦
            [_tcLinkMicMgr sendLinkMicResponse:_userIdRequest withType:LINKMIC_RESPONSE_TYPE_ACCEPT andParams:@{@"sessionID": _sessionId, @"streams": [self getCurrentPlayStreams]}];
            
            //查找空闲的TCLinkMicSmallPlayer, 开始loading
            for (TCLinkMicSmallPlayer * playItem in _playItems) {
                if (playItem.userID == nil || playItem.userID.length == 0) {
                    playItem.pending = YES;
                    playItem.userID = _userIdRequest;
                    [playItem startLoading];
                    break;
                }
            }
            
            //设置超时逻辑
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onLinkMicTimeOut:) object:_userIdRequest];
            [self performSelector:@selector(onLinkMicTimeOut:) withObject:_userIdRequest afterDelay:15];
            
            //加入连麦成员列表
            [_setLinkMemeber addObject:_userIdRequest];
            
            //第一个小主播加入连麦，设置视频质量：连麦大主播
            if ([_setLinkMemeber count] == 1) {
                [self.txLivePublisher setVideoQuality:VIDEO_QUALITY_LINKMIC_MAIN_PUBLISHER];
            }

        }
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleTimeOutRequest:) object:alertView];
    _userIdRequest = @"";
}

-(void) onReceiveMemberJoinNotify:(NSString*)userID withPlayUrl:(NSString*)strPlayUrl {
    if (userID == nil || strPlayUrl == nil) {
        return;
    }
    
    DebugLog(@"onReceiveMemberJoinNotify: userID = %@ playUrl = %@", userID, strPlayUrl);
    
    if ([_setLinkMemeber containsObject:userID] == NO) {
        return;
    }
    
    TCLinkMicSmallPlayer * item = [self getPlayItemByUserID:userID];
    if (item == nil) {
        return;
    }

    //拉取连麦观众的低时延流
    TCUserInfoData * profile = [[TCUserInfoModel sharedInstance] getUserProfile];
    [[TCPlayerModel sharedInstance] getPlayUrlWithSignature:profile.identifier originPlayUrl:strPlayUrl handler:^(int errCode, NSString *playUrl) {
        if (errCode == 0 && playUrl != nil && playUrl.length > 0) {
            [item startPlay:playUrl];
        }
        else {
            [self handleLinkMicFailed: item.userID message: @"获取防盗链key失败，结束连麦"];
        }
    }];
}

-(void) onReceiveMemberExitNotify:(NSString*)userID {
    if (userID == nil || userID.length == 0) {
        return;
    }
    
    DebugLog(@"onReceiveMemberExitNotify: userID = %@", userID);
    
    TCLinkMicSmallPlayer* playItem = [self getPlayItemByUserID:userID];
    if (playItem == nil) {
        DebugLog(@"onReceiveMemberExitNotify: invalid notify");
        return;
    }
    
    //混流：减少一路
    [[TCStreamMergeMgr shareInstance] delSubVideoStream:playItem.playUrl];
    
    //通知其它小主播：有小主播退出连麦
    [self broadcastMemberExitNotify:playItem.userID];

    [playItem stopPlay];
    [playItem emptyPlayInfo];
    
    [_setLinkMemeber removeObject:userID];
    
    if ([_setLinkMemeber count] == 0) {
        //无人连麦，设置视频质量：高清
        [self.txLivePublisher setVideoQuality:VIDEO_QUALITY_HIGH_DEFINITION];
    }
}


#pragma mark- ITCLivePlayListener
-(void)onLivePlayEvent:(NSString*) strStreamUrl withEvtID:(int)event andParam:(NSDictionary*)param {
    TCLinkMicSmallPlayer * playItem = [self getPlayItemByStreamUrl:strStreamUrl];
    if (playItem == nil) {
        return;
    }
    
    if (event == PLAY_ERR_NET_DISCONNECT || event == PLAY_EVT_PLAY_END || event == PLAY_ERR_GET_RTMP_ACC_URL_FAIL) {
        if (playItem.pending == YES) {
            [self handleLinkMicFailed:playItem.userID message:@"拉流失败，结束连麦"];
        }
        else {
            [self handleLinkMicFailed:playItem.userID message:@"连麦观众视频断流，结束连麦"];
            
            //混流：减少一路
            [[TCStreamMergeMgr shareInstance] delSubVideoStream:strStreamUrl];
        }
    }
    
    if (event == PLAY_EVT_PLAY_BEGIN) {
        if (playItem.pending == YES) {
            playItem.pending = NO;
            playItem.btnKickout.hidden = NO;
            [playItem stopLoading];
            
            //混流：增加一路
            [[TCStreamMergeMgr shareInstance] addSubVideoStream:strStreamUrl];
            
            //通知其它小主播：有新的小主播加入连麦
            [self broadcastMemberJoinNotify:playItem.userID withPlayUrl:playItem.playUrl];
        }
    }
    
    if (event == PUSH_WARNING_HW_ACCELERATION_FAIL || event == PLAY_WARNING_HW_ACCELERATION_FAIL) {
        [self handleLinkMicFailed:playItem.userID message:@"系统不支持硬编或硬解"];
        _isSupprotHardware = NO;
    }
    
    [playItem appendEventMsg:event andParam:param];
}

-(void)onLivePlayNetStatus:(NSString*) playUrl withParam: (NSDictionary*) param {
    TCLinkMicSmallPlayer * playItem = [self getPlayItemByStreamUrl:playUrl];
    if (playItem) {
        [playItem freshStatusMsg:param];
    }
}

-(void) onNetStatus:(NSDictionary*) param {
    dispatch_async(dispatch_get_main_queue(), ^{
        int width  = [(NSNumber*)[param valueForKey:NET_STATUS_VIDEO_WIDTH] intValue];
        int height = [(NSNumber*)[param valueForKey:NET_STATUS_VIDEO_HEIGHT] intValue];
        [[TCStreamMergeMgr shareInstance] setMainVideoStreamResolution: CGSizeMake(width, height)];
    });
    [super onNetStatus:param];
}

#pragma mark- MiscFunc
- (NSString*) getLinkMicSessionID {
    //说明：
    //1.sessionID是混流依据，sessionID相同的流，后台混流Server会混为一路视频流；因此，sessionID必须全局唯一
    
    //2.直播码频道ID理论上是全局唯一的，使用直播码作为sessionID是最为合适的
    //NSString* strSessionID = [TCLinkMicModel getStreamIDByStreamUrl:self.rtmpUrl];
    
    //3.直播码是字符串，混流Server目前只支持64位数字表示的sessionID，暂时按照下面这种方式生成sessionID
    //  待混流Server改造完成后，再使用直播码作为sessionID
    
    UInt64 timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    UInt64 sessionID = ((UInt64)3891 << 48 | timeStamp); // 3891是bizid, timeStamp是当前毫秒值
    
    return [NSString stringWithFormat:@"%llu", sessionID];
}

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

-(void) broadcastMemberJoinNotify:(NSString*)userID withPlayUrl:(NSString*) playUrl {
    //向所有正在和主播连麦的小主播发送通知：有新的小主播加入连麦
    for (TCLinkMicSmallPlayer * item in _playItems) {
        if (item.userID && item.userID.length > 0 && item.playUrl && item.playUrl.length > 0) {
            if ([item.userID isEqualToString:userID] != YES) {
                [_tcLinkMicMgr sendMemberJoinNotify:item.userID withJoinerID:userID andJoinerPlayUrl:playUrl];
            }
        }
    }
    
    //把所有正在连麦的小主播的拉流信息，发送给新加入的连麦者
    for (TCLinkMicSmallPlayer * item in _playItems) {
        if (item.userID && item.userID.length > 0 && item.playUrl && item.playUrl.length > 0) {
            if ([item.userID isEqualToString:userID] != YES) {
                [_tcLinkMicMgr sendMemberJoinNotify:userID withJoinerID:item.userID andJoinerPlayUrl:item.playUrl];
            }
        }
    }
}

-(void) broadcastMemberExitNotify:(NSString*)userID {
    //向所有正在和主播连麦的小主播发送通知：有小主播退出连麦
    for (TCLinkMicSmallPlayer * item in _playItems) {
        if (item.userID && item.userID.length > 0 && item.playUrl && item.playUrl.length > 0) {
            if ([item.userID isEqualToString:userID] != YES) {
                [_tcLinkMicMgr sendMemberExitNotify:item.userID withExiterID:userID];
            }
        }
    }
}

-(NSArray*) getCurrentPlayStreams {
    NSMutableArray * array = [NSMutableArray new];
    for (TCLinkMicSmallPlayer * item in _playItems) {
        if (item.userID && item.userID.length > 0 && item.playUrl && item.playUrl.length > 0) {
            [array addObject:@{@"userID": item.userID, @"playUrl": item.playUrl}];
        }
    }
    return array;
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

@end
