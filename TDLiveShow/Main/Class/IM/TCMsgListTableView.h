//
//  TCMessageTableView.h
//  TCLVBIMDemo
//
//  Created by zhangxiang on 16/7/29.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCMsgModel.h"
#import "TCMsgListCell.h"

/**
 *  消息列表
 */
@interface TCMsgListTableView : UITableView<UITableViewDelegate,UITableViewDataSource>
/**
 *  给消息列表发一条消息展示
 *  @param msgModel 消息 model
 */
-(void)bulletNewMsg:(TCMsgModel *)msgModel;
@end


@protocol TCAudienceListDelegate <NSObject>

-(void)onFetchGroupMemberList:(int)errCode memberCount:(int)memberCount;

@end

/**
 *  观众列表
 */
@interface TCAudienceListTableView : UITableView<UITableViewDelegate, UITableViewDataSource>

@property(nonatomic,weak) id<TCAudienceListDelegate> audienceListDelegate;

-(instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style liveInfo:(TCLiveInfo *)liveInfo;

/**
 *  判断是否已经在头像列表中了，如果已经在列表中，则数量不必再加1
 *
 *  @param model 消息model
 *
 *  @return
 */
-(BOOL)isAlreadyInAudienceList:(TCMsgModel *)model;

/**
 *  通过TCMsgModel 判断哪位观众进入或则退出房间
 */
-(void)refreshAudienceList:(TCMsgModel *)model;
@end
