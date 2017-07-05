
#import <Foundation/Foundation.h>
#import "TCVideoRecordViewController.h"
#import "TXRTMPSDK/TXUGCRecord.h"
#import "TCVideoPublishController.h"
#import "TCVideoPreviewViewController.h"
#import "V8HorizontalPickerView.h"
#import <AVFoundation/AVFoundation.h>

#define BUTTON_RECORD_SIZE          65
#define BUTTON_CONTROL_SIZE         40
#define MAX_RECORD_TIME             60
#define MIN_RECORD_TIME             5


typedef NS_ENUM(NSInteger,TCLVFilterType) {
    FilterType_None 		= 0,
    FilterType_white        ,   //美白滤镜
    FilterType_langman 		,   //浪漫滤镜
    FilterType_qingxin 		,   //清新滤镜
    FilterType_weimei 		,   //唯美滤镜
    FilterType_fennen 		,   //粉嫩滤镜
    FilterType_huaijiu 		,   //怀旧滤镜
    FilterType_landiao 		,   //蓝调滤镜
    FilterType_qingliang 	,   //清凉滤镜
    FilterType_rixi 		,   //日系滤镜
};

#if POD_PITU
#import "MCCameraDynamicView.h"
#import "MaterialManager.h"
#import "MCTip.h"
@interface TCVideoRecordViewController () <MCCameraDynamicDelegate>

@end
#endif

@interface TCVideoRecordViewController()<TXVideoRecordListener,V8HorizontalPickerViewDelegate,V8HorizontalPickerViewDataSource>
{
    BOOL                            _cameraFront;
    BOOL                            _lampOpened;
    BOOL                            _bottomViewShow;
    
    int                             _beautyDepth;
    int                             _whitenDepth;
    
    BOOL                            _cameraPreviewing;
    BOOL                            _videoRecording;
    UIView *                        _videoRecordView;
    UIButton *                      _btnStartRecord;
    UIButton *                      _btnCamera;
    UIButton *                      _btnLamp;
    UIButton *                      _btnBeauty;
    UIProgressView *                _progressView;
    UILabel *                       _recordTimeLabel;
    int                             _currentRecordTime;
    
    UIView *                        _bottomView;
    UIView *                        _beautyPage;
    UIView *                        _filterPage;
    UIButton *                      _beautyBtn;
    UIButton *                      _filterBtn;
    UISlider*                       _sdBeauty;
    UISlider*                       _sdWhitening;
    V8HorizontalPickerView *        _filterPickerView;
    NSMutableArray *                _filterArray;
    int                             _filterIndex;
    
    BOOL                            _navigationBarHidden;
    BOOL                            _statusBarHidden;
    BOOL                            _appForeground;
    
    UIButton              *_motionBtn;
#if POD_PITU
    MCCameraDynamicView   *_tmplBar;
    NSString              *_materialID;
#else
    UIView                *_tmplBar;
#endif
    UIButton              *_greenBtn;
    V8HorizontalPickerView  *_greenPickerView;
    NSMutableArray *_greenArray;
    
    UILabel               *_beautyLabel;
    UILabel               *_whiteLabel;
    UILabel               *_bigEyeLabel;
    UILabel               *_slimFaceLabel;
    
    
    UISlider              *_sdBigEye;
    UISlider              *_sdSlimFace;
    
    int    _filterType;
    int    _greenIndex;;
    
    float  _eye_level;
    float  _face_level;
}
@end


