//
//  TCVideoEditViewController.m
//  TCLVBIMDemo
//
//  Created by xiang zhang on 2017/4/10.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "TCVideoEditViewController.h"
#import <TXRTMPSDK/TXVideoEditer.h>
#import <MediaPlayer/MPMediaPickerController.h>
#import <AVFoundation/AVFoundation.h>
#import "TCVideoRangeSlider.h"
#import "TCVideoRangeConst.h"
#import "TCVideoPublishController.h"
#import "UIView+Additions.h"
#import "UIColor+MLPFlatColors.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "TCFilterSettingView.h"
#import "TCVideoPreview.h"
#import "TCBottomTabBar.h"
#import "TCVideoCutView.h"
#import "TCMusicMixView.h"
#import "TCTextAddView.h"
#import "TCVideoTextViewController.h"

typedef  NS_ENUM(NSInteger,ActionType)
{
    ActionType_Save,
    ActionType_Publish,
    ActionType_Save_Publish,
};

@interface TCVideoEditViewController ()<TXVideoGenerateListener,TXVideoJoinerListener,TCVideoPreviewDelegate, TCVideoPreviewDelegate, TCFilterSettingViewDelegate, TCBottomTabBarDelegate, TCVideoCutViewDelegate, TCMusicMixViewDelegate, TCTextAddViewDelegate, TCVideoTextViewControllerDelegate, MPMediaPickerControllerDelegate, UIActionSheetDelegate>

@end

@implementation TCVideoEditViewController
{
    TXVideoEditer       *_ugcEdit;
    TCVideoPreview      *_videoPreview;
    
    
    unsigned long long _fileSize;
    NSMutableArray      *_cutPathList;
    NSString            *_videoOutputPath;
    
    UIProgressView* _playProgressView;
    UILabel*        _startTimeLabel;
    UILabel*        _endTimeLabel;
    CGFloat         _leftTime;
    CGFloat         _rightTime;
    
    ActionType         _actionType;
    
    UILabel*        _generationTitleLabel;
    UIView*         _generationView;
    UIProgressView* _generateProgressView;
    UIButton*       _generateCannelBtn;
    
    UIColor            *_barTintColor;
    
    TCBottomTabBar*       _bottomBar;
    TCVideoCutView    *_videoCutView;
    TCFilterSettingView*  _filterView;
    TCMusicMixView*       _musixMixView;
    TCTextAddView*        _textView;
    
    NSMutableArray<TCVideoTextInfo*>* _videoTextInfos;
}



