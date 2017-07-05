//
//  TCMsgHandler.h
//  TCLVBIMDemo
//
//  Created by dackli on 16/8/4.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImSDK/ImSDK.h"

typedef NS_ENUM(NSInteger, AVIMCommand) {
    AVIMCMD_None                 = 0, // 无事件
    
    AVIMCMD_Custom_Text          = 1, //文本消息
    AVIMCMD_Custom_EnterLive     = 2, //用户加入直播
    AVIMCMD_Custom_ExitLive      = 3, //用户推出直播
    AVIMCMD_Custom_Like          = 4, //点赞消息
    AVIMCMD_Custom_Danmaku       = 5, //弹幕消息
};



@interface IMUserAble : NSObject

@property (nonatomic, assign) NSInteger cmdType;

// 两个用户是否相同，可通过比较imUserId来判断
// 用户IMSDK的identigier
@property (nonatomic, copy) NSString *imUserId;

// 用户昵称
@property (nonatomic, copy) NSString *imUserName;

// 用户头像地址
@property (nonatomic, copy) NSString *imUserIconUrl;

@end



@protocol AVIMMsgListener <NSObject>

@required

-(void)onRecvGroupSender:(IMUserAble *)info textMsg:(NSString *)msgText;


@optional

- (void)onRecvGroupSystemMessage:(TIMGroupSystemElem *)msg;

@end



@interface AVIMMsgHandler : NSObject<TIMMessageListener>
{
@protected
    NSString                *_groupId;                // 房间信息
    TIMConversation         *_chatRoomConversation;   // 群会话上下文
}

@property (nonatomic, weak) id<AVIMMsgListener> roomIMListener;

//创建群组（直播聊天室）
- (void)createLiveRoom:(void (^)(int errCode, NSString* groupId))handler;

//删除群组（直播聊天室）
- (void)deleteLiveRoom:(NSString *)groupId handler:(void (^)(int errCode))handler;

//加入群组（直播聊天室）
- (void)joinLiveRoom:(NSString *)groupId handler:(void (^)(int errCode))handler;

//退出群组（直播聊天室）
- (void)quitLiveRoom:(NSString *)groupId handler:(void (^)(int errCode))handler;

// 释放相关的引用
- (void)releaseIMRef;

// 发送点赞消息
// 返回值，true: 成功， false：表示超过频率限制，点赞失败
- (BOOL)sendLikeMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic;

//发送文本消息
- (void)sendTextMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic msg:(NSString*)msg;

// 发送弹幕消息
- (void)sendDanmakuMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic msg:(NSString *)msg;

// 向群成员发送自己进群消息
- (void)sendEnterLiveRoomMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic;

// 向群成员发送自己退群消息
- (void)sendQuitLiveRoomMessage:(NSString *)userId nickName:(NSString *)nickName headPic:(NSString *)headPic;

@end