@implementation TCVideoRecordViewController

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _cameraFront = YES;
        _lampOpened = NO;
        _bottomViewShow = NO;
        
        _beautyDepth = 6.3;
        _whitenDepth = 2.7;
        
        _cameraPreviewing = NO;
        _videoRecording = NO;

        _currentRecordTime = 0;
        _greenArray = [NSMutableArray new];
        [_greenArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"无";
            v.file = nil;
            v.face = [UIImage imageNamed:@"greens_no"];
            v;
        })];
        [_greenArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"卡通";
            v.file = [[NSBundle mainBundle] URLForResource:@"goodluck" withExtension:@"mp4"];;
            v.face = [UIImage imageNamed:@"greens_1"];
            v;
        })];
        [_greenArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"DJ";
            v.file = [[NSBundle mainBundle] URLForResource:@"2gei_5" withExtension:@"mp4"];
            v.face = [UIImage imageNamed:@"greens_2"];
            v;
        })];
        
        _filterIndex = 0;
        _filterArray = [NSMutableArray new];
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"原图";
            v.face = [UIImage imageNamed:@"orginal"];
            v;
        })];
        
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"美白";
            v.face = [UIImage imageNamed:@"fwhite"];
            v;
        })];
        
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"浪漫";
            v.face = [UIImage imageNamed:@"langman"];
            v;
        })];
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"清新";
            v.face = [UIImage imageNamed:@"qingxin"];
            v;
        })];
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"唯美";
            v.face = [UIImage imageNamed:@"weimei"];
            v;
        })];
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"粉嫩";
            v.face = [UIImage imageNamed:@"fennen"];
            v;
        })];
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"怀旧";
            v.face = [UIImage imageNamed:@"huaijiu"];
            v;
        })];
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"蓝调";
            v.face = [UIImage imageNamed:@"landiao"];
            v;
        })];
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"清凉";
            v.face = [UIImage imageNamed:@"qingliang"];
            v;
        })];
        [_filterArray addObject:({
            V8LabelNode *v = [V8LabelNode new];
            v.title = @"日系";
            v.face = [UIImage imageNamed:@"rixi"];
            v;
        })];

        
        [TXUGCRecord shareInstance].recordDelegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onAudioSessionEvent:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
        
        _appForeground = YES;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    [self initBeautyUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _navigationBarHidden = self.navigationController.navigationBar.hidden;
    _statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    
    [self startCameraPreview];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:_navigationBarHidden];
    [[UIApplication sharedApplication]setStatusBarHidden:_statusBarHidden];
    
    [self stopCameraPreview];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)onAudioSessionEvent:(NSNotification*)notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        // 在10.3及以上的系统上，分享跳其它app后再回来会收到AVAudioSessionInterruptionWasSuspendedKey的通知，不处理这个事件。
        if ([info objectForKey:@"AVAudioSessionInterruptionWasSuspendedKey"]) {
            return;
        }
        _appForeground = NO;
        
        if (_videoRecording)
        {
            _videoRecording = NO;
        }
    }else{
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            _appForeground = YES;
        }
    }
}

- (void)onAppDidEnterBackGround:(UIApplication*)app
{
    _appForeground = NO;
    
    if (_videoRecording)
    {
        _videoRecording = NO;
    }
}

- (void)onAppWillEnterForeground:(UIApplication*)app
{
    _appForeground = YES;
}


