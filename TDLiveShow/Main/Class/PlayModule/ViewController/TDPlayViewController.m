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
#import "TXRTMPSDK/TXLivePlayer.h"
#import "TDLiveListModel.h"
@interface TDPlayViewController ()
{
    TXLivePlayer *       _txLivePlayer;
    TXLivePlayConfig*    _config;
    
    NSString             *_rtmpUrl;
    TX_Enum_PlayType     _playType;
}

@end

@implementation TDPlayViewController
{
    
}

- (id)initWithPlayInfo:(TDLiveInfo *)info{
    if (self == [super init]) {
        _txLivePlayer =[[TXLivePlayer alloc] init];
    }
    return self;
}

-(BOOL)startPlay {
    if (![self checkPlayUrl:_rtmpUrl]) {
        return NO;
    }
    
    NSArray* ver = [TXLivePlayer getSDKVersion];
    if ([ver count] >= 4) {
       
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
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@%d", kErrorMsgRtmpPlayFailed, result]];
            [SVProgressHUD dismissWithDelay:1];
            return NO;
        }
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    
    return YES;
}

-(BOOL)checkPlayUrl:(NSString*)playUrl {
    if (!([playUrl hasPrefix:@"http:"] || [playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"rtmp:"] )) {
        [SVProgressHUD showWithStatus:@"播放地址不合法，目前仅支持rtmp,flv,hls,mp4播放方式!"];
        [SVProgressHUD dismissWithDelay:1];
        return NO;
    }
    
    /*
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
    */
    return YES;
}

- (void)closeVCWithRefresh:(BOOL)refresh popViewController: (BOOL)popViewController {
    [self stopRtmp];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    /*
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
     */
    
    if (popViewController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
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

@end
