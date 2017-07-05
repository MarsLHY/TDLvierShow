#import <Foundation/Foundation.h>
#import "TCLinkMicModel.h"
#import "TCUserInfoModel.h"

static TCLinkMicModel *_sharedInstance = nil;


@implementation TCLinkMicModel

-(instancetype)init {
    self = [super init];

    return self;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _sharedInstance = [[TCLinkMicModel alloc] init];
    });
    return _sharedInstance;
}

-(void) sendLinkMicRequest:(NSString*)toUserID {
    [self sendMessage:toUserID command:LINKMIC_CMD_REQUEST withParam:@""];
}

-(void) sendLinkMicResponse:(NSString*)toUserID withType:(TCLinkMicResponseType)rspType andParams:(NSDictionary*)param {
    int cmd = -1;
    NSDictionary* dict = nil;
    switch (rspType) {
        case LINKMIC_RESPONSE_TYPE_ACCEPT:
            cmd = LINKMIC_CMD_ACCEPT;
            dict = @{@"sessionID": param[@"sessionID"], @"streams": param[@"streams"]};
            break;

        case LINKMIC_RESPONSE_TYPE_REJECT:
            cmd = LINKMIC_CMD_REJECT;
            dict = @{@"reason": param[@"reason"]};
            break;
 
        default:
            break;
    }
    
    if (cmd != -1) {
        NSData* data = [TCUtil dictionary2JsonData:dict];
        if (data) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self sendMessage:toUserID command:cmd withParam:content];
        }
    }
}

-(void) sendMemberJoinNotify:(NSString*)toUserID withJoinerID:(NSString*)joinerID andJoinerPlayUrl:(NSString*)playUrl {
    NSDictionary* dict = @{@"joinerID": joinerID, @"playUrl": playUrl};
    NSData* data = [TCUtil dictionary2JsonData:dict];
    if (data) {
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self sendMessage:toUserID command:LINKMIC_CMD_MEMBER_JOIN_NOTIFY withParam:content];
    }
}

-(void) sendMemberExitNotify:(NSString*)toUserID withExiterID:(NSString*)exiterID{
    NSDictionary* dict = @{@"exiterID": exiterID};
    NSData* data = [TCUtil dictionary2JsonData:dict];
    if (data) {
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self sendMessage:toUserID command:LINKMIC_CMD_MEMBER_EXIT_NOTIFY withParam:content];
    }
}

-(void) kickoutLinkMicMember:(NSString*)toUserID {
    [self sendMessage:toUserID command:LINKMIC_CMD_KICK_MEMBER withParam:@""];
}

- (void)sendMessage:(NSString *)userID command:(int)cmd withParam:(NSString*) param {
    if (userID == nil || userID.length == 0) {
        return;
    }
    
    TCUserInfoData* userInfo = [[TCUserInfoModel sharedInstance] getUserProfile];
    NSDictionary* dict = @{@"userAction":@(cmd), @"userId":TC_PROTECT_STR(userInfo.identifier),@"nickName":TC_PROTECT_STR(userInfo.nickName),@"param":TC_PROTECT_STR(param)};
    
    NSData* data = [TCUtil dictionary2JsonData:dict];
    NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    TIMTextElem *textElem = [[TIMTextElem alloc] init];
    [textElem setText:content];
    
    TIMMessage *timMsg = [[TIMMessage alloc] init];
    [timMsg addElem:textElem];
    
    TIMConversation * c2cConversation = [[TIMManager sharedInstance] getConversation:TIM_C2C receiver:userID];
    
    [c2cConversation sendMessage:timMsg succ:^{
        DebugLog(@"sendMessage success, cmd:%d, toUser:%s", cmd, [userID UTF8String]);
    } fail:^(int code, NSString *msg) {
        DebugLog(@"sendMessage failed, cmd:%d, toUser:%s, code:%d, errmsg:%@", cmd, [userID UTF8String], code, msg);
    }];
}