#pragma mark ---- Common UI ----
-(void)initUI
{
    _videoRecordView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_videoRecordView];
    
    UIImageView* mask_top = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, BUTTON_CONTROL_SIZE)];
    [mask_top setImage:[UIImage imageNamed:@"video_record_mask_top"]];
    [self.view addSubview:mask_top];
    
    UIImageView* mask_buttom = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 100, self.view.frame.size.width, 100)];
    [mask_buttom setImage:[UIImage imageNamed:@"video_record_mask_buttom"]];
    [self.view addSubview:mask_buttom];

    _btnStartRecord = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_RECORD_SIZE, BUTTON_RECORD_SIZE)];
    _btnStartRecord.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - BUTTON_RECORD_SIZE + 10);
    [_btnStartRecord setImage:[UIImage imageNamed:@"startrecord"] forState:UIControlStateNormal];
    [_btnStartRecord setImage:[UIImage imageNamed:@"startrecord_press"] forState:UIControlStateSelected];
    [_btnStartRecord addTarget:self action:@selector(onBtnRecordStartClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnStartRecord];
    
    _btnBeauty = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnBeauty.bounds = CGRectMake(0, 0, 30, 30);
    _btnBeauty.center = CGPointMake(self.view.frame.size.width * 3 / 4 , _btnStartRecord.center.y);
    [_btnBeauty setImage:[UIImage imageNamed:@"beautyex"] forState:UIControlStateNormal];
    [_btnBeauty addTarget:self action:@selector(onBtnBeautyClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnBeauty];
    
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 40, 20)];
    _progressView.center = CGPointMake(self.view.frame.size.width / 2, _btnStartRecord.frame.origin.y - 20);
    _progressView.progressTintColor = UIColorFromRGB(0X0ACCAC);
    _progressView.tintColor = UIColorFromRGB(0XBBBBBB);
    _progressView.progress = _currentRecordTime / MAX_RECORD_TIME;
    [self.view addSubview:_progressView];
    
    UIView * minimumView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 6)];
    minimumView.backgroundColor = UIColorFromRGB(0X0ACCAC);
    minimumView.center = CGPointMake(_progressView.frame.origin.x + _progressView.width*MIN_RECORD_TIME/MAX_RECORD_TIME, _progressView.center.y);
    [self.view addSubview:minimumView];
    
    UILabel * minimumLabel = [[UILabel alloc]init];
    minimumLabel.frame = CGRectMake(5, 1, 150, 150);
    [minimumLabel setText:@"至少要录到这里"];
    [minimumLabel setFont:[UIFont fontWithName:@"" size:14]];
    [minimumLabel setTextColor:[UIColor whiteColor]];
    [minimumLabel sizeToFit];
    UIImageView * minumumImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, minimumLabel.frame.size.width + 10, minimumLabel.frame.size.height + 5)];
    minumumImageView.image = [UIImage imageNamed:@"bubble"];
    [minumumImageView addSubview:minimumLabel];
    minumumImageView.center = CGPointMake(minimumView.center.x + 13, minimumView.frame.origin.y - minimumLabel.frame.size.height);
    [self.view addSubview:minumumImageView];
    minumumImageView.hidden = YES;
    minimumLabel.hidden = YES;
    
    _recordTimeLabel = [[UILabel alloc]init];
    _recordTimeLabel.frame = CGRectMake(0, 0, 100, 100);
    [_recordTimeLabel setText:@"00:00"];
    _recordTimeLabel.font = [UIFont systemFontOfSize:10];
    _recordTimeLabel.textColor = [UIColor whiteColor];
    _recordTimeLabel.textAlignment = NSTextAlignmentLeft;
    [_recordTimeLabel sizeToFit];
    _recordTimeLabel.center = CGPointMake(CGRectGetMaxX(_progressView.frame) - _recordTimeLabel.frame.size.width / 2, _progressView.frame.origin.y - _recordTimeLabel.frame.size.height);
    [self.view addSubview:_recordTimeLabel];
    
    int margin = 0;
    int offsetX = self.view.frame.size.width - 5 - (BUTTON_CONTROL_SIZE >> 1);
    int centerY = margin + (BUTTON_CONTROL_SIZE >> 1);

    UIButton * btnClose = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
    btnClose.center = CGPointMake(offsetX , centerY);
    [btnClose setImage:[UIImage imageNamed:@"kickout"] forState:UIControlStateNormal];
    [btnClose addTarget:self action:@selector(onBtnCloseClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnClose];
    
    _btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnCamera.bounds = CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE);
    _btnCamera.center = CGPointMake(offsetX - BUTTON_CONTROL_SIZE , centerY);
    [_btnCamera setImage:[UIImage imageNamed:@"cameraex"] forState:UIControlStateNormal];
    [_btnCamera addTarget:self action:@selector(onBtnCameraClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnCamera];
    
    _btnLamp = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnLamp.bounds = CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE);
    _btnLamp.center = CGPointMake(offsetX - BUTTON_CONTROL_SIZE * 2 , centerY);
    [_btnLamp setImage:[UIImage imageNamed:@"lamp"] forState:UIControlStateNormal];
    [_btnLamp addTarget:self action:@selector(onBtnLampClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnLamp];
}

-(void)onBtnRecordStartClicked
{
    _videoRecording = !_videoRecording;
    
    if (_videoRecording)
    {
        [self startVideoRecord];
    }
    else
    {
        [self stopVideoRecord];
    }
}

-(void)startCameraPreview
{
    if (_cameraPreviewing == NO)
    {
        //简单设置
        //        TXUGCSimpleConfig * param = [[TXUGCSimpleConfig alloc] init];
        //        param.videoQuality = VIDEO_QUALITY_MEDIUM;
        //        [[TXUGCRecord shareInstance] startCameraSimple:param preview:_videoRecordView];
        //自定义设置
        TXUGCCustomConfig * param = [[TXUGCCustomConfig alloc] init];
        param.videoResolution =  VIDEO_RESOLUTION_540_960;
        param.videoFPS = 20;
        param.videoBitratePIN = 1200;
        [[TXUGCRecord shareInstance] startCameraCustom:param preview:_videoRecordView];
        [[TXUGCRecord shareInstance] setBeautyDepth:_beautyDepth WhiteningDepth:_whitenDepth];
 
        if (_greenIndex >=0 || _greenIndex < _greenArray.count) {
            V8LabelNode *v = [_greenArray objectAtIndex:_greenIndex];
            [[TXUGCRecord shareInstance] setGreenScreenFile:v.file];
        }
        
        [[TXUGCRecord shareInstance] setEyeScaleLevel:_eye_level];
        
        [[TXUGCRecord shareInstance] setFaceScaleLevel:_face_level];
        
        [self setFilter:_filterIndex];
        
#if POD_PITU
        [self motionTmplSelected:_materialID];
#endif
        _cameraPreviewing = YES;
    }
}

