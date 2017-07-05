//
//  TCMessageModel.h
//  TCLVBIMDemo
//
//  Created by zhangxiang on 16/7/29.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCLiveListModel.h"
#import "TCMsgHandler.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define MSG_TABLEVIEW_WIDTH        200
#define MSG_TABLEVIEW_HEIGHT       150
#define MSG_TABLEVIEW_BOTTOM_SPACE 10
#define MSG_TABLEVIEW_LABEL_FONT   14
#define MSG_BULLETVIEW_HEIGHT      34
#define MSG_UI_SPACE               10

//发送框
#define MSG_TEXT_SEND_VIEW_HEIGHT          45
#define MSG_TEXT_SEND_FEILD_HEIGHT         25
#define MSG_TEXT_SEND_BTN_WIDTH            35
#define MSG_TEXT_SEND_BULLET_BTN_WIDTH     55

//小图标
#define BOTTOM_BTN_ICON_WIDTH  35


typedef NS_ENUM(NSInteger, TCMsgModelType)
{
    TCMsgModelType_NormalMsg           = 0,   //普通消息
    TCMsgModelType_MemberEnterRoom     = 1,   //进入房间消息
    TCMsgModelType_MemberQuitRoom      = 2,   //退出房间消息
    TCMsgModelType_DanmaMsg            = 3,   //弹幕消息
    TCMsgModelType_Praise              = 4,   //点赞消息
};

/**
 *  消息model，这个model会在弹幕，消息列表，观众列表用到
 */
@interface TCMsgModel : NSObject
@property(nonatomic,assign)TCMsgModelType msgType;      //消息类型
@property(nonatomic,retain)NSString *userId;            //用户Id
@property(nonatomic,retain)NSString *userName;          //用户名字
@property(nonatomic,retain)NSString *userMsg;           //用户发的消息
@property(nonatomic,retain)NSString *userHeadImageUrl;  //用户头像url
@property(nonatomic,assign)NSInteger msgHeight; //消息高度
@property(nonatomic, retain)NSAttributedString* msgAttribText;
@end


/**
 *  推流model，这个model会在推流 TCPushDecorateView用到
 */
@interface TCPublishInfo : NSObject
@property(nonatomic,retain) TCLiveInfo *liveInfo;
@property(nonatomic,retain) AVIMMsgHandler   *msgHandler;
@end

