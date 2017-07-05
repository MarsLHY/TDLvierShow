//
//  LiverListCell.h
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCLiveListModel.h"
@class TCLiveInfo;
/**
 *  直播/点播列表的Cell类，主要展示封面、标题、昵称、在线数、点赞数、定位位置
 */
@interface LiverListCell : UITableViewCell
{
//    TCLiveInfo *_model;
//    NSInteger  _type;
}

@property (nonatomic , retain) TCLiveInfo *model;
@property (nonatomic, assign) NSInteger type; // type为1表示UGC，其余为0

- (instancetype)initWithFrame:(CGRect)frame videoType:(VideoType)type;

@end