-(BOOL) handleC2CMessageReceived:(TIMMessage *)msg {
    if (msg == nil || _listener == nil) {
        return NO;
    }
    
    TCUserInfoData* userInfo = [[TCUserInfoModel sharedInstance] getUserProfile];
    if (userInfo == nil) {
        DebugLog(@"getUserProfile failed");
        return NO;
    }
    
    if([msg.sender isEqualToString:userInfo.identifier]) {
        DebugLog(@"recevie a self-msg");
        return NO;
    }
    
    for(int index = 0; index < [msg elemCount]; index++) {
        TIMElem *elem = [msg getElem:index];
        if(elem && [elem isKindOfClass:[TIMTextElem class]]) {
            TIMTextElem *textElem = (TIMTextElem *)elem;
            if (textElem == nil) {
                DebugLog(@"invalid msg-element");
                continue;
            }
            
            NSString *msgText   = textElem.text;
            NSDictionary* dict  = [TCUtil jsonData2Dictionary:msgText];
            
            if (dict) {
                NSNumber * action   = dict[@"userAction"];
                NSString * userID   = dict[@"userId"];
                NSString * nickName = dict[@"nickName"];
                NSString * param    = dict[@"param"];
                
                int actionValue = 0;
                if (action) {
                    actionValue = [action intValue];
                }
                
                if (actionValue >= LINKMIC_CMD_REQUEST && actionValue <= LINKMIC_CMD_KICK_MEMBER) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        int actionValue = [action intValue];
                        switch (actionValue) {
                            case LINKMIC_CMD_REQUEST:
                                [_listener onReceiveLinkMicRequest: userID withNickName:nickName];
                                break;
                                
                            case LINKMIC_CMD_ACCEPT:
                            {
                                NSDictionary* dictBody = nil;
                                if (param) {
                                    dictBody = [TCUtil jsonData2Dictionary:param];
                                }
                                [_listener onReceiveLinkMicResponse: userID withType:LINKMIC_RESPONSE_TYPE_ACCEPT andParam:dictBody];
                                break;
                            }
                                
                            case LINKMIC_CMD_REJECT:
                            {
                                NSDictionary* dictBody = nil;
                                if (param) {
                                    dictBody = [TCUtil jsonData2Dictionary:param];
                                }
                                [_listener onReceiveLinkMicResponse: userID withType:LINKMIC_RESPONSE_TYPE_REJECT andParam:dictBody];
                                break;
                            }
                                
                            case LINKMIC_CMD_MEMBER_JOIN_NOTIFY:
                            {
                                NSString * strJoinerID = nil;
                                NSString * strPlayUrl = nil;
                                if (param) {
                                    NSDictionary* dictBody  = [TCUtil jsonData2Dictionary:param];
                                    if (dictBody) {
                                        if ([[dictBody allKeys] containsObject:@"joinerID"]) {
                                            strJoinerID = [dictBody objectForKey:@"joinerID"];
                                        }
                                        if ([[dictBody allKeys] containsObject:@"playUrl"]) {
                                            strPlayUrl = [dictBody objectForKey:@"playUrl"];
                                        }
                                    }
                                }
                                if (strJoinerID != nil && strPlayUrl != nil) {
                                    [_listener onReceiveMemberJoinNotify: strJoinerID withPlayUrl:strPlayUrl];
                                }
                                break;
                            }
                        
                            case LINKMIC_CMD_MEMBER_EXIT_NOTIFY:
                            {
                                NSString * strExiterID = nil;
                                if (param) {
                                    NSDictionary* dictBody  = [TCUtil jsonData2Dictionary:param];
                                    if (dictBody && [[dictBody allKeys] containsObject:@"exiterID"]) {
                                        strExiterID = [dictBody objectForKey:@"exiterID"];
                                    }
                                }
                                if (strExiterID != nil) {
                                    [_listener onReceiveMemberExitNotify: strExiterID];
                                }
                                break;
                            }
                                
                            case LINKMIC_CMD_KICK_MEMBER:
                                if ([_listener respondsToSelector:@selector(onReceiveKickoutNotify)]) {
                                    [_listener onReceiveKickoutNotify];
                                }
                                break;
                                
                            default:
                                break;
                        }
                    });
                    return YES;
                }
                else {
                    return NO;
                }
            }
        }
    }
    return NO;
}

