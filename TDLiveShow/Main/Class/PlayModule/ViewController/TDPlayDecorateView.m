//
//  TDPlayDecorateView.m
//  TDLiveShow
//
//  Created by TD on 2017/7/5.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "TDPlayDecorateView.h"
#import "TCMsgBulletView.h"
#import <UIImageView+WebCache.h>
#import "TCPlayerModel.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"
#import "TCUserInfoModel.h"
#import "TCLoginModel.h"
#import "TCConstants.h"
#import "TCLiveListModel.h"
//#import "HUDHelper.h"
//#import "UMSocialUIManager.h"
//#import <UMSocialCore/UMSocialCore.h>

@implementation TDPlayDecorateView
{
    TCShowLiveTopView  *_topView;
    TCAudienceListTableView *_audienceTableView;
    TCMsgListTableView *_msgTableView;
    TCMsgBulletView *_bulletViewOne;
    TCMsgBulletView *_bulletViewTwo;
    TCLiveInfo         *_liveInfo;
    UIButton           *_praiseBtn;
    UIButton           *_closeBtn;
    UIView             *_msgInputView;
    UITextField        *_msgInputFeild;
    CGPoint            _touchBeginLocation;
    BOOL               _bulletBtnIsOn;
    BOOL               _viewsHidden;
    NSMutableArray     *_heartAnimationPoints;
}

-(instancetype)initWithFrame:(CGRect)frame liveInfo:(TCLiveInfo *)liveInfo withLinkMic:(BOOL)linkmic{
    self = [super initWithFrame:frame];
    if (self) {
        _liveInfo      = liveInfo;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameDidChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLogout:) name:logoutNotification object:nil];
        UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickScreen:)];
        [self addGestureRecognizer:tap];
        [self initUI: linkmic];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setViewerCount:(int)viewerCount likeCount:(int)likeCount
{
    _liveInfo.viewercount = viewerCount;
    _liveInfo.likecount = likeCount;
    [_topView setViewerCount:viewerCount likeCount:likeCount];
}

-(BOOL)isAlreadyInAudienceList:(TCMsgModel *)model
{
    return [_audienceTableView isAlreadyInAudienceList:model];
}

- (void)setMsgHandler:(AVIMMsgHandler *)msgHandler {
    _msgHandler = msgHandler;
    _msgHandler.roomIMListener = self;
    //    [[TCLoginModel sharedInstance] setGroupAssistantListener:self];
}

- (void)initAudienceList {
    CGFloat audience_width = self.width - 25 - _topView.right;
    _audienceTableView = [[TCAudienceListTableView alloc] initWithFrame:CGRectMake(_topView.right + 10 +audience_width / 2 - IMAGE_SIZE / 2 ,_topView.center.y -  audience_width / 2, _topView.height, audience_width) style:UITableViewStyleGrouped liveInfo:_liveInfo];
    _audienceTableView.transform = CGAffineTransformMakeRotation(- M_PI/2);
    _audienceTableView.audienceListDelegate = self;
    
    [self addSubview:_audienceTableView];
}