-(instancetype)init
{
    self = [super init];
    if (self) {
        _cutPathList = [NSMutableArray array];
        _videoOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"outputCut.mp4"];
        
        _videoTextInfos = [NSMutableArray new];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _barTintColor =  self.navigationController.navigationBar.barTintColor;
    self.navigationController.navigationBar.barTintColor =  UIColorFromRGB(0x181818);
    self.navigationController.navigationBar.translucent  =  NO;
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barTintColor =  _barTintColor;
    self.navigationController.navigationBar.translucent  =  YES;
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    [_videoPreview removeNotification];
    _videoPreview = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UILabel *barTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0 , 100, 44)];
    barTitleLabel.backgroundColor = [UIColor clearColor];
    barTitleLabel.font = [UIFont boldSystemFontOfSize:17];
    barTitleLabel.textColor = [UIColor whiteColor];
    barTitleLabel.textAlignment = NSTextAlignmentCenter;
    barTitleLabel.text = @"编辑视频";
    self.navigationItem.titleView = barTitleLabel;
    
    self.view.backgroundColor = UIColor.blackColor;
    
    _videoPreview = [[TCVideoPreview alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 225 * self.view.width / 375) coverImage:nil];
    _videoPreview.delegate = self;
    [self.view addSubview:_videoPreview];
    
    _playProgressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, _videoPreview.bottom, self.view.width, 6)];
    _playProgressView.trackTintColor = UIColorFromRGB(0xd8d8d8);
    _playProgressView.progressTintColor = UIColorFromRGB(0x0accac);
    [self.view addSubview:_playProgressView];
    
    _startTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, _playProgressView.bottom + 10 * kScaleY, 50, 12)];
    _startTimeLabel.text = @"0:00";
    _startTimeLabel.textAlignment = NSTextAlignmentLeft;
    _startTimeLabel.font = [UIFont systemFontOfSize:12];
    _startTimeLabel.textColor = UIColor.lightTextColor;
    [self.view addSubview:_startTimeLabel];
    
    _endTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.width - 15 - 50, _playProgressView.bottom + 10, 50, 12)];
    _endTimeLabel.text = @"0:00";
    _endTimeLabel.textAlignment = NSTextAlignmentRight;
    _endTimeLabel.font = [UIFont systemFontOfSize:12];
    _endTimeLabel.textColor = UIColor.lightTextColor;
    [self.view addSubview:_endTimeLabel];
    
    _bottomBar = [[TCBottomTabBar alloc] initWithFrame:CGRectMake(0, self.view.height - 64 - 50 * kScaleY, self.view.width, 50 * kScaleY)];
    _bottomBar.delegate = self;
    [self.view addSubview:_bottomBar];
    
    CGFloat heightDist = 65 * kScaleY;
    _videoCutView = [[TCVideoCutView alloc] initWithFrame:CGRectMake(0, _playProgressView.bottom + heightDist, self.view.width, _bottomBar.y - _playProgressView.bottom - heightDist) videoPath:_videoPath];
    _videoCutView.delegate = self;
    [self.view addSubview:_videoCutView];
    
    _filterView = [[TCFilterSettingView alloc] initWithFrame:CGRectMake(0, _playProgressView.bottom + heightDist, self.view.width, _bottomBar.y - _playProgressView.bottom - heightDist)];
    _filterView.delegate = self;
    
    _musixMixView = [[TCMusicMixView alloc] initWithFrame:CGRectMake(0, _playProgressView.bottom + heightDist, self.view.width, _bottomBar.y - _playProgressView.bottom - heightDist)];
    _musixMixView.delegate = self;
    
    _textView = [[TCTextAddView alloc] initWithFrame:CGRectMake(0, _playProgressView.bottom + heightDist, self.view.width, _bottomBar.y - _playProgressView.bottom - heightDist)];
    _textView.delegate = self;
    
    TXPreviewParam *param = [[TXPreviewParam alloc] init];
    param.videoView = _videoPreview.renderView;
    param.renderMode =  PREVIEW_RENDER_MODE_FILL_EDGE;
    _ugcEdit = [[TXVideoEditer alloc] initWithPreview:param];
    _ugcEdit.generateDelegate = self;
    _ugcEdit.previewDelegate = _videoPreview;
    
    [_ugcEdit setVideoPath:_videoPath];
    TXVideoInfo *videoMsg = [TXVideoInfoReader getVideoInfo:_videoPath];
    _fileSize   = videoMsg.fileSize;
    CGFloat duration = videoMsg.duration;
    _rightTime = duration;
    _endTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", (int)duration / 60, (int)duration % 60];
    
    
    UIImage *image = [UIImage imageNamed:@"watermark"];
    [_ugcEdit setWaterMark:image normalizationFrame:CGRectMake(0, 0, 0.3 , 0.3 * image.size.height / image.size.width)];
    
    UIBarButtonItem *customBackButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goBack)];
    customBackButton.tintColor = UIColorFromRGB(0x0accac);
    self.navigationItem.leftBarButtonItem = customBackButton;
    
    UIBarButtonItem *customSaveButton = [[UIBarButtonItem alloc] initWithTitle:@"保存"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goSave)];
    customSaveButton.tintColor = UIColorFromRGB(0x0accac);
    self.navigationItem.rightBarButtonItem = customSaveButton;
}


- (UIView*)generatingView
{
    /*用作生成时的提示浮层*/
    if (!_generationView) {
        _generationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height + 64)];
        _generationView.backgroundColor = UIColor.blackColor;
        _generationView.alpha = 0.9f;
        
        _generateProgressView = [UIProgressView new];
        _generateProgressView.center = CGPointMake(_generationView.width / 2, _generationView.height / 2);
        _generateProgressView.bounds = CGRectMake(0, 0, 225, 20);
        _generateProgressView.progressTintColor = UIColorFromRGB(0x0accac);
        [_generateProgressView setTrackImage:[UIImage imageNamed:@"slide_bar_small"]];
        //_generateProgressView.trackTintColor = UIColor.whiteColor;
        //_generateProgressView.transform = CGAffineTransformMakeScale(1.0, 2.0);
        
        _generationTitleLabel = [UILabel new];
        _generationTitleLabel.font = [UIFont systemFontOfSize:14];
        _generationTitleLabel.text = @"视频生成中";
        _generationTitleLabel.textColor = UIColor.whiteColor;
        _generationTitleLabel.textAlignment = NSTextAlignmentCenter;
        _generationTitleLabel.frame = CGRectMake(0, _generateProgressView.y - 34, _generationView.width, 14);
        
        _generateCannelBtn = [UIButton new];
        [_generateCannelBtn setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
        _generateCannelBtn.frame = CGRectMake(_generateProgressView.right + 15, _generationTitleLabel.bottom + 10, 20, 20);
        [_generateCannelBtn addTarget:self action:@selector(onGenerateCancelBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [_generationView addSubview:_generationTitleLabel];
        [_generationView addSubview:_generateProgressView];
        [_generationView addSubview:_generateCannelBtn];
    }
    
    _generateProgressView.progress = 0.f;
    [[[UIApplication sharedApplication] delegate].window addSubview:_generationView];
    return _generationView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_videoPreview playVideo];
}

