//
//  TDPlayDecorateView.h
//  TDLiveShow
//
//  Created by TD on 2017/7/5.
//  Copyright © 2017年 TD. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCMsgModel.h"
#import "TCMsgHandler.h"
#import "TCMsgListTableView.h"

@protocol TDPlayDecorateDelegate <NSObject>
-(void)closeVC:(BOOL)popViewController;
-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer;
-(void)clickPlayVod;
-(void)onSeek:(UISlider *)slider;
-(void)onSeekBegin:(UISlider *)slider;
-(void)onDrag:(UISlider *)slider;
-(void)clickLog:(UIButton *)button;
-(void)clickShare:(UIButton *)button;
-(void)clickRecord:(UIButton *)button;
-(void)onRecvGroupDeleteMsg;
@end

/**
 *  播放模块逻辑view，里面展示了消息列表，弹幕动画，观众列表等UI，其中与SDK的逻辑交互需要交给主控制器处理
 */
@interface TDPlayDecorateView : UIView<UITextFieldDelegate, UIAlertViewDelegate, AVIMMsgListener, TIMGroupAssistantListener, TCAudienceListDelegate>

@property(nonatomic,weak) id<TDPlayDecorateDelegate>delegate;
@property(nonatomic,retain)  UILabel            *playDuration;
@property(nonatomic,retain)  UISlider           *playProgress;
@property(nonatomic,retain)  UILabel            *playLabel;
@property(nonatomic,retain)  UIButton           *playBtn;
@property(nonatomic,retain)  UIButton           *btnChat;
@property(nonatomic,retain)  UIButton           *btnLog;
@property(nonatomic,retain)  UIButton           *btnShare;
@property(nonatomic,retain)  UIButton           *btnRecord;
@property(nonatomic,retain)  UIView             *cover;
@property(nonatomic,retain)  UITextView         *statusView;
@property(nonatomic,retain)  UITextView         *logViewEvt;

@property(nonatomic,retain)   AVIMMsgHandler    *msgHandler;

-(instancetype)initWithFrame:(CGRect)frame liveInfo:(TCLiveInfo *)liveInfo withLinkMic:(BOOL)linkmic;

-(void)setViewerCount:(int)viewerCount likeCount:(int)likeCount;

-(BOOL)isAlreadyInAudienceList:(TCMsgModel *)model;

-(void)initAudienceList;

-(void)keyboardFrameDidChange:(NSNotification*)notice;


@end