- (void)initUI:(BOOL)linkmic {
    //close VC
    _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeBtn setFrame:CGRectMake(self.width - 15 - BOTTOM_BTN_ICON_WIDTH, self.height - 50, BOTTOM_BTN_ICON_WIDTH, BOTTOM_BTN_ICON_WIDTH)];
    [_closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(closeVC) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_closeBtn];
    
    //topview,展示主播头像，在线人数及点赞
    int statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    _topView = [[TCShowLiveTopView alloc] initWithFrame:CGRectMake(5, statusBarHeight + 5, 110, 35) isHost:NO hostNickName:_liveInfo.userinfo.nickname
                                          audienceCount:_liveInfo.viewercount likeCount:_liveInfo.likecount hostFaceUrl:_liveInfo.userinfo.headpic];
    
    [self addSubview:_topView];
    
    //举报
    UIButton *reportBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [reportBtn setFrame:CGRectMake(_topView.left, _topView.bottom + 10, 50, 20)];
    [reportBtn setImage:[UIImage imageNamed:@"user_report"] forState:UIControlStateNormal];
    [reportBtn addTarget:self action:@selector(userReport) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:reportBtn];
    
    int   icon_size = BOTTOM_BTN_ICON_WIDTH;
    float startSpace = 15;
    float icon_center_y = self.height - icon_size/2 - startSpace;
    
    if (_liveInfo.type == TCLiveListItemType_Record || _liveInfo.type == TCLiveListItemType_UGC) {  //点播
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [_playBtn setFrame:CGRectMake(15, _closeBtn.y, BOTTOM_BTN_ICON_WIDTH, BOTTOM_BTN_ICON_WIDTH)];
        [_playBtn addTarget:self action:@selector(clickPlayVod) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playBtn];
        
        _playLabel = [[UILabel alloc]init];
        _playLabel.frame = CGRectMake(_playBtn.right + 10, _playBtn.center.y - 5, 53, 10);
        [_playLabel setText:@"00:00:00"];
        [_playLabel setTextAlignment:NSTextAlignmentRight];
        [_playLabel setFont:[UIFont systemFontOfSize:12]];
        [_playLabel setTextColor:[UIColor whiteColor]];
        [self addSubview:_playLabel];
        
        UILabel *centerLabel =[[UILabel alloc]init];
        centerLabel.frame = CGRectMake(_playLabel.right, _playLabel.y, 4, 10);
        centerLabel.text = @"/";
        centerLabel.font = [UIFont systemFontOfSize:12];
        centerLabel.textColor = [UIColor whiteColor];
        centerLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:centerLabel];
        
        _playDuration = [[UILabel alloc]init];
        _playDuration.frame = CGRectMake(centerLabel.right, centerLabel.y, 53, 10);
        [_playDuration setText:@"--:--:--"];
        [_playDuration setFont:[UIFont systemFontOfSize:12]];
        [_playDuration setTextColor:[UIColor whiteColor]];
        [self addSubview:_playDuration];
        
        //log显示或隐藏
        _btnLog = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnLog.center = CGPointMake(_closeBtn.center.x - icon_size - 15, icon_center_y);
        _btnLog.bounds = CGRectMake(0, 0, icon_size, icon_size);
        [_btnLog setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
        [_btnLog addTarget:self action:@selector(clickLog:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnLog];
        
        _btnShare = ({
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [self addSubview:btn];
            btn.center = CGPointMake(_closeBtn.center.x - (icon_size + 15) * 2, icon_center_y);
            btn.bounds = CGRectMake(0, 0, icon_size, icon_size);
            [btn setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"share_pressed"] forState:UIControlStateHighlighted];
            [btn addTarget:self action:@selector(clickShare:) forControlEvents:UIControlEventTouchUpInside];
            btn;
        });
        
        _playProgress=[[UISlider alloc]initWithFrame:CGRectMake(15, _playBtn.top - 35, self.width - 30, 20)];
        [_playProgress setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
        [_playProgress setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
        [_playProgress setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
        _playProgress.maximumValue = 0;
        _playProgress.minimumValue = 0;
        _playProgress.value = 0;
        _playProgress.continuous = NO;
        [_playProgress addTarget:self action:@selector(onSeek:) forControlEvents:(UIControlEventValueChanged)];
        [_playProgress addTarget:self action:@selector(onSeekBegin:) forControlEvents:(UIControlEventTouchDown)];
        [_playProgress addTarget:self action:@selector(onDrag:) forControlEvents:UIControlEventTouchDragInside];
        [self addSubview:_playProgress];
    }else{    //直播
        //聊天
        float icon_count = (linkmic == YES ? 8 : 6);
        float icon_center_interval = (self.width - 2*startSpace - icon_size)/(icon_count - 1);
        float first_icon_center_x = startSpace + icon_size/2;
        
        _btnChat = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnChat.center = CGPointMake(first_icon_center_x, icon_center_y);
        _btnChat.bounds = CGRectMake(0, 0, icon_size, icon_size);
        [_btnChat setImage:[UIImage imageNamed:@"comment"] forState:UIControlStateNormal];
        [_btnChat addTarget:self action:@selector(clickChat:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnChat];
        
        //点赞
        _praiseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        //_praiseBtn.center = CGPointMake(_closeBtn.center.x - icon_size - 15, icon_center_y);
        _praiseBtn.center = CGPointMake(_closeBtn.center.x - icon_center_interval, icon_center_y);
        _praiseBtn.bounds = CGRectMake(0, 0, icon_size, icon_size);
        [_praiseBtn setImage:[UIImage imageNamed:@"like_hover"] forState:UIControlStateNormal];
        [_praiseBtn addTarget:self action:@selector(clickPraise:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_praiseBtn];
        
        //log显示或隐藏
        _btnLog = [UIButton buttonWithType:UIButtonTypeCustom];
        //_btnLog.center = CGPointMake(_closeBtn.center.x - icon_size * 2 - 15 * 2, icon_center_y);
        _btnLog.center = CGPointMake(_closeBtn.center.x - icon_center_interval * 2, icon_center_y);
        _btnLog.bounds = CGRectMake(0, 0, icon_size, icon_size);
        [_btnLog setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
        [_btnLog addTarget:self action:@selector(clickLog:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnLog];
        
        _btnShare = ({
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [self addSubview:btn];
            //btn.center = CGPointMake(_closeBtn.center.x - (icon_size + 15) * 3, icon_center_y);
            btn.center = CGPointMake(_closeBtn.center.x - icon_center_interval * 3, icon_center_y);
            btn.bounds = CGRectMake(0, 0, icon_size, icon_size);
            [btn setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"share_pressed"] forState:UIControlStateHighlighted];
            [btn addTarget:self action:@selector(clickShare:) forControlEvents:UIControlEventTouchUpInside];
            btn;
        });
        
        //UGC
        _btnRecord = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnRecord.center = CGPointMake(_closeBtn.center.x - icon_center_interval * 4, icon_center_y);
        _btnRecord.bounds = CGRectMake(0, 0, icon_size, icon_size);
        [_btnRecord setImage:[UIImage imageNamed:@"video_record"] forState:UIControlStateNormal];
        [_btnRecord setImage:[UIImage imageNamed:@"video_record_press"] forState:UIControlStateHighlighted];
        [_btnRecord addTarget:self action:@selector(clickRecord:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnRecord];
        
        //弹幕
        _msgTableView = [[TCMsgListTableView alloc] initWithFrame:CGRectMake(15, _btnChat.top - MSG_TABLEVIEW_HEIGHT - MSG_TABLEVIEW_BOTTOM_SPACE, MSG_TABLEVIEW_WIDTH, MSG_TABLEVIEW_HEIGHT) style:UITableViewStyleGrouped];
        [self addSubview:_msgTableView];
        
        _bulletViewOne = [[TCMsgBulletView alloc]initWithFrame:CGRectMake(0,_msgTableView.top - MSG_UI_SPACE - MSG_BULLETVIEW_HEIGHT, SCREEN_WIDTH, MSG_BULLETVIEW_HEIGHT)];
        [self addSubview:_bulletViewOne];
        
        _bulletViewTwo = [[TCMsgBulletView alloc]initWithFrame:CGRectMake(0, _bulletViewOne.top - MSG_BULLETVIEW_HEIGHT, SCREEN_WIDTH, MSG_BULLETVIEW_HEIGHT)];
        [self addSubview:_bulletViewTwo];
        
        
        //输入框
        _msgInputView = [[UIView alloc] initWithFrame:CGRectMake(0, self.height, self.width, MSG_TEXT_SEND_VIEW_HEIGHT )];
        _msgInputView.backgroundColor = [UIColor clearColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _msgInputView.width, _msgInputView.height)];
        imageView.image = [UIImage imageNamed:@"input_comment"];
        
        UIButton *bulletBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        bulletBtn.frame = CGRectMake(10, (_msgInputView.height - MSG_TEXT_SEND_FEILD_HEIGHT)/2, MSG_TEXT_SEND_BULLET_BTN_WIDTH, MSG_TEXT_SEND_FEILD_HEIGHT);
        [bulletBtn setImage:[UIImage imageNamed:@"Switch_OFF"] forState:UIControlStateNormal];
        [bulletBtn setImage:[UIImage imageNamed:@"Switch_ON"] forState:UIControlStateSelected];
        [bulletBtn addTarget:self action:@selector(clickBullet:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        sendBtn.frame = CGRectMake(self.width - 15 - MSG_TEXT_SEND_BTN_WIDTH, (_msgInputView.height - MSG_TEXT_SEND_FEILD_HEIGHT)/2, MSG_TEXT_SEND_BTN_WIDTH, MSG_TEXT_SEND_FEILD_HEIGHT);
        [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
        [sendBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [sendBtn setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateNormal];
        [sendBtn setBackgroundColor:[UIColor clearColor]];
        [sendBtn addTarget:self action:@selector(clickSend) forControlEvents:UIControlEventTouchUpInside];
        
        UIImageView *msgInputFeildLine1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vertical_line"]];
        msgInputFeildLine1.frame = CGRectMake(bulletBtn.right + 10, sendBtn.y, 1, MSG_TEXT_SEND_FEILD_HEIGHT);
        
        UIImageView *msgInputFeildLine2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vertical_line"]];
        msgInputFeildLine2.frame = CGRectMake(sendBtn.left - 10, sendBtn.y, 1, MSG_TEXT_SEND_FEILD_HEIGHT);
        
        _msgInputFeild = [[UITextField alloc] initWithFrame:CGRectMake(msgInputFeildLine1.right + 10,sendBtn.y,msgInputFeildLine2.left - msgInputFeildLine1.right - 20,MSG_TEXT_SEND_FEILD_HEIGHT)];
        _msgInputFeild.backgroundColor = [UIColor clearColor];
        _msgInputFeild.returnKeyType = UIReturnKeySend;
        _msgInputFeild.placeholder = @"和大家说点什么吧";
        _msgInputFeild.delegate = self;
        _msgInputFeild.textColor = [UIColor blackColor];
        _msgInputFeild.font = [UIFont systemFontOfSize:14];
        
        
        [_msgInputView addSubview:imageView];
        [_msgInputView addSubview:_msgInputFeild];
        [_msgInputView addSubview:bulletBtn];
        [_msgInputView addSubview:sendBtn];
        [_msgInputView addSubview:msgInputFeildLine1];
        [_msgInputView addSubview:msgInputFeildLine2];
        [self addSubview:_msgInputView];
    }
    
    //LOG UI
    _cover = [[UIView alloc]init];
    _cover.frame  = CGRectMake(10.0f, 55 + 2*icon_size, self.width - 20, self.height - 110 - 3 * icon_size);
    _cover.backgroundColor = [UIColor whiteColor];
    _cover.alpha  = 0.5;
    _cover.hidden = YES;
    [self addSubview:_cover];
    
    int logheadH = 65;
    _statusView = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2*icon_size, self.width - 20,  logheadH)];
    _statusView.backgroundColor = [UIColor clearColor];
    _statusView.alpha = 1;
    _statusView.textColor = [UIColor blackColor];
    _statusView.editable = NO;
    _statusView.hidden = YES;
    [self addSubview:_statusView];
    
    
    _logViewEvt = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2*icon_size + logheadH, self.width - 20, self.height - 110 - 3 * icon_size - logheadH)];
    _logViewEvt.backgroundColor = [UIColor clearColor];
    _logViewEvt.alpha = 1;
    _logViewEvt.textColor = [UIColor blackColor];
    _logViewEvt.editable = NO;
    _logViewEvt.hidden = YES;
    [self addSubview:_logViewEvt];
}

-(void)userReport{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"确定举报？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alertView show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        TCUserInfoData  *userInfoData = [[TCUserInfoModel sharedInstance] getUserProfile ];
        [[TCPlayerModel sharedInstance] reportUser:_liveInfo.userid hostUserId:userInfoData.identifier handler:^(int errCode) {
            //todo
        }];
        [[HUDHelper sharedInstance] tipMessage:@"感谢你的举报，我们会尽快处理"];
    }
}

-(void)bulletMsg:(TCMsgModel *)msgModel{
    [_msgTableView bulletNewMsg:msgModel];
    if (msgModel.msgType == TCMsgModelType_DanmaMsg) {
        if ([self getLocation:_bulletViewOne] >= [self getLocation:_bulletViewTwo]) {
            [_bulletViewTwo bulletNewMsg:msgModel];
        }else{
            [_bulletViewOne bulletNewMsg:msgModel];
        }
    }
    
    if (msgModel.msgType == TCMsgModelType_MemberEnterRoom || msgModel.msgType == TCMsgModelType_MemberQuitRoom) {
        [_audienceTableView refreshAudienceList:msgModel];
    }
}

-(CGFloat)getLocation:(TCMsgBulletView *)bulletView{
    UIView *view = bulletView.lastAnimateView;
    CGRect rect = [view.layer.presentationLayer frame];
    return rect.origin.x + rect.size.width;
}


-(void)clickBullet:(UIButton *)btn{
    _bulletBtnIsOn = !_bulletBtnIsOn;
    btn.selected = _bulletBtnIsOn;
}

-(void)clickChat:(UIButton *)button{
    [_msgInputFeild becomeFirstResponder];
}

-(void)clickSend{
    [self textFieldShouldReturn:_msgInputFeild];
}

-(void)clickPraise:(UIButton *)button{
    TCUserInfoData  *profile = [[TCUserInfoModel sharedInstance] getUserProfile];
    if ([_msgHandler sendLikeMessage:profile.identifier nickName:profile.nickName headPic:profile.faceURL]) {
        [[TCPlayerModel sharedInstance] giveLike:_liveInfo.userid handler:^(int errCode) {
        }];
        [_topView onUserSendLikeMessage];
    }
    [self showLikeHeartStartRect:button.frame];
}

-(void)clickLog:(UIButton *)button{
    if (self.delegate) [self.delegate clickLog:button];
}

-(void)clickShare:(UIButton *)button{
    if (self.delegate) [self.delegate clickShare:button];
}

-(void)clickRecord:(UIButton *)button{
    if (self.delegate) {
        [self.delegate clickRecord:button];
    }
}

-(void)showLikeHeart{
    [self showLikeHeartStartRect:_praiseBtn.frame];
}

- (void)showLikeHeartStartRect:(CGRect)frame
{
    {
        // 星星动画频率限制
        static TCFrequeControl *freqControl = nil;
        if (freqControl == nil) {
            freqControl = [[TCFrequeControl alloc] initWithCounts:10 andSeconds:1];
        }
        
        if (![freqControl canTrigger]) {
            return;
        }
    }
    
    if (_viewsHidden) {
        return;
    }
    UIImageView *imageView = [[UIImageView alloc ] initWithFrame:frame];
    imageView.image = [[UIImage imageNamed:@"img_like"] imageWithTintColor:[UIColor randomFlatDarkColor]];
    [self addSubview:imageView];
    imageView.alpha = 0;
    
    
    [imageView.layer addAnimation:[self hearAnimationFrom:frame] forKey:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [imageView removeFromSuperview];
    });
}

- (CAAnimation *)hearAnimationFrom:(CGRect)frame
{
    //位置
    CAKeyframeAnimation *animation=[CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.beginTime = 0.5;
    animation.duration = 2.5;
    animation.removedOnCompletion = YES;
    animation.fillMode = kCAFillModeForwards;
    animation.repeatCount= 0;
    animation.calculationMode = kCAAnimationCubicPaced;
    
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    CGPoint point0 = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2);
    
    CGPathMoveToPoint(curvedPath, NULL, point0.x, point0.y);
    
    if (!_heartAnimationPoints) {
        _heartAnimationPoints = [[NSMutableArray alloc] init];
    }
    if ([_heartAnimationPoints count] < 40) {
        float x11 = point0.x - arc4random() % 30 + 30;
        float y11 = frame.origin.y - arc4random() % 60 ;
        float x1 = point0.x - arc4random() % 15 + 15;
        float y1 = frame.origin.y - arc4random() % 60 - 30;
        CGPoint point1 = CGPointMake(x11, y11);
        CGPoint point2 = CGPointMake(x1, y1);
        
        int conffset2 = self.superview.bounds.size.width * 0.2;
        int conffset21 = self.superview.bounds.size.width * 0.1;
        float x2 = point0.x - arc4random() % conffset2 + conffset2;
        float y2 = arc4random() % 30 + 240;
        float x21 = point0.x - arc4random() % conffset21  + conffset21;
        float y21 = (y2 + y1) / 2 + arc4random() % 30 - 30;
        CGPoint point3 = CGPointMake(x21, y21);
        CGPoint point4 = CGPointMake(x2, y2);
        
        [_heartAnimationPoints addObject:[NSValue valueWithCGPoint:point1]];
        [_heartAnimationPoints addObject:[NSValue valueWithCGPoint:point2]];
        [_heartAnimationPoints addObject:[NSValue valueWithCGPoint:point3]];
        [_heartAnimationPoints addObject:[NSValue valueWithCGPoint:point4]];
    }
    
    // 从_heartAnimationPoints中随机选取一组point
    int idx = arc4random() % ([_heartAnimationPoints count]/4);
    CGPoint p1 = [[_heartAnimationPoints objectAtIndex:4*idx] CGPointValue];
    CGPoint p2 = [[_heartAnimationPoints objectAtIndex:4*idx+1] CGPointValue];
    CGPoint p3 = [[_heartAnimationPoints objectAtIndex:4*idx+2] CGPointValue];
    CGPoint p4 = [[_heartAnimationPoints objectAtIndex:4*idx+3] CGPointValue];
    CGPathAddQuadCurveToPoint(curvedPath, NULL, p1.x, p1.y, p2.x, p2.y);
    CGPathAddQuadCurveToPoint(curvedPath, NULL, p3.x, p3.y, p4.x, p4.y);
    
    
    animation.path = curvedPath;
    
    CGPathRelease(curvedPath);
    
    //透明度变化
    CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnim.fromValue = [NSNumber numberWithFloat:1.0];
    opacityAnim.toValue = [NSNumber numberWithFloat:0];
    opacityAnim.removedOnCompletion = NO;
    opacityAnim.beginTime = 0;
    opacityAnim.duration = 3;
    
    //比例
    CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    //        int scale = arc4random() % 5 + 5;
    scaleAnim.fromValue = [NSNumber numberWithFloat:.0];//[NSNumber numberWithFloat:((float)scale / 10)];
    scaleAnim.toValue = [NSNumber numberWithFloat:1];
    scaleAnim.removedOnCompletion = NO;
    scaleAnim.fillMode = kCAFillModeForwards;
    scaleAnim.duration = .5;
    
    CAAnimationGroup *animGroup = [CAAnimationGroup animation];
    animGroup.animations = [NSArray arrayWithObjects: scaleAnim,opacityAnim,animation, nil];
    animGroup.duration = 3;
    
    return animGroup;
}

//监听键盘高度变化
-(void)keyboardFrameDidChange:(NSNotification*)notice
{
    NSDictionary * userInfo = notice.userInfo;
    NSValue * endFrameValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect endFrame = endFrameValue.CGRectValue;
    [UIView animateWithDuration:0.25 animations:^{
        if (endFrame.origin.y == self.height) {
            _msgInputView.y =  endFrame.origin.y;
        }else{
            _msgInputView.y =  endFrame.origin.y - _msgInputView.height;
        }
    }];
}

// 监听登出消息
- (void)onLogout:(NSNotification*)notice {
    [self closeVC];
}

#pragma mark TCPlayDecorateDelegate
-(void)closeVC{
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeVC:)]) {
        [_bulletViewOne stopAnimation];
        [_bulletViewTwo stopAnimation];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        //直播更新在线人数和点赞数到列表页
        if (TCLiveListItemType_Live == _liveInfo.type)
        {
            int viewerCount = [_topView getViewerCount] > 0 ? (int)[_topView getViewerCount] - 1 : 0;
            [[TCLiveListMgr sharedMgr] update:_liveInfo.userid viewerCount:viewerCount likeCount:(int)[_topView getLikeCount]];
        }
        
        [self.delegate closeVC: YES];
    }
}
-(void)clickScreen:(UITapGestureRecognizer *)gestureRecognizer{
    [_msgInputFeild resignFirstResponder];
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickScreen:)]) {
        [self.delegate clickScreen:gestureRecognizer];
    }
}