@end



// ----------------------------------------------------------------------------




#import <Foundation/Foundation.h>
#import "TCUtil.h"
#import "TCUserInfoModel.h"

#define MAX_SUB_VIDEO_STREAM        3




@interface TCStreamMergeMgr()
{
    NSString *              _mainStreamId;
    NSMutableArray *        _subStreamIds;
    
    int                     _mainStreamWidth;
    int                     _mainStreamHeight;
}
@end


@implementation TCStreamMergeMgr

-(instancetype) init
{
    if (self = [super init])
    {
        _subStreamIds = [NSMutableArray new];
        _mainStreamWidth = 540;
        _mainStreamHeight = 960;
    }
    return self;
}

+(instancetype) shareInstance
{
    static TCStreamMergeMgr * sharedInstance = NULL;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[TCStreamMergeMgr alloc] init];
    });
    return sharedInstance;
}

-(void) setMainVideoStream:(NSString*) streamUrl
{
    _mainStreamId = [TCUtil getStreamIDByStreamUrl:streamUrl];
    
    NSLog(@"MergeVideoStream: setMainVideoStream %@", _mainStreamId);
}

-(void) setMainVideoStreamResolution:(CGSize) size
{
    if (size.width > 0 && size.height > 0) {
        _mainStreamWidth  = size.width;
        _mainStreamHeight = size.height;
    }
}

-(void) addSubVideoStream:(NSString*) streamUrl
{
    if ([_subStreamIds count] >= MAX_SUB_VIDEO_STREAM) {
        return;
    }
    
    NSString * streamId = [TCUtil getStreamIDByStreamUrl:streamUrl];
    NSLog(@"MergeVideoStream: addSubVideoStream %@", streamId);
    
    for (NSString* item in _subStreamIds) {
        if ([item isEqualToString:streamId] == YES) {
            return;
        }
    }
    
    [_subStreamIds addObject:streamId];
    [self sendStreamMergeRequest: 5];
}

-(void) delSubVideoStream:(NSString*) streamUrl
{
    NSString * streamId = [TCUtil getStreamIDByStreamUrl:streamUrl];
    
    NSLog(@"MergeVideoStream: delSubVideoStream %@", streamId);
    
    BOOL bExist = NO;
    for (NSString* item in _subStreamIds) {
        if ([item isEqualToString:streamId] == YES) {
            bExist = YES;
            break;
        }
    }
    
    if (bExist == YES) {
        [_subStreamIds removeObject:streamId];
        [self sendStreamMergeRequest: 1];
    }
}

-(void) resetMergeState
{
    NSLog(@"MergeVideoStream: resetMergeState");
    
    [_subStreamIds removeAllObjects];
    
    if (_mainStreamId != nil && [_subStreamIds count] > 0) {
        [self sendStreamMergeRequest: 1];
    }
    
    _mainStreamId = nil;
    _mainStreamWidth = 540;
    _mainStreamHeight = 960;
}

-(void) sendStreamMergeRequest: (int) retryCount
{
    if (_mainStreamId == nil) {
        return;
    }
    
    NSDictionary * mergeDictParam = [self createRequestParam];
    if (mergeDictParam == nil) {
        return;
    }
    
    [self performSelectorInBackground: @selector(internalSendRequest:) withObject:@[[NSNumber numberWithInt:retryCount], mergeDictParam]];
}