-(void)stopCameraPreview
{
    if (_cameraPreviewing == YES)
    {
        [[TXUGCRecord shareInstance] stopCameraPreview];
        _cameraPreviewing = NO;
    }
}

-(void)startVideoRecord
{
    [self refreshRecordTime:0];
    [self startCameraPreview];
    [[TXUGCRecord shareInstance] startRecord];
    
    [_btnStartRecord setImage:[UIImage imageNamed:@"stoprecord"] forState:UIControlStateNormal];
    [_btnStartRecord setImage:[UIImage imageNamed:@"stoprecord_press"] forState:UIControlStateSelected];

}

-(void)stopVideoRecord
{
    [[TXUGCRecord shareInstance] stopRecord];
    
    [_btnStartRecord setImage:[UIImage imageNamed:@"startrecord"] forState:UIControlStateNormal];
    [_btnStartRecord setImage:[UIImage imageNamed:@"startrecord_press"] forState:UIControlStateSelected];
}

-(void)onBtnCloseClicked
{
    [self stopCameraPreview];
    [self stopVideoRecord];
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

-(void)onBtnCameraClicked
{
    _cameraFront = !_cameraFront;
    
    if (_cameraFront)
    {
        [_btnCamera setImage:[UIImage imageNamed:@"cameraex"] forState:UIControlStateNormal];
    }
    else
    {
        [_btnCamera setImage:[UIImage imageNamed:@"cameraex_press"] forState:UIControlStateNormal];
    }
    
    [[TXUGCRecord shareInstance] switchCamera:_cameraFront];
}

-(void)onBtnLampClicked
{
    _lampOpened = !_lampOpened;
    
    BOOL result = [[TXUGCRecord shareInstance] toggleTorch:_lampOpened];
    if (result == NO)
    {
        _lampOpened = !_lampOpened;
        [self toastTip:@"闪光灯启动失败"];
    }
    
    if (_lampOpened)
    {
        [_btnLamp setImage:[UIImage imageNamed:@"lamp_press"] forState:UIControlStateNormal];
    }
    else
    {
        [_btnLamp setImage:[UIImage imageNamed:@"lamp"] forState:UIControlStateNormal];
    }
    
    
}

-(void)onBtnBeautyClicked
{
    _bottomViewShow = !_bottomViewShow;
    
    if (_bottomViewShow)
    {
        [_btnBeauty setImage:[UIImage imageNamed:@"beautyex_press"] forState:UIControlStateNormal];
    }
    else
    {
        [_btnBeauty setImage:[UIImage imageNamed:@"beautyex"] forState:UIControlStateNormal];
    }
    
    _bottomView.hidden = !_bottomViewShow;
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (_bottomViewShow)
    {
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint _touchPoint = [touch locationInView:self.view];
        if (NO == CGRectContainsPoint(_bottomView.frame, _touchPoint))
        {
            [self onBtnBeautyClicked];
        }
    }
}

#pragma mark ---- Video Beauty UI ----
-(void)initBeautyUI
{
    CGSize size = self.view.frame.size;
    
    int bottomViewHeight = 160;
    int bottomButtonHeight = 40;
    
    _bottomView = [[UIView alloc] initWithFrame: CGRectMake(0, size.height- bottomViewHeight, size.width, bottomViewHeight)];
    [_bottomView setBackgroundColor:[UIColor whiteColor]];
    _bottomView.hidden = YES;
    [self.view addSubview:_bottomView];
    
    float   beauty_btn_width  = 65;
    float   beauty_btn_height = 19;
#if POD_PITU
    float   beauty_btn_count  = 4;
#else
    float   beauty_btn_count  = 2;
#endif
    float   beauty_center_interval = (_bottomView.width - 30 - beauty_btn_width)/(beauty_btn_count - 1);
    float   first_beauty_center_x  = 15 + beauty_btn_width/2;
    int ib = 0;
    float   beauty_center_y = _bottomView.height - 25;
    
    _beautyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _beautyBtn.center = CGPointMake(first_beauty_center_x, beauty_center_y);
    _beautyBtn.bounds = CGRectMake(0, 0, beauty_btn_width, beauty_btn_height);
    [_beautyBtn setImage:[UIImage imageNamed:@"white_beauty"] forState:UIControlStateNormal];
    [_beautyBtn setImage:[UIImage imageNamed:@"white_beauty_press"] forState:UIControlStateSelected];
    [_beautyBtn setTitle:@"美颜" forState:UIControlStateNormal];
    [_beautyBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_beautyBtn setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateSelected];
    _beautyBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 0);
    _beautyBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    _beautyBtn.tag = 0;
    _beautyBtn.selected = YES;
    [_beautyBtn addTarget:self action:@selector(selectBeautyPage:) forControlEvents:UIControlEventTouchUpInside];
    ++ib;
    
    _filterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _filterBtn.center = CGPointMake(first_beauty_center_x + ib*beauty_center_interval, beauty_center_y);
    _filterBtn.bounds = CGRectMake(0, 0, beauty_btn_width, beauty_btn_height);
    [_filterBtn setImage:[UIImage imageNamed:@"beautiful"] forState:UIControlStateNormal];
    [_filterBtn setImage:[UIImage imageNamed:@"beautiful_press"] forState:UIControlStateSelected];
    [_filterBtn setTitle:@"滤镜" forState:UIControlStateNormal];
    [_filterBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_filterBtn setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateSelected];
    _filterBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 0);
    _filterBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    _filterBtn.tag = 1;
    [_filterBtn addTarget:self action:@selector(selectBeautyPage:) forControlEvents:UIControlEventTouchUpInside];
    ++ib;
    