-(void)clickPlayVod{
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickPlayVod)]) {
        [self.delegate clickPlayVod];
    }
}

-(void)onSeek:(UISlider *)slider{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onSeek:)]) {
        [self.delegate onSeek:slider];
    }
}

-(void)onSeekBegin:(UISlider *)slider{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onSeekBegin:)]) {
        [self.delegate onSeekBegin:slider];
    }
}

-(void)onDrag:(UISlider *)slider {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onDrag:)]) {
        [self.delegate onDrag:slider];
    }
}

#pragma mark - AVIMMsgListener

-(void)onRecvGroupSender:(IMUserAble *)info textMsg:(NSString *)msgText{
    
    switch (info.cmdType) {
        case AVIMCMD_Custom_Text: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userName = [info imUserName];
            msgModel.userMsg  =  msgText;
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_NormalMsg;
            [self bulletMsg:msgModel];
            break;
        }
            
        case AVIMCMD_Custom_EnterLive: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userId = info.imUserId;
            msgModel.userName = info.imUserName;
            msgModel.userMsg  =  @"加入直播";
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_MemberEnterRoom;
            
            //收到新增观众消息，判断只有没在观众列表中，数量才需要增加1
            if (![self isAlreadyInAudienceList:msgModel])
            {
                [_topView onUserEnterLiveRoom];
            }
            [self bulletMsg:msgModel];
            
            break;
        }
            
        case AVIMCMD_Custom_ExitLive: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userId = info.imUserId;
            msgModel.userName = info.imUserName;
            msgModel.userMsg  =  @"退出直播";
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_MemberQuitRoom;
            
            [_topView onUserExitLiveRoom];
            [self bulletMsg:msgModel];
            
            break;
        }
            
        case AVIMCMD_Custom_Like: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userId = info.imUserId;
            msgModel.userName = info.imUserName;
            msgModel.userMsg  =  @"点了个赞";
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_Praise;
            
            [self bulletMsg:msgModel];
            [self showLikeHeart];
            [_topView onUserSendLikeMessage];
            break;
        }
            
        case AVIMCMD_Custom_Danmaku: {
            TCMsgModel *msgModel = [[TCMsgModel alloc] init];
            msgModel.userId = info.imUserId;
            msgModel.userName = info.imUserName;
            msgModel.userMsg  =  msgText;
            msgModel.userHeadImageUrl = info.imUserIconUrl;
            msgModel.msgType = TCMsgModelType_DanmaMsg;
            
            [self bulletMsg:msgModel];
            break;
        }
            
        default:
            break;
    }
}