- (void)goBack
{
    [self pause];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)goSave
{
    [self pause];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil  delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"保存并发布" otherButtonTitles:@"仅保存",@"仅发布", nil];
    [sheet showInView:self.view];
    
}

- (void)pause
{
    [_ugcEdit pausePlay];
    [_videoPreview setPlayBtn:NO];
}


- (void)onGenerateCancelBtnClicked:(UIButton*)sender
{
    _generationView.hidden = YES;
    [_ugcEdit cancelGenerate];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0){
        _actionType = ActionType_Save_Publish;
    }
    else if (buttonIndex == 1){
        _actionType = ActionType_Save;
    }
    else if (buttonIndex == 2){
        _actionType = ActionType_Publish;
    }
    
    if (buttonIndex == 0 || buttonIndex == 1 || buttonIndex == 2) {
        if (_fileSize > 200 * 1024 * 1024) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频文件过大,超过200M,暂不支持裁剪！" message:nil delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
        
        _generationView = [self generatingView];
        _generationView.hidden = NO;
        [_ugcEdit setCutFromTime:_leftTime toTime:_rightTime];
        
        [_ugcEdit generateVideo:VIDEO_COMPRESSED_720P videoOutputPath:_videoOutputPath];
        
        [self onVideoPause];
        [_videoPreview setPlayBtn:NO];
    }
}

#pragma mark FilterSettingViewDelegate
- (void)onSetFilterWithImage:(UIImage *)image
{
    [_ugcEdit setFilter:image];
}

#pragma mark - BottomTabBarDelegate
- (void)onCutBtnClicked
{
    //    [self pause];
    [_filterView removeFromSuperview];
    [_musixMixView removeFromSuperview];
    [_textView removeFromSuperview];
    
    [self.view addSubview:_videoCutView];
}

- (void)onFilterBtnClicked
{
    //    [self pause];
    [_videoCutView removeFromSuperview];
    [_musixMixView removeFromSuperview];
    [_textView removeFromSuperview];
    
    
    [self.view addSubview:_filterView];
}

- (void)onMusicBtnClicked
{
    //    [self pause];
    [_filterView removeFromSuperview];
    [_videoCutView removeFromSuperview];
    [_textView removeFromSuperview];
    
    [self.view addSubview:_musixMixView];
}

- (void)onTextBtnClicked
{
    //    [self pause];
    [_filterView removeFromSuperview];
    [_videoCutView removeFromSuperview];
    [_musixMixView removeFromSuperview];
    
    [self.view addSubview:_textView];
}


#pragma mark TXVideoGenerateListener
-(void) onGenerateProgress:(float)progress
{
//    [MBProgressHUD HUDForView:self.view].progress = progress;
    _generateProgressView.progress = progress;
}

