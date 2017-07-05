#import <Foundation/NSObject.h>
#import "ImSDK/ImSDK.h"

//连麦消息类型
typedef NS_ENUM(NSInteger, TXLinkMicCmd) {
    LINKMIC_CMD_REQUEST                                 = 10001,
    LINKMIC_CMD_ACCEPT                                  = 10002,
    LINKMIC_CMD_REJECT                                  = 10003,
    LINKMIC_CMD_MEMBER_JOIN_NOTIFY                      = 10004,
    LINKMIC_CMD_MEMBER_EXIT_NOTIFY                      = 10005,
    LINKMIC_CMD_KICK_MEMBER                             = 10006,
};


//连麦响应类型
typedef NS_ENUM(NSInteger, TCLinkMicResponseType) {
    LINKMIC_RESPONSE_TYPE_ACCEPT                        = 1,    //主播接受连麦
    LINKMIC_RESPONSE_TYPE_REJECT                        = 2,    //主播拒绝连麦
};


@protocol TCLinkMicListener <NSObject>
/**
 * 收到连麦请求
 */
@optional
-(void) onReceiveLinkMicRequest:(NSString*)fromUserID withNickName:(NSString*)nickName;

/**
 * 收到连麦响应
 */
@optional
-(void) onReceiveLinkMicResponse:(NSString*)fromUserID withType:(TCLinkMicResponseType)rspType andParam:(NSDictionary*)param;

/**
 * 收到新成员加入连麦的通知
 */
@optional
-(void) onReceiveMemberJoinNotify:(NSString*)joinerID withPlayUrl:(NSString*)playUrl;

/**
 * 收到成员退出连麦的通知
 */
@optional
-(void) onReceiveMemberExitNotify:(NSString*)exiterID;

/**
 * 被主播踢出连麦
 */
@optional
-(void) onReceiveKickoutNotify;
@end



@interface TCLinkMicModel: NSObject

+ (instancetype)sharedInstance;

/**
 * 发送连麦请求
 */
-(void) sendLinkMicRequest:(NSString*)toUserID;

/**
 * 发送连麦响应
 */
-(void) sendLinkMicResponse:(NSString*)toUserID withType:(TCLinkMicResponseType)rspType andParams:(NSDictionary*)param;

/**
 * 发送加入连麦通知
 */
-(void) sendMemberJoinNotify:(NSString*)toUserID withJoinerID:(NSString*)joinerID andJoinerPlayUrl:(NSString*)playUrl;

/**
 * 发送退出连麦通知
 */
-(void) sendMemberExitNotify:(NSString*)toUserID withExiterID:(NSString*)exiterID;

/**
 * 踢出连麦者
 */
-(void) kickoutLinkMicMember:(NSString*)toUserID;

/**
 * 解析IM C2C消息，处理连麦消息
 */
-(BOOL) handleC2CMessageReceived:(TIMMessage *)msg;

@property (nonatomic, weak)     id<TCLinkMicListener>   listener;

@end


// ----------------------------------------------------------------------------

@interface TCStreamMergeMgr : NSObject

+(instancetype) shareInstance;

-(void) setMainVideoStream:(NSString*) streamUrl;

-(void) setMainVideoStreamResolution:(CGSize) size;

-(void) addSubVideoStream:(NSString*) streamUrl;

-(void) delSubVideoStream:(NSString*) streamUrl;

-(void) resetMergeState;


@end