- (void)onRecvGroupSystemMessage:(TIMGroupSystemElem *)msg {
    // 群被解散
    if (msg.type == TIM_GROUP_SYSTEM_DELETE_GROUP_TYPE) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onRecvGroupDeleteMsg)]) {
            [self.delegate onRecvGroupDeleteMsg];
        }
    }
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    _msgInputFeild.text = @"";
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    _msgInputFeild.text = textField.text;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSString *textMsg = [textField.text stringByTrimmingCharactersInSet:[NSMutableCharacterSet whitespaceCharacterSet]];
    if (textMsg.length <= 0) {
        textField.text = @"";
        [HUDHelper alert:@"消息不能为空"];
        return YES;
    }
    
    TCUserInfoData  *profile = [[TCUserInfoModel sharedInstance] getUserProfile];
    TCMsgModel *msgModel = [[TCMsgModel alloc] init];
    msgModel.userName = @"我";
    msgModel.userMsg  = textMsg;
    msgModel.userHeadImageUrl = profile.faceURL;
    
    if (_bulletBtnIsOn) {
        msgModel.msgType  = TCMsgModelType_DanmaMsg;
        [_msgHandler sendDanmakuMessage:profile.identifier nickName:profile.nickName headPic:profile.faceURL msg:textMsg];
    }else{
        msgModel.msgType = TCMsgModelType_NormalMsg;
        [_msgHandler sendTextMessage:profile.identifier nickName:profile.nickName headPic:profile.faceURL msg:textMsg];
    }
    
    [self bulletMsg:msgModel];
    [_msgInputFeild resignFirstResponder];
    return YES;
}