#if POD_PITU
    _motionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _motionBtn.center = CGPointMake(first_beauty_center_x + ib*beauty_center_interval, beauty_center_y);
    _motionBtn.bounds = CGRectMake(0, 0, beauty_btn_width, beauty_btn_height);
    [_motionBtn setImage:[UIImage imageNamed:@"move"] forState:UIControlStateNormal];
    [_motionBtn setImage:[UIImage imageNamed:@"move_press"] forState:UIControlStateSelected];
    [_motionBtn setTitle:@"动效" forState:UIControlStateNormal];
    [_motionBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_motionBtn setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateSelected];
    _motionBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 0);
    _motionBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    _motionBtn.tag = 2;
    [_motionBtn addTarget:self action:@selector(selectBeautyPage:) forControlEvents:UIControlEventTouchUpInside];
    ib++;

    
    _greenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _greenBtn.center = CGPointMake(first_beauty_center_x + ib*beauty_center_interval, beauty_center_y);
    _greenBtn.bounds = CGRectMake(0, 0, beauty_btn_width, beauty_btn_height);
    [_greenBtn setImage:[UIImage imageNamed:@"greens"] forState:UIControlStateNormal];
    [_greenBtn setImage:[UIImage imageNamed:@"greens_press"] forState:UIControlStateSelected];
    [_greenBtn setTitle:@"绿幕" forState:UIControlStateNormal];
    [_greenBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_greenBtn setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateSelected];
    _greenBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 0);
    _greenBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    _greenBtn.tag = 3;
    [_greenBtn addTarget:self action:@selector(selectBeautyPage:) forControlEvents:UIControlEventTouchUpInside];
    ib++;
#endif
    
    [_bottomView addSubview:_beautyBtn];
    [_bottomView addSubview:_filterBtn];
#if POD_PITU
    [_bottomView addSubview:_motionBtn];
    [_bottomView addSubview:_greenBtn];
#endif
    //美颜 Page
    _beautyPage = [[UIView alloc] init];
    _beautyPage.frame = CGRectMake(0, 0, size.width, bottomViewHeight - bottomButtonHeight);
    [_beautyPage setBackgroundColor:[UIColor whiteColor]];
    
    _beautyLabel = [[UILabel alloc]init];
    
#if POD_PITU
    _beautyLabel.frame = CGRectMake(10,  _beautyBtn.top - 40, 40, 20);
#else
    _beautyLabel.frame = CGRectMake(10,  _beautyBtn.top - 95, 40, 20);
#endif
    [_beautyLabel setText:@"美颜"];
    [_beautyLabel setFont:[UIFont systemFontOfSize:12]];
    
    _sdBeauty = [[UISlider alloc] init];
#if POD_PITU
    _sdBeauty.frame = CGRectMake(_beautyLabel.right, _beautyBtn.top - 40, size.width / 2 - _beautyLabel.right - 7, 20);
#else
    _sdBeauty.frame = CGRectMake(_beautyLabel.right, _beautyBtn.top - 95, size.width - _beautyLabel.right - 10, 20);
