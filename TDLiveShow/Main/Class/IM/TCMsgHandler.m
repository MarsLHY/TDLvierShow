//
//  TCMsgHandler.m
//  TCLVBIMDemo
//
//  Created by dackli on 16/8/4.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "TCMsgHandler.h"
//#import "TCLinkMicModel.h"

@implementation AVIMMsgHandler


#pragma mark - AVIMMsgHandlerAble

- (instancetype)init {
    if (self = [super init]) {
        [[TIMManager sharedInstance] setMessageListener:self];
    }
    return self;
}

- (void)releaseIMRef {
    [[TIMManager sharedInstance] setMessageListener:nil];
}


- (void)sendTextMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic msg:(NSString *)msg
{
    [self sendMessage:AVIMCMD_Custom_Text userId:userId nickName:nickName headPic:headPic msg:msg];
}

- (void)sendEnterLiveRoomMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic
{
    [self sendMessage:AVIMCMD_Custom_EnterLive userId:userId nickName:nickName headPic:headPic msg:nil];
}

- (void)sendQuitLiveRoomMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic
{
    [self sendMessage:AVIMCMD_Custom_ExitLive userId:userId nickName:nickName headPic:headPic msg:nil];
}

- (BOOL)sendLikeMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic
{
    // 点赞消息做频率限制：1秒/2次
    static TCFrequeControl *freqControl = nil;
    if (freqControl == nil) {
        freqControl = [[TCFrequeControl alloc] initWithCounts:2 andSeconds:1];
    }
    
    if (![freqControl canTrigger]) {
        return NO;
    }
    
    [self sendMessage:AVIMCMD_Custom_Like userId:userId nickName:nickName headPic:headPic msg:nil];
    
    return YES;
}

- (void)sendDanmakuMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic msg:(NSString *)msg
{
    [self sendMessage:AVIMCMD_Custom_Danmaku userId:userId nickName:nickName headPic:headPic msg:msg];
}

- (void)sendMessage:(AVIMCommand)cmd userId:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic msg:(NSString *)msgContent
{
    if ((AVIMCMD_Custom_Text == cmd || AVIMCMD_Custom_Danmaku == cmd) && msgContent.length == 0)
    {
        DebugLog(@"sendMessage failed, msg length is 0");
        return;
    }
    
    NSDictionary* dict = @{@"userAction" : @(cmd), @"userId" : TC_PROTECT_STR(userId), @"nickName" : TC_PROTECT_STR(nickName), @"headPic" : TC_PROTECT_STR(headPic), @"msg" : TC_PROTECT_STR(msgContent)};
    
    NSData* data = [TCUtil dictionary2JsonData:dict];
    NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    TIMTextElem *textElem = [[TIMTextElem alloc] init];
    [textElem setText:content];

    TIMMessage *timMsg = [[TIMMessage alloc] init];
    [timMsg addElem:textElem];

    [_chatRoomConversation sendMessage:timMsg succ:^{
        DebugLog(@"sendMessage success, cmd:%d", cmd);
    } fail:^(int code, NSString *msg) {
        DebugLog(@"sendMessage failed, cmd:%d, code:%d, errmsg:%@", cmd, code, msg);
    }];
}


#pragma mark - TIMMessageListener
- (void)onNewMessage:(NSArray *)msgs {
    // TODO 可以将onThread改为另外的线程
    [self performSelector:@selector(onHandleNewMessage:) onThread:[NSThread currentThread] withObject:msgs waitUntilDone:NO];
}

- (void)onHandleNewMessage:(NSArray *)msgs {
    for(TIMMessage *msg in msgs) {
        TIMConversationType conType = msg.getConversation.getType;
        
        switch (conType) {
            case TIM_C2C: {
#warning TDLinkMic 暂时屏蔽连麦功能
                //目前只有连麦模块使用了C2C消息
//                if (NO == [[TCLinkMicModel sharedInstance] handleC2CMessageReceived:msg]) {
//                    //返回YES表示C2C消息已经被处理，否则可以继续给其它模块处理
//                }
                break;
            }
            case TIM_GROUP: {
                if([[msg.getConversation getReceiver] isEqualToString:_groupId]) {
                    // 处理群聊天消息
                    // 只接受来自该聊天室的消息
                    [self onRecvGroup:msg];
                }
                break;
            }
            case TIM_SYSTEM: {
                // 这里获取的groupid为空，IMSDK的问题
                // 所以在onRecvGroupSystemMessage里面通过sysElem.group来判断
//                if ([[msg.getConversation getReceiver] isEqualToString:_groupId]) {
                    [self onRecvGroupSystemMessage:msg];
//                }
                break;
            }
            default:
                break;
        }
    }
}