#pragma mark - 滑动隐藏界面UI
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[event allTouches] anyObject];
    _touchBeginLocation = [touch locationInView:self];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:self];
    [self endMove:location.x - _touchBeginLocation.x];
}


-(void)endMove:(CGFloat)moveX{
    [UIView animateWithDuration:0.2 animations:^{
        if(moveX > 10){
            for (UIView *view in self.subviews) {
                if (![view isEqual:_closeBtn]) {
                    CGRect rect = view.frame;
                    if (rect.origin.x >= 0 && rect.origin.x < SCREEN_WIDTH) {
                        rect = CGRectOffset(rect, self.width, 0);
                        view.frame = rect;
                        [self resetViewAlpha:view];
                    }
                }
            }
        }else if(moveX < -10){
            for (UIView *view in self.subviews) {
                if (![view isEqual:_closeBtn]) {
                    CGRect rect = view.frame;
                    if (rect.origin.x >= SCREEN_WIDTH) {
                        rect = CGRectOffset(rect, -self.width, 0);
                        view.frame = rect;
                        [self resetViewAlpha:view];
                    }
                    
                }
            }
        }
    }];
}

-(void)resetViewAlpha:(UIView *)view{
    CGRect rect = view.frame;
    if (rect.origin.x  >= SCREEN_WIDTH || rect.origin.x < 0) {
        view.alpha = 0;
        _viewsHidden = YES;
    }else{
        view.alpha = 1;
        _viewsHidden = NO;
    }
    if (view == _cover)
        _cover.alpha = 0.5;
}

#pragma mark AudienceListDelegate

-(void)onFetchGroupMemberList:(int)errCode memberCount:(int)memberCount
{
    if (_topView && 0 == errCode)
    {
        [_topView setViewerCount:memberCount likeCount:(int)[_topView getLikeCount]];
    }
}

@end