#endif
    
    _sdBeauty.minimumValue = 0;
    _sdBeauty.maximumValue = 9;
    _sdBeauty.value = _beautyDepth;
    _sdBeauty.center = CGPointMake(_sdBeauty.center.x, _beautyLabel.center.y);
    [_sdBeauty setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sdBeauty setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sdBeauty setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [_sdBeauty addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    _sdBeauty.tag = 0;
    
    _whiteLabel = [[UILabel alloc] init];

#if POD_PITU
    _whiteLabel.frame = CGRectMake(_sdBeauty.right + 15, _beautyBtn.top - 40, 40, 20);
#else
    _whiteLabel.frame = CGRectMake(10, _beautyBtn.top - 55, 40, 20);
#endif
    [_whiteLabel setText:@"美白"];
    [_whiteLabel setFont:[UIFont systemFontOfSize:12]];
    
    _sdWhitening = [[UISlider alloc] init];

#if POD_PITU
    _sdWhitening.frame = CGRectMake(_whiteLabel.right, _beautyBtn.top - 40, size.width - _whiteLabel.right - 10, 20);
#else
    _sdWhitening.frame = CGRectMake(_whiteLabel.right, _beautyBtn.top - 55, size.width - _whiteLabel.right - 10, 20);
#endif
    _sdWhitening.minimumValue = 0;
    _sdWhitening.maximumValue = 9;
    _sdWhitening.value = _whitenDepth;
    _sdWhitening.center = CGPointMake(_sdWhitening.center.x, _whiteLabel.center.y);
    [_sdWhitening setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sdWhitening setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sdWhitening setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [_sdWhitening addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    _sdWhitening.tag = 1;
    
#if POD_PITU
    _bigEyeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _sdBeauty.top - 60, 40, 20)];
    _bigEyeLabel.text = @"大眼";
    _bigEyeLabel.font = [UIFont systemFontOfSize:12];
    _sdBigEye = [[UISlider alloc] init];
    _sdBigEye.frame =  CGRectMake(_bigEyeLabel.right, _sdBeauty.top - 60, size.width / 2 - _bigEyeLabel.right - 7, 20);
    _sdBigEye.minimumValue = 0;
    _sdBigEye.maximumValue = 9;
    _sdBigEye.value = 0;
    [_sdBigEye setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sdBigEye setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sdBigEye setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [_sdBigEye addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    _sdBigEye.tag = 2;
    
    _slimFaceLabel = [[UILabel alloc] initWithFrame:CGRectMake(_sdBigEye.right + 15, _sdBeauty.top - 60, 40, 20)];
    _slimFaceLabel.text = @"瘦脸";
    _slimFaceLabel.font = [UIFont systemFontOfSize:12];
    _sdSlimFace = [[UISlider alloc] init];
    _sdSlimFace.frame =  CGRectMake(_slimFaceLabel.right, _sdBeauty.top - 60, size.width - _slimFaceLabel.right - 10, 20);
    _sdSlimFace.minimumValue = 0;
    _sdSlimFace.maximumValue = 9;
    _sdSlimFace.value = 0;
    [_sdSlimFace setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sdSlimFace setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sdSlimFace setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [_sdSlimFace addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    _sdSlimFace.tag = 3;
#endif
    
    [_beautyPage addSubview:_beautyLabel];
    [_beautyPage addSubview:_sdBeauty];
    [_beautyPage addSubview:_whiteLabel];
    [_beautyPage addSubview:_sdWhitening];
    [_beautyPage addSubview:_bigEyeLabel];
    [_beautyPage addSubview:_sdBigEye];
    [_beautyPage addSubview:_slimFaceLabel];
    [_beautyPage addSubview:_sdSlimFace];
    [_bottomView addSubview:_beautyPage];
    
    //滤镜 Page
    _filterPage = [[UIView alloc] init];
    _filterPage.frame = CGRectMake(0, 0, size.width, bottomViewHeight - bottomButtonHeight);
    [_filterPage setBackgroundColor:[UIColor whiteColor]];
    _filterPage.hidden = YES;
    
    _filterPickerView = [[V8HorizontalPickerView alloc] init];
    _filterPickerView.frame = CGRectMake(0, 0, size.width, bottomViewHeight - bottomButtonHeight - 20);
    _filterPickerView.center = _filterPage.center;
    _filterPickerView.textColor = [UIColor grayColor];
    _filterPickerView.elementFont = [UIFont fontWithName:@"" size:14];
    _filterPickerView.delegate = self;
    _filterPickerView.dataSource = self;
    _filterPickerView.selectedMaskView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"filter_selected"]];
    
    [_filterPage addSubview:_filterPickerView];
    [_bottomView addSubview:_filterPage];
    
    
#if POD_PITU
    _tmplBar = [[MCCameraDynamicView alloc] initWithFrame:CGRectMake(0.f, 0, size.width, 115.f)];
    _tmplBar.delegate = self;
    _tmplBar.hidden = YES;
    [_bottomView addSubview:_tmplBar];
    
    _greenPickerView = [[V8HorizontalPickerView alloc] initWithFrame:CGRectMake(0, _beautyBtn.top - 96, size.width, 66)];
    _greenPickerView.selectedTextColor = [UIColor blackColor];
    _greenPickerView.textColor = [UIColor grayColor];
    _greenPickerView.elementFont = [UIFont fontWithName:@"" size:14];
    _greenPickerView.delegate = self;
    _greenPickerView.dataSource = self;
    _greenPickerView.hidden = YES;
    _greenPickerView.selectedMaskView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"greens_selected.png"]];
    _greenIndex = 0;
    [_bottomView addSubview:_greenPickerView];
#endif
}


-(void)selectBeautyPage:(UIButton *)button
{
    switch (button.tag)
    {
        case 0:
            _beautyPage.hidden = NO;
            _beautyBtn.selected = YES;
            
            _filterPage.hidden = YES;
            _filterBtn.selected = NO;
            
            _motionBtn.selected = NO;
            _greenBtn.selected  = NO;
            _tmplBar.hidden = YES;
            _greenPickerView.hidden = YES;
            
            break;
            
        case 1:
            _beautyPage.hidden = YES;
            _beautyBtn.selected = NO;
            
            _filterPage.hidden = NO;
            _filterBtn.selected = YES;
            
            [_filterPickerView scrollToElement:_filterIndex animated:NO];
            
            _motionBtn.selected = NO;
            _greenBtn.selected  = NO;
            _tmplBar.hidden = YES;
            _greenPickerView.hidden = YES;
            break;
            
        case 2: {
            _beautyPage.hidden = YES;
            _beautyBtn.selected = NO;
            
            _filterPage.hidden = YES;
            _filterBtn.selected = NO;
            
            _motionBtn.selected = YES;
            _greenBtn.selected  = NO;
            _tmplBar.hidden = NO;
            _greenPickerView.hidden = YES;
        }
            break;
        case 3: {
            _beautyPage.hidden = YES;
            _beautyBtn.selected = NO;
            
            _filterPage.hidden = YES;
            _filterBtn.selected = NO;
            
            _motionBtn.selected = NO;
            _greenBtn.selected  = YES;
            _tmplBar.hidden = YES;
            _greenPickerView.hidden = NO;
            [_greenPickerView scrollToElement:_greenIndex animated:NO];
        }
    }
}

-(void)sliderValueChange:(UISlider*)obj
{
    int tag = obj.tag;
    float value = obj.value;
    
    switch (tag) {
        case 0:
            _beautyDepth = value;
            [[TXUGCRecord shareInstance] setBeautyDepth:_beautyDepth WhiteningDepth:_whitenDepth];
            break;
            
        case 1:
            _whitenDepth = value;
            [[TXUGCRecord shareInstance] setBeautyDepth:_beautyDepth WhiteningDepth:_whitenDepth];
            break;
        case 2: //大眼
            _eye_level = value;
            [[TXUGCRecord shareInstance] setEyeScaleLevel:_eye_level];
            break;
         case 3:  //瘦脸
            _face_level = value;
            [[TXUGCRecord shareInstance] setFaceScaleLevel:_face_level];
            break;
        default:
            break;
    }
}

-(void)refreshRecordTime:(int)second
{
    _currentRecordTime = second;
    _progressView.progress = (float)_currentRecordTime / MAX_RECORD_TIME;
    int min = second / 60;
    int sec = second % 60;
    
    [_recordTimeLabel setText:[NSString stringWithFormat:@"%02d:%02d", min, sec]];
    [_recordTimeLabel sizeToFit];
}

#pragma mark ---- VideoRecordListener ----
-(void) onRecordProgress:(NSInteger)milliSecond;
{
    if (milliSecond > MAX_RECORD_TIME * 1000)
    {
        [self onBtnRecordStartClicked];
    }
    else
    {
        [self refreshRecordTime: milliSecond / 1000];
    }
}

-(void) onRecordComplete:(TXRecordResult*)result;
{
    if (_appForeground)
    {
        if (_currentRecordTime >= MIN_RECORD_TIME)
        {
            if (result.retCode == RECORD_RESULT_OK) {
                TCVideoPreviewViewController *vc = [[TCVideoPreviewViewController alloc] initWith:kRecordType_Camera  coverImage:result.coverImage RecordResult:result TCLiveInfo:nil];
                [self.navigationController pushViewController:vc animated:YES];
            }
            else {
                [self toastTip:@"录制失败"];
            }
        } else {
            [self toastTip:@"至少要录够5秒"];
        }
    }
    
    [self refreshRecordTime:0];
}
#if POD_PITU
- (void)motionTmplSelected:(NSString *)materialID {
    if (materialID == nil) {
        [MCTip hideText];
    }
    _materialID = materialID;
    if ([MaterialManager isOnlinePackage:materialID]) {
        [[TXUGCRecord shareInstance] selectMotionTmpl:materialID inDir:[MaterialManager packageDownloadDir]];
    } else {
        NSString *localPackageDir = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Resource"];
        [[TXUGCRecord shareInstance] selectMotionTmpl:materialID inDir:localPackageDir];
    }
}
#endif
#pragma mark - HorizontalPickerView DataSource
- (NSInteger)numberOfElementsInHorizontalPickerView:(V8HorizontalPickerView *)picker {
    if (picker == _greenPickerView) {
        return [_greenArray count];
    } else if(picker == _filterPickerView) {
        return [_filterArray count];
    }
    return 0;
}

#pragma mark - HorizontalPickerView Delegate Methods
- (UIView *)horizontalPickerView:(V8HorizontalPickerView *)picker viewForElementAtIndex:(NSInteger)index {
    if (picker == _greenPickerView) {
        V8LabelNode *v = [_greenArray objectAtIndex:index];
        return [[UIImageView alloc] initWithImage:v.face];
    } else if(picker == _filterPickerView) {
        V8LabelNode *v = [_filterArray objectAtIndex:index];
        return [[UIImageView alloc] initWithImage:v.face];
    }
    return nil;
}

- (NSInteger) horizontalPickerView:(V8HorizontalPickerView *)picker widthForElementAtIndex:(NSInteger)index {
    if (picker == _greenPickerView) {
        return 70;
    }
    return 90;
}

- (void)horizontalPickerView:(V8HorizontalPickerView *)picker didSelectElementAtIndex:(NSInteger)index
{
    if (picker == _greenPickerView) {
        _greenIndex = index;
        V8LabelNode *v = [_greenArray objectAtIndex:index];
        [[TXUGCRecord shareInstance] setGreenScreenFile:v.file];
        return;
    }
    if (picker == _filterPickerView) {
        _filterIndex = index;
        
        [self setFilter:_filterIndex];
    }
}

- (void)setFilter:(int)index
{
    NSString* lookupFileName = @"";
    
    switch (index) {
        case FilterType_None:
            break;
        case FilterType_white:
            lookupFileName = @"filter_white";
            break;
        case FilterType_langman:
            lookupFileName = @"filter_langman";
            break;
        case FilterType_qingxin:
            lookupFileName = @"filter_qingxin";
            break;
        case FilterType_weimei:
            lookupFileName = @"filter_weimei";
            break;
        case FilterType_fennen:
            lookupFileName = @"filter_fennen";
            break;
        case FilterType_huaijiu:
            lookupFileName = @"filter_huaijiu";
            break;
        case FilterType_landiao:
            lookupFileName = @"filter_landiao";
            break;
        case FilterType_qingliang:
            lookupFileName = @"filter_qingliang";
            break;
        case FilterType_rixi:
            lookupFileName = @"filter_rixi";
            break;
        default:
            break;
    }
    
    NSString * path = [[NSBundle mainBundle] pathForResource:lookupFileName ofType:@"png"];
    if (path != nil && index != FilterType_None)
    {
        [[TXUGCRecord shareInstance] setFilter:[UIImage imageWithContentsOfFile:path]];
    }
    else
    {
        [[TXUGCRecord shareInstance] setFilter:nil];
    }
}

#pragma mark - Misc Methods

- (float) heightForString:(UITextView *)textView andWidth:(float)width{
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void) toastTip:(NSString*)toastInfo
{
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 100;
    frameRC.size.height -= 100;
    __block UITextView * toastView = [[UITextView alloc] init];
    
    toastView.editable = NO;
    toastView.selectable = NO;
    
    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];
    
    toastView.frame = frameRC;
    
    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;
    
    [self.view addSubview:toastView];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(){
        [toastView removeFromSuperview];
        toastView = nil;
    });
}

@end