- (void)onRecvGroupSystemMessage:(TIMMessage *)msg {
    for (int index = 0; index < [msg elemCount]; index++) {
        TIMElem *elem = [msg getElem:index];
        if ([elem isKindOfClass:[TIMGroupSystemElem class]]) {
            TIMGroupSystemElem *sysElem = (TIMGroupSystemElem *)elem;
            if ([sysElem.group isEqualToString:_groupId]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_roomIMListener && [_roomIMListener respondsToSelector:@selector(onRecvGroupSystemMessage:)]) {
                        [_roomIMListener onRecvGroupSystemMessage:sysElem];
                    }
                });

            }
        }
    }
}

- (void)onRecvGroup:(TIMMessage *)msg {
    IMUserAble *userAble = [[IMUserAble alloc] init];
    
    for(int index = 0; index < [msg elemCount]; index++) {
        TIMElem *elem = [msg getElem:index];
        if([elem isKindOfClass:[TIMTextElem class]]) {
            // 消息总入口频率限制
            static TCFrequeControl *freqControl = nil;
            if (freqControl == nil) {
                freqControl = [[TCFrequeControl alloc] initWithCounts:20 andSeconds:1];
            }
            
            if (![freqControl canTrigger]) {
                return;
            }
            
            // 文本消息
            TIMTextElem *textElem = (TIMTextElem *)elem;
            NSString *msgText = textElem.text;
            NSDictionary* dict = [TCUtil jsonData2Dictionary:msgText];
            if (dict)
            {
                if (dict[@"userAction"])
                    userAble.cmdType = [dict[@"userAction"] intValue];

                userAble.imUserId = dict[@"userId"];
                userAble.imUserName = dict[@"nickName"];
                userAble.imUserIconUrl = dict[@"headPic"];
                msgText = dict[@"msg"];
            }
            else
            {
                TIMUserProfile *userProfile = [msg GetSenderProfile];
                if (userProfile) {
                    userAble.imUserId = userProfile.identifier;
                    userAble.imUserName = userProfile.nickname.length > 0 ? userProfile.nickname : userProfile.identifier;
                    userAble.imUserIconUrl = userProfile.faceURL;
                }
                userAble.cmdType = AVIMCMD_Custom_Text;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_roomIMListener) {
                    [_roomIMListener onRecvGroupSender:userAble textMsg:msgText];
                }
            });
        }
        else if([elem isKindOfClass:[TIMCustomElem class]]) {
            // 自定义消息
            TIMCustomElem* cele = (TIMCustomElem*)elem;
            NSString *dataStr = [[NSString alloc] initWithData:cele.data encoding:NSUTF8StringEncoding];
            DebugLog(@"datastr is:%@", dataStr);
        }
    }
}

- (void)switchToLiveRoom:(NSString *)groupId
{
    _groupId = groupId;
    _chatRoomConversation = [[TIMManager sharedInstance] getConversation:TIM_GROUP receiver:groupId];
}

- (void)createLiveRoom:(void (^)(int, NSString *))handler
{
    __weak typeof(self) weakSelf = self;
    [[TIMGroupManager sharedInstance] CreateAVChatRoomGroup:@"live" succ:^(NSString *groupId) {
        DebugLog(@"createLiveRoom succ, groupId:%@", groupId);
        //切换群会话的上下文环境
        [weakSelf switchToLiveRoom:groupId];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(0, groupId);
        });
        
    } fail:^(int code, NSString *msg) {
        DebugLog(@"createLiveRoom failed, error:%d, msg:%@", code, msg);
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(code, nil);
        });
    }];
}

- (void)deleteLiveRoom:(NSString *)groupId handler:(void (^)(int))handler
{
    [[TIMGroupManager sharedInstance] DeleteGroup:TC_PROTECT_STR(groupId) succ:^{
        DebugLog(@"deleteLiveRoom succ, groupId:%@", groupId);
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(0);
        });
        
    } fail:^(int code, NSString *msg) {
        DebugLog(@"deleteLiveRoom failed, error:%d, msg:%@", code, msg);
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(code);
        });
    }];
}

- (void)joinLiveRoom:(NSString *)groupId handler:(void (^)(int))handler
{
    __weak typeof(self) weakSelf = self;
    [[TIMGroupManager sharedInstance] JoinGroup:groupId msg:nil succ:^{
        DebugLog(@"joinGroup success,group id:%@", groupId);
        //切换群会话的上下文环境
        [weakSelf switchToLiveRoom:groupId];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(0);
        });
        
    } fail:^(int code, NSString *msg) {
        if (kError_HasBeenGroupMember == code)  //10013表示已经是群成员
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(0);
            });
        }
        else
        {
            DebugLog(@"joinGroup failed,group id:%@, code:%d, msg:%@", groupId, code, msg);
            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(code);
                });
            });
        }
    }];
}

- (void)quitLiveRoom:(NSString *)groupId handler:(void (^)(int))handler
{
    [[TIMGroupManager sharedInstance] QuitGroup:groupId succ:^{
        DebugLog(@"quitGroup success,group id:%@", groupId);
    } fail:^(int code, NSString *msg) {
        DebugLog(@"quitGroup failed,group id:%@", groupId);
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(code);
        });
        
    }];
}


@end



@implementation IMUserAble

@end