-(void) internalSendRequest: (NSArray*)array
{
    if ([array count] < 2) {
        return;
    }
    
    NSNumber * numRetryIndex = [array objectAtIndex:0];
    NSDictionary* mergeParams = [array objectAtIndex:1];
    
    TCUserInfoData * profile = [[TCUserInfoModel sharedInstance] getUserProfile];
    NSDictionary* dictParam = @{@"Action": @"MergeVideoStream", @"userid": profile.identifier, @"mergeparams": mergeParams};
    
    NSString * streamsLog = [NSString stringWithFormat:@"mainStream: %@", _mainStreamId];
    int streamIndex = 1;
    for (NSString* item in _subStreamIds) {
        streamsLog = [NSString stringWithFormat:@"%@ subStream%d: %@", streamsLog, streamIndex++, item];
    }
    NSLog(@"MergeVideoStream: send request, %@ ,retryIndex: %d", streamsLog, [numRetryIndex intValue]);
    
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        NSString * strMessage = @"";
        if (resultDict != nil) {
            strMessage = resultDict[@"msg"];
        }
        
        NSLog(@"MergeVideoStream: recv response, message = %@", strMessage);
        
        BOOL bSuccess = NO;
        NSDictionary * dictMessage = [TCUtil jsonData2Dictionary:strMessage];
        if (dictMessage != nil) {
            int code = [dictMessage[@"code"] intValue];
            if (code == 0) {
                bSuccess = YES;
            }
        }
        
        if (bSuccess != YES) {
            int retryIndex = [numRetryIndex intValue];
            --retryIndex;
            if (retryIndex > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self performSelectorInBackground: @selector(internalSendRequest:) withObject:@[[NSNumber numberWithInt:retryIndex], mergeParams]];
                });
            }
        }
    }];
}

-(NSDictionary*) createRequestParam
{
    NSString * appid = kXiaoZhiBoAppId;
    
    NSMutableArray * inputStreamList = [NSMutableArray new];
    
    //大主播
    NSDictionary * mainStream = @{
                                  @"input_stream_id": _mainStreamId,
                                  @"layout_params": @{@"image_layer": [NSNumber numberWithInt:1]}
                                  };
    [inputStreamList addObject:mainStream];
    
    
    int subWidth  = 160;
    int subHeight = 240;
    int offsetHeight = 90;
    if (_mainStreamWidth < 540 || _mainStreamHeight < 960) {
        subWidth  = 120;
        subHeight = 180;
        offsetHeight = 60;
    }
    int subLocationX = _mainStreamWidth - subWidth;
    int subLocationY = _mainStreamHeight - subHeight - offsetHeight;
    
    //小主播
    int index = 0;
    for (NSString * item in _subStreamIds) {
        NSDictionary * subStream = @{
                                     @"input_stream_id": item,
                                     @"layout_params": @{
                                             @"image_layer": [NSNumber numberWithInt:(index + 2)],
                                             @"image_width": [NSNumber numberWithInt: subWidth],
                                             @"image_height": [NSNumber numberWithInt: subHeight],
                                             @"location_x": [NSNumber numberWithInt:subLocationX],
                                             @"location_y": [NSNumber numberWithInt:(subLocationY - index * subHeight)]
                                             }
                                     };
        ++index;
        [inputStreamList addObject:subStream];
    }
    
    //para
    NSDictionary * para = @{
                            @"app_id": [NSNumber numberWithInt:[appid intValue]] ,
                            @"interface": @"mix_streamv2.start_mix_stream_advanced",
                            @"mix_stream_session_id": _mainStreamId,
                            @"output_stream_id": _mainStreamId,
                            @"input_stream_list": inputStreamList
                            };
    
    //interface
    NSDictionary * interface = @{
                                 @"interfaceName":@"Mix_StreamV2",
                                 @"para":para
                                 };
    
    
    //mergeParams
    NSDictionary * mergeParams = @{
                                   @"timestamp": [NSNumber numberWithLong: (long)[[NSDate date] timeIntervalSince1970]],
                                   @"eventId": [NSNumber numberWithLong: (long)[[NSDate date] timeIntervalSince1970]],
                                   @"interface": interface
                                   };
    return mergeParams;
}

-(NSString*) dictionaryToString:(NSDictionary*)dict
{
    NSError *error;
    NSData *jsonData = [TCUtil dictionary2JsonData:dict];
    
    NSString *jsonString = @"";
    if (!jsonData)
    {
        NSLog(@"Got an error: %@", error);
    }
    else
    {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return jsonString;
}

@end