-(void) onGenerateComplete:(TXGenerateResult *)result
{
    _generationView.hidden = YES;
    
    if (result.retCode == 0) {
        if (_actionType == ActionType_Save_Publish || _actionType == ActionType_Save) {
            UISaveVideoAtPathToSavedPhotosAlbum(_videoOutputPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }else if (_actionType == ActionType_Publish){
            [self publish];
        }
    }else{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频生成失败"
                                                            message:[NSString stringWithFormat:@"错误码：%ld 错误信息：%@",(long)result.retCode,result.descMsg]
                                                           delegate:self
                                                  cancelButtonTitle:@"知道了"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    if (_actionType == ActionType_Save) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    [self publish];
}


- (void)publish
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    //TXVideoInfo *videoMsg = [TXUGCVideoInfoReader getVideoInfo:_videoOutputPath];
    TCVideoPublishController *vc = [[TCVideoPublishController alloc] initWithPath:_videoOutputPath
                                                                         videoMsg:[TXVideoInfoReader getVideoInfo:_videoOutputPath]];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark TCVideoPreviewDelegate
- (void)onVideoPlay
{
    CGFloat currentPos = _videoCutView.videoRangeSlider.currentPos;
    if (currentPos < _leftTime || currentPos > _rightTime)
        currentPos = _leftTime;

    [_ugcEdit startPlayFromTime:currentPos toTime:_videoCutView.videoRangeSlider.rightPos];
}

- (void)onVideoPause
{
    [_ugcEdit pausePlay];
}

- (void)onVideoResume
{
//    [_ugcEdit resumePlay];
    [self onVideoPlay];
}

- (void)onVideoPlayProgress:(CGFloat)time
{
    _playProgressView.progress = (time - _leftTime) / (_rightTime - _leftTime);
    [_videoCutView setPlayTime:time];
    
}

- (void)onVideoPlayFinished
{
    [_ugcEdit startPlayFromTime:_leftTime toTime:_rightTime];
}

- (void)onVideoEnterBackground
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (_generationView && !_generationView.hidden) {
        _generationView.hidden = YES;
        [_ugcEdit cancelGenerate];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频生成失败"
                                                            message:@"中途切后台导致,请重新生成"
                                                           delegate:self
                                                  cancelButtonTitle:@"知道了"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
    
}

#pragma mark - MusicMixViewDelegate
- (void)onOpenLocalMusicList
{
    [self pause];
    //    MusicCollectionViewController* vc = [[MusicCollectionViewController alloc] initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
    //    [self.navigationController pushViewController:vc animated:YES];
    MPMediaPickerController *mpc = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    mpc.delegate = self;
    mpc.editing = YES;
    mpc.allowsPickingMultipleItems = NO;
    [self presentViewController:mpc animated:YES completion:nil];
}

- (void)onSetVideoVolume:(CGFloat)videoVolume musicVolume:(CGFloat)musicVolume
{
    [_ugcEdit setVideoVolume:videoVolume];
    [_ugcEdit setBGMVolume:musicVolume];
}

- (void)onSetBGMWithFilePath:(NSString *)filePath startTime:(CGFloat)startTime endTime:(CGFloat)endTime
{
    [_ugcEdit setBGM:filePath startTime:startTime endTime:endTime];
    if (filePath == nil) {
        [_ugcEdit setVideoVolume:1.f];
    }
    
    [_ugcEdit startPlayFromTime:_leftTime toTime:_rightTime];
}

#pragma mark - TextAddViewDelegate
- (void)onAddTextBtnClicked
{
    [_videoPreview removeFromSuperview];
    
    NSMutableArray* inRangeVideoTexts = [NSMutableArray new];
    for (TCVideoTextInfo* info in _videoTextInfos) {
        if (info.startTime >= _rightTime || info.endTime <= _leftTime)
            continue;
        
        [inRangeVideoTexts addObject:info];
    }
    
    TCVideoTextViewController* vc = [[TCVideoTextViewController alloc] initWithVideoEditer:_ugcEdit previewView:_videoPreview startTime:_leftTime endTime:_rightTime videoTextInfos:inRangeVideoTexts];
    vc.delegate = self;
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - VideoTextViewControllerDelegate
- (void)onSetVideoTextInfosFinish:(NSArray<TCVideoTextInfo *> *)videoTextInfos
{
    //更新文字信息
    //新增的
    for (TCVideoTextInfo* info in videoTextInfos) {
        if (![_videoTextInfos containsObject:info]) {
            [_videoTextInfos addObject:info];
        }
    }
    
    NSMutableArray* removedTexts = [NSMutableArray new];
    for (TCVideoTextInfo* info in _videoTextInfos) {
        //删除的
        NSUInteger index = [videoTextInfos indexOfObject:info];
        if ( index != NSNotFound) {
            continue;
        }
        
        if (info.startTime < _rightTime && info.endTime > _leftTime)
            [removedTexts addObject:info];
    }
    
    if (removedTexts.count > 0)
        [_videoTextInfos removeObjectsInArray:removedTexts];
    
    _videoPreview.frame = CGRectMake(0, 0, self.view.width, 225 * kScaleY);
    _videoPreview.delegate = self;
    [_videoPreview setPlayBtnHidden:NO];
    [self.view addSubview:_videoPreview];
    
    if (videoTextInfos.count > 0) {
        [_textView setEdited:YES];
    }
    else {
        [_textView setEdited:NO];
    }
}



#pragma mark - VideoCutViewDelegate
- (void)onVideoLeftCutChanged:(TCVideoRangeSlider *)sender
{
    //[_ugcEdit pausePlay];
    [_videoPreview setPlayBtn:NO];
    [_ugcEdit previewAtTime:sender.leftPos];
}

- (void)onVideoRightCutChanged:(TCVideoRangeSlider *)sender
{
    [_videoPreview setPlayBtn:NO];
    [_ugcEdit previewAtTime:sender.rightPos];
}

- (void)onVideoCutChangedEnd:(TCVideoRangeSlider *)sender
{
    _leftTime = sender.leftPos;
    _rightTime = sender.rightPos;
    _startTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", (int)sender.leftPos / 60, (int)sender.leftPos % 60];
    _endTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", (int)sender.rightPos / 60, (int)sender.rightPos % 60];
    [_ugcEdit startPlayFromTime:sender.leftPos toTime:sender.rightPos];
    [_videoPreview setPlayBtn:YES];
}

- (void)onVideoCutChange:(TCVideoRangeSlider *)sender seekToPos:(CGFloat)pos
{
    [_ugcEdit previewAtTime:pos];
    [_videoPreview setPlayBtn:NO];
    _playProgressView.progress = (pos - _leftTime) / (_rightTime - _leftTime);
}

- (void)onSetSpeedUp:(BOOL)isSpeedUp
{
    if (isSpeedUp) {
        [_ugcEdit setSpeedLevel:2.0];
    } else {
        [_ugcEdit setSpeedLevel:1.0];
    }
}

- (void)onSetSpeedUpLevel:(CGFloat)level
{
    [_ugcEdit setSpeedLevel:level];
}

- (void)onSetBeautyDepth:(float)beautyDepth WhiteningDepth:(float)whiteningDepth
{
    [_ugcEdit setBeautyFilter:beautyDepth setWhiteningLevel:whiteningDepth];
}



#pragma mark - MPMediaPickerControllerDelegate
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    NSArray *items = mediaItemCollection.items;
    MPMediaItem *songItem = [items objectAtIndex:0];
    
    NSURL *url = [songItem valueForProperty:MPMediaItemPropertyAssetURL];
    NSString* songName = [songItem valueForProperty: MPMediaItemPropertyTitle];
    NSString* authorName = [songItem valueForProperty:MPMediaItemPropertyArtist];
    NSNumber* duration = [songItem valueForKey:MPMediaItemPropertyPlaybackDuration];
    NSLog(@"MPMediaItemPropertyAssetURL = %@", url);
    
    TCMusicInfo* musicInfo = [TCMusicInfo new];
    musicInfo.duration = duration.floatValue;
    musicInfo.soneName = songName;
    musicInfo.singerName = authorName;
    
    if (mediaPicker.editing) {
        mediaPicker.editing = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveAssetURLToFile:musicInfo assetURL:url];
        });
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//点击取消时回调
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 将AssetURL(音乐)导出到app的文件夹并播放
- (void)saveAssetURLToFile:(TCMusicInfo*)musicInfo assetURL:(NSURL*)assetURL
{
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:songAsset presetName:AVAssetExportPresetAppleM4A];
    NSLog (@"created exporter. supportedFileTypes: %@", exporter.supportedFileTypes);
    exporter.outputFileType = @"com.apple.m4a-audio";
    
    [AVAssetExportSession exportPresetsCompatibleWithAsset:songAsset];
    NSString *docDir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LocalMusics/"];
    NSString *exportFilePath = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.m4a", musicInfo.soneName, musicInfo.singerName]];
    
    exporter.outputURL = [NSURL fileURLWithPath:exportFilePath];
    musicInfo.filePath = exportFilePath;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportFilePath]) {
        [_musixMixView addMusicInfo:musicInfo];
        return;
    }
    
    MBProgressHUD* hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hub.labelText = @"音频读取中...";
    
    // do the export
    //__weak typeof(self) weakSelf = self;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        int exportStatus = exporter.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed: {
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exporter.error);
                break;
                
            }
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@"AVAssetExportSessionStatusCompleted: %@", exporter.outputURL);
                
                // 播放背景音乐
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_musixMixView addMusicInfo:musicInfo];
                });
                break;
            }
            case AVAssetExportSessionStatusUnknown: { NSLog (@"AVAssetExportSessionStatusUnknown"); break;}
            case AVAssetExportSessionStatusExporting: { NSLog (@"AVAssetExportSessionStatusExporting"); break;}
            case AVAssetExportSessionStatusCancelled: { NSLog (@"AVAssetExportSessionStatusCancelled"); break;}
            case AVAssetExportSessionStatusWaiting: { NSLog (@"AVAssetExportSessionStatusWaiting"); break;}
            default: { NSLog (@"didn't get export status"); break;}
        }
    }];
}
@end
