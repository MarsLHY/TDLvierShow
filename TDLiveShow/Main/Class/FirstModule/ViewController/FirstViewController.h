//
//  FirstViewController.h
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "BaseViewController.h"
#import "TDPlayViewController.h"

@protocol TCLiveListViewControllerListener <NSObject>
-(void)onEnterPlayViewController;
@end

/**
 *  直播/点播列表的TableViewController，负责展示直播、点播列表，点击后跳转播放界面
 */

@interface FirstViewController : BaseViewController

@property(nonatomic,retain) TDPlayViewController *playVC;
@property(nonatomic, weak)  id<TCLiveListViewControllerListener> listener;
@end
