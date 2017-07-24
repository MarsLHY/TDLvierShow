//
//  TDLiveListModel.h
//  TDLiveShow
//
//  Created by TD on 2017/7/19.
//  Copyright © 2017年 TD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDLiveListModel : NSObject

@end

@interface TDLiveUserInfo : NSObject

@property NSString *nickname;
@property NSString *headpic;
@property NSString *frontcover;
@property UIImage  *frontcoverImage;
@property NSString *location;

@end

@interface TDLiveInfo : NSObject

@property NSString *userid;
@property NSString *groupid;
@property int       type;
@property int       viewercount;         // 当前在线人数
@property int       likecount;           // 点赞数
@property NSString  *title;
@property NSString  *playurl;
@property NSString  *hls_play_url;
@property NSString  *fileid;
@property TDLiveUserInfo *userinfo;
@property int       timestamp;

@end
