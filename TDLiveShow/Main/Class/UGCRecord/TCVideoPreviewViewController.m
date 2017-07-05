
#import <Foundation/Foundation.h>
#import "TCVideoPreviewViewController.h"
#import "TXRTMPSDK/TXUGCRecord.h"
#import "TXRTMPSDK/TXVideoEditer.h"
#import "TCVideoPublishController.h"
#import "TCVideoEditViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define BUTTON_PREVIEW_SIZE         65
#define BUTTON_CONTROL_SIZE         40

@interface TCVideoPreviewViewController()<TXLivePlayListener>
{
    UIView *                        _videoPreview;
    UIButton *                      _btnStartPreview;
    UISlider *                      _sdPreviewSlider;
    
    int                             _recordType;
    UIImage *                       _coverImage;
    BOOL                            _previewing;
    BOOL                            _startPlay;
    
    BOOL                            _navigationBarHidden;
    BOOL                            _statusBarHidden;
    
    TXRecordResult                  *_recordResult;
    TCLiveInfo                      *_liveInfo;
    TXLivePlayer                    *_livePlayer;
}
@end


@implementation TCVideoPreviewViewController

-(instancetype)initWith:(NSInteger)recordType  coverImage:(UIImage*)coverImage RecordResult:(TXRecordResult *)recordResult TCLiveInfo:(TCLiveInfo *)liveInfo
{
    self = [super init];
    if (self)
    {
        _recordType   = (int)recordType;
        _coverImage   = coverImage;
        _previewing   = NO;
        _startPlay    = NO;
        _recordResult = recordResult;
        _liveInfo = liveInfo;
        
        _livePlayer = [[TXLivePlayer alloc] init];
        _livePlayer.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
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
    [self initPreviewUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _navigationBarHidden = self.navigationController.navigationBar.hidden;
    _statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    
    if (_previewing)
    {
        [self startVideoPreview:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:_navigationBarHidden];
    [[UIApplication sharedApplication]setStatusBarHidden:_statusBarHidden];
    
    [self stopVideoPreview:NO];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)dealloc{
    [_livePlayer removeVideoWidget];
}

- (void)onAppDidEnterBackGround:(UIApplication*)app
{
    [self stopVideoPreview:NO];
}

- (void)onAppWillEnterForeground:(UIApplication*)app
{
    if (_previewing)
    {
        [self startVideoPreview:NO];
    }
}

-(void)startVideoPreview:(BOOL) startPlay
{
    if (_recordType == kRecordType_Camera || kRecordType_Play)
    {
        if(startPlay == YES){
            [_livePlayer setupVideoWidget:CGRectZero containView:_videoPreview insertIndex:0];
            [_livePlayer startPlay:_recordResult.videoPath type:PLAY_TYPE_LOCAL_VIDEO];
        }else{
            [_livePlayer resume];
        }
    }
    else
    {
        NSLog(@"startVideoPreview invalid _recordType");
    }
}

-(void)stopVideoPreview:(BOOL) stopPlay
{
    if (_recordType == kRecordType_Camera || _recordType == kRecordType_Play)
    {
        if(stopPlay == YES)
            [_livePlayer stopPlay];
        else
            [_livePlayer pause];
    }
    else
    {
        NSLog(@"stopVideoPreview invalid _recordType");
    }
}

#pragma mark ---- Video Preview ----
-(void)initPreviewUI
{
    UIImageView * coverImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    coverImageView.image = _coverImage;
    [self.view addSubview:coverImageView];
    
    _videoPreview = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview: _videoPreview];
    
    _btnStartPreview = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_PREVIEW_SIZE, BUTTON_PREVIEW_SIZE)];
    _btnStartPreview.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview"] forState:UIControlStateNormal];
    [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview_press"] forState:UIControlStateSelected];
    [_btnStartPreview addTarget:self action:@selector(onBtnPreviewStartClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnStartPreview];
    
    UIButton *btnDelete = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
    btnDelete.center = CGPointMake(self.view.frame.size.width / 4, self.view.frame.size.height - BUTTON_CONTROL_SIZE - 5);
    [btnDelete setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
    [btnDelete setImage:[UIImage imageNamed:@"delete_press"] forState:UIControlStateSelected];
    [btnDelete addTarget:self action:@selector(onBtnDeleteClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnDelete];
    
    UIButton *btnDownload = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
    btnDownload.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - BUTTON_CONTROL_SIZE - 5);
    [btnDownload setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
    [btnDownload setImage:[UIImage imageNamed:@"download_press"] forState:UIControlStateSelected];
    [btnDownload addTarget:self action:@selector(onBtnDownloadClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnDownload];
    
    UIButton *btnShare = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
    btnShare.center = CGPointMake(self.view.frame.size.width * 3 / 4, self.view.frame.size.height - BUTTON_CONTROL_SIZE - 5);
    [btnShare setImage:[UIImage imageNamed:@"shareex"] forState:UIControlStateNormal];
    [btnShare setImage:[UIImage imageNamed:@"shareex_press"] forState:UIControlStateSelected];
    [btnShare addTarget:self action:@selector(onBtnShareClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnShare];
    
    _sdPreviewSlider = [[UISlider alloc] init];
    _sdPreviewSlider.frame = CGRectMake(0, 0, self.view.frame.size.width - 40, 60);
    _sdPreviewSlider.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 80);
    [_sdPreviewSlider setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sdPreviewSlider setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sdPreviewSlider setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [self.view addSubview:_sdPreviewSlider];
}

-(void)onBtnPreviewStartClicked
{
    if (!_startPlay) {
        [self startVideoPreview:YES];
        _startPlay = YES;
    }
    _previewing = !_previewing;
    
    if (_previewing)
    {
        [self startVideoPreview:NO];
        [_btnStartPreview setImage:[UIImage imageNamed:@"pausepreview"] forState:UIControlStateNormal];
        [_btnStartPreview setImage:[UIImage imageNamed:@"pausepreview_press"] forState:UIControlStateSelected];
    }
    else
    {
        [self stopVideoPreview:NO];
        [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview"] forState:UIControlStateNormal];
        [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview_press"] forState:UIControlStateSelected];
    }
}

-(void)onBtnDownloadClicked
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:_recordResult.videoPath] completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error != nil) {
            NSLog(@"save video fail:%@", error);
        }
    }];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)onBtnDeleteClicked
{
    [[NSFileManager defaultManager] removeItemAtPath:_recordResult.videoPath error:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)onBtnShareClicked
{
//    TCVideoPublishController *vc = [[TCVideoPublishController alloc] init:[TXUGCRecord shareInstance] recordType:_recordType RecordResult:_recordResult TCLiveInfo:_liveInfo];
//    [self.navigationController pushViewController:vc animated:YES];
    
    TCVideoEditViewController *vc = [[TCVideoEditViewController alloc] init];
    [vc setVideoPath:_recordResult.videoPath];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TXVideoPreviewListener
-(void) onPlayEvent:(int)EvtID withParam:(NSDictionary*)param
{
    NSDictionary* dict = param;
    dispatch_async(dispatch_get_main_queue(), ^{
       if (EvtID == PLAY_EVT_PLAY_PROGRESS) {
            float progress = [dict[EVT_PLAY_PROGRESS] floatValue];
            [_sdPreviewSlider setValue:progress + 0.5];
            
            float duration = [dict[EVT_PLAY_DURATION] floatValue];
            if (duration > 0 && _sdPreviewSlider.maximumValue != duration) {
                _sdPreviewSlider.minimumValue = 0;
                _sdPreviewSlider.maximumValue = duration;
            }
            return ;
       } else if(EvtID == PLAY_EVT_PLAY_END) {
           [_sdPreviewSlider setValue:0];
           [self stopVideoPreview:YES];
           [self startVideoPreview:YES];
       }
    });
}

-(void) onNetStatus:(NSDictionary*) param
{
    return;
}

@end
