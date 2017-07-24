//
//  TCConstants.h
//  TCLVBIMDemo
//
//  Created by realingzhou on 16/8/22.
//  Copyright © 2016年 tencent. All rights reserved.
//

#ifndef TCConstants_h
#define TCConstants_h


//小直播相关配置请参考:https://www.qcloud.com/document/product/454/7999
//************在腾讯云开通各项服务后，将您的配置替换到如下的几个定义中************
//腾讯云云通信服务AppId
#define kTCIMSDKAppId                        @"1400030881"
#define kTCIMSDKAccountType                  @"13374"

//腾讯云对象和存储服务(COS)AppId
#define kTCCOSAppId                          @""
//COS服务的bucket
#define kTCCOSBucket                         @""
//COS服务配置的机房区域，从COS的管理控制台https://console.qcloud.com/cos4/bucket进入Bucket列表后，选择您所创建的Bucket->基础配置->所属地区，查到所属地区后，根据如下
//对应关系填入，如是“华南”请填写"gz"，“华北”请填写"tj"，“华东”请填写"sh"
#define kTCCOSRegion                         @""

//云API服务密钥，在https://console.qcloud.com/capi查看，用于UGC短视频上传并落地到点播系统。已经废弃，不用填写。
#define kTCCloudAPISecretId                  @""
//Http配置
#define kHttpServerAddr                      @""

//bugly组件Appid，bugly为腾讯提供的用于App Crash收集和分析的组件
#define BUGLY_APP_ID                         @""

//录屏需要用到此配置,请改成您的工程配置文件中的app groups的配置
#define APP_GROUP                            @""

//直播分享页面的跳转地址，分享到微信、手Q后点击观看将会跳转到这个地址，请参考https://www.qcloud.com/document/product/454/8046 文档部署html5的代码后，替换成相应的页面地址
#define kLivePlayShareAddr                   @""
//设置第三方平台的appid和appsecrect，大部分平台进行分享操作需要在第三方平台创建应用并提交审核，通过后拿到appid和appsecrect并填入这里，具体申请方式请参考http://dev.umeng.com/social/android/operation
//有关友盟组件更多资料请参考这里：http://dev.umeng.com/social/ios/quick-integration
#define kWeiXin_Share_ID                     @""
#define kWeiXin_Share_Secrect                @""

#define kSina_WeiBo_Share_ID                 @""
#define kSina_WeiBo_Share_Secrect            @""

#define kQQZone_Share_ID                     @""
#define kQQZone_Share_Secrect                @""

//小直播appid
#define kXiaoZhiBoAppId                      @""

//**********************************************************************

#define kHttpTimeout                         30



//错误码
#define kError_InvalidParam                            -10001
#define kError_ConvertJsonFailed                       -10002
#define kError_HttpError                               -10003

//IMSDK群组相关错误码
#define kError_GroupNotExist                            10010  //该群已解散
#define kError_HasBeenGroupMember                       10013  //已经是群成员

//错误信息
#define  kErrorMsgNetDisconnected  @"网络异常，请检查网络"

//直播端错误信息
#define  kErrorMsgCreateGroupFailed  @"创建直播房间失败,Error:"
#define  kErrorMsgGetPushUrlFailed  @"拉取直播推流地址失败,Error:"
#define  kErrorMsgOpenCameraFailed  @"无法打开摄像头，需要摄像头权限"
#define  kErrorMsgOpenMicFailed  @"无法打开麦克风，需要麦克风权限"

//播放端错误信息
#define kErrorMsgGroupNotExit @"直播已结束，加入失败"
#define kErrorMsgJoinGroupFailed @"加入房间失败，Error:"
#define kErrorMsgLiveStopped @"直播已结束"
#define kErrorMsgRtmpPlayFailed @"视频流播放失败，Error:"

//提示语
#define  kTipsMsgStopPush  @"当前正在直播，是否退出直播？"

#ifndef POD_PITU
#define POD_PITU 0
#endif

#ifndef YOUTU_AUTH
#define YOUTU_AUTH 0
#endif


#endif /* TCConstants_h */
