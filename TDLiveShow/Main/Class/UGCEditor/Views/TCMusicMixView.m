//
//  MusicMixView.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/12.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "TCMusicMixView.h"
#import "UIView+Additions.h"
#import "ColorMacro.h"
#import "TCRangeContent.h"
#import "TCMusicCollectionCell.h"
#import <AVFoundation/AVFoundation.h>


#define PIN_WIDTH 13
#define THUMB_HEIGHT 60
#define BORDER_HEIGHT 2

@interface TCMusicMixView()<TCRangeContentDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation TCMusicMixView
{
    UIView*     _selectView;
    UILabel*    _titleLabel;
    UICollectionView* _musicCollection;
    NSMutableArray*   _allMusicArray;
    NSString*   _selectedFilePath;
    CGFloat     _musicDuration;
    
    UIView*     _editView;
    UIImageView* _musicIcon;
    UILabel*     _songName;
    UIButton*    _deleteBtn;
    UILabel*     _cutTitleLabel;
    
    TCRangeContent* _musicCutSlider;
    UILabel*     _startTimeLabel;
    UILabel*     _endTimeLabel;
    
    UILabel*     _volumeLabel;
    UIButton*     _micBtn;
    UISlider*    _volumeSlider;
    UIButton*     _accompanyBtn;
    
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self loadAllMusics];
        
        _selectView = [[UIView alloc] init];
        [self addSubview:_selectView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"添加音乐";
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = UIColorFromRGB(0x777777);
        [_selectView addSubview:_titleLabel];
        
        UICollectionViewLayout* layout = [[UICollectionViewFlowLayout alloc] init];
        _musicCollection = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _musicCollection.delegate = self;
        _musicCollection.dataSource = self;
        [_musicCollection registerClass:[TCMusicCollectionCell class] forCellWithReuseIdentifier:@"TCMusicCollectionCell"];
        [_selectView addSubview:_musicCollection];
        _selectView.hidden = NO;
        
        
        
        _editView = [[UIView alloc] init];
        _editView.hidden = YES;
        [self addSubview:_editView];
        
        _musicIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"voice"]];
        [_editView addSubview:_musicIcon];
        
        _songName = [[UILabel alloc] init];
        _songName.text = @"歌曲名";
        _songName.textColor = UIColorFromRGB(0x777777);
        _songName.font = [UIFont systemFontOfSize:14];
        _songName.textAlignment = NSTextAlignmentLeft;
        [_editView addSubview:_songName];
        
        _deleteBtn = [[UIButton alloc] init];
        [_deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        [_deleteBtn setTitleColor:UIColorFromRGB(0x0accac) forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(onDeleteBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_editView addSubview:_deleteBtn];
        
        _cutTitleLabel = [[UILabel alloc] init];
        _cutTitleLabel.textColor = UIColorFromRGB(0xcccccc);
        _cutTitleLabel.text = @"截取所需音频片段";
        _cutTitleLabel.textAlignment = NSTextAlignmentCenter;
        _cutTitleLabel.font = [UIFont systemFontOfSize:14];
        [_editView addSubview:_cutTitleLabel];
        
        TCRangeContentConfig* sliderConfig = [TCRangeContentConfig new];
        sliderConfig.pinWidth = 16;
        sliderConfig.borderHeight = 1;
        sliderConfig.thumbHeight = 38;
        sliderConfig.leftPinImage = [UIImage imageNamed:@"audio_left"];
        sliderConfig.rightPigImage = [UIImage imageNamed:@"audio_right"];
        _musicCutSlider = [[TCRangeContent alloc] initWithImageList:@[[UIImage imageNamed:@"wave_chosen"]] config:sliderConfig];
        _musicCutSlider.middleLine.hidden = YES;
        _musicCutSlider.delegate = self;
        [_editView addSubview:_musicCutSlider];
        
        
        _startTimeLabel = [[UILabel alloc] init];
        _startTimeLabel.textColor = UIColorFromRGB(0x777777);
        _startTimeLabel.font = [UIFont systemFontOfSize:10];
        _startTimeLabel.text = @"0:00";
        [_editView addSubview:_startTimeLabel];
        
        _endTimeLabel = [[UILabel alloc] init];
        _endTimeLabel.textColor = UIColorFromRGB(0x777777);
        _endTimeLabel.font = [UIFont systemFontOfSize:10];
        _endTimeLabel.text = @"0:00";
        [_editView addSubview:_endTimeLabel];
        
        _volumeLabel = [[UILabel alloc] init];
        _volumeLabel.textColor = UIColorFromRGB(0x777777);
        _volumeLabel.font = [UIFont systemFontOfSize:14];
        _volumeLabel.text = @"音量控制";
        [_editView addSubview:_volumeLabel];
        
        _micBtn = [UIButton new];
        [_micBtn setImage:[UIImage imageNamed:@"micIcon"] forState:UIControlStateNormal];
        [_micBtn addTarget:self action:@selector(onMicBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_editView addSubview:_micBtn];
        
        _volumeSlider = [[UISlider alloc] init];
        _volumeSlider.minimumValue = 0;
        _volumeSlider.maximumValue = 1;
        _volumeSlider.thumbTintColor = UIColorFromRGB(0x0accac);
        //_volumeSlider.minimumTrackTintColor = UIColorFromRGB(0x777777);
        _volumeSlider.minimumTrackTintColor = UIColor.whiteColor;
        _volumeSlider.maximumTrackTintColor = UIColorFromRGB(0x0accac);
        _volumeSlider.value = 0.5;
        [_volumeSlider setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
        [_volumeSlider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
        [_editView addSubview:_volumeSlider];
        
        _accompanyBtn = [UIButton new];
        [_accompanyBtn setImage:[UIImage imageNamed:@"voice"] forState:UIControlStateNormal];
        [_accompanyBtn addTarget:self action:@selector(onAccompanyBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_editView addSubview:_accompanyBtn];
        
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"MusicMixView dealloc");
}

- (void)loadAllMusics
{
    _allMusicArray = [NSMutableArray new];
    NSArray* mp3Paths = [NSBundle pathsForResourcesOfType:@"mp3" inDirectory:[[NSBundle mainBundle] resourcePath]];

    
    NSString *m4aDir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LocalMusics/"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:m4aDir]) {
        [fileManager createDirectoryAtPath:m4aDir withIntermediateDirectories:NO attributes:nil error:nil];
    }
    else {
        NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:m4aDir];
        for (NSString* fileName in dirEnumerator) {
            if ([[fileName pathExtension] isEqualToString:@"m4a"]) {
                TCMusicInfo* musicInfo = [TCMusicInfo new];
                
                NSString* filePath = [m4aDir stringByAppendingPathComponent:fileName];
                NSURL *url = [NSURL fileURLWithPath:filePath];
                AVURLAsset *musicAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                musicInfo.duration = musicAsset.duration.value / musicAsset.duration.timescale;
                musicInfo.filePath = filePath;
            
                NSArray<NSString*>* names = [[fileName stringByDeletingPathExtension] componentsSeparatedByString:@"_"];
                musicInfo.soneName = names[0];
                musicInfo.singerName = names[1];
                [_allMusicArray addObject:musicInfo];
            }
        }
    }
    
    for (NSString* filePath in mp3Paths) {
        NSURL *url = [NSURL fileURLWithPath:filePath];
        AVURLAsset *musicAsset = [AVURLAsset URLAssetWithURL:url options:nil];
        TCMusicInfo* musicInfo = [TCMusicInfo new];
        musicInfo.duration = musicAsset.duration.value / musicAsset.duration.timescale;

        for (NSString *format in [musicAsset availableMetadataFormats]) {
            for (AVMetadataItem *metadataItem in [musicAsset metadataForFormat:format]) {
                musicInfo.filePath = filePath;
                if([metadataItem.commonKey isEqualToString:@"title"]) {
                    musicInfo.soneName = (NSString *)metadataItem.value;
                }
                else if([metadataItem.commonKey isEqualToString:@"artist"]) {
                    musicInfo.singerName = (NSString *)metadataItem.value;
                }
                
            }
        }
        
        [_allMusicArray addObject:musicInfo];

    }
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _selectView.frame = self.bounds;
    
    _titleLabel.frame = CGRectMake(0, 0, self.width, 14);
    _musicCollection.frame = CGRectMake(15 * kScaleX, _selectView.height - 202.5 * kScaleY, _selectView.width - 30 * kScaleX, 187.5 * kScaleY);
    
    
    _editView.frame = self.bounds;
    
    _musicIcon.frame = CGRectMake(15 * kScaleX, 0, _musicIcon.width, _musicIcon.height);
    _songName.frame = CGRectMake(_musicIcon.right + 15 * kScaleX, 0, _editView.width / 2, 14);
    _deleteBtn.frame = CGRectMake(_editView.width - 15 * kScaleX - 50, 0, 40, _musicIcon.height);
    
    _cutTitleLabel.frame = CGRectMake(15 * kScaleX, _musicIcon.bottom + 40 * kScaleY, _editView.width - 30 * kScaleX, 14);
    _musicCutSlider.frame = CGRectMake((_editView.width - _musicCutSlider.width) / 2, _cutTitleLabel.bottom + 15 * kScaleY, _musicCutSlider.width, _musicCutSlider.height);
    
    _startTimeLabel.frame = CGRectMake(_musicCutSlider.x + _musicCutSlider.leftScale * _musicCutSlider.width + _musicCutSlider.leftPin.width / 2, _musicCutSlider.bottom + 5, 30, 10);
    _endTimeLabel.frame = CGRectMake(_musicCutSlider.x + _musicCutSlider.rightScale * _musicCutSlider.width - 30 + _musicCutSlider.rightPin.width / 2, _musicCutSlider.bottom + 5, 30, 10);
    
    _volumeLabel.frame = CGRectMake(15 * kScaleX, _musicCutSlider.bottom + 70 * kScaleY, 0, 14);
    [_volumeLabel sizeToFit];
    
    
    _micBtn.bounds = CGRectMake(0, 0, 20, 20);
    _micBtn.center = CGPointMake(_volumeLabel.right + _micBtn.width / 2 + 50 * kScaleX, _volumeLabel.center.y);

    _accompanyBtn.bounds = CGRectMake(0, 0, 20, 20);
    _accompanyBtn.center = CGPointMake(self.width - 15 * kScaleX - _accompanyBtn.width / 2, _micBtn.center.y);
    
    _volumeSlider.bounds = CGRectMake(0, 0, _accompanyBtn.left - _micBtn.right - 24 * kScaleX, 20);
    _volumeSlider.center = CGPointMake(_micBtn.right + 12 * kScaleX + _volumeSlider.width / 2, _micBtn.center.y);
}

- (void)addMusicInfo:(TCMusicInfo *)musicInfo
{
    BOOL isExisted = NO;
    for (TCMusicInfo* info in _allMusicArray) {
        if ([info.filePath isEqualToString:musicInfo.filePath]) {
            isExisted = YES;
            break;
        }
    }
    
    if (!isExisted) {
        [_allMusicArray insertObject:musicInfo atIndex:0];
        [_musicCollection reloadData];
    }
    
    [self showMusicInfo:musicInfo];
}


- (void)showMusicInfo:(TCMusicInfo *)musicInfo
{
    _selectedFilePath = musicInfo.filePath;
    
    _musicDuration = musicInfo.duration;
    _songName.text = musicInfo.soneName;
    if (musicInfo.singerName.length > 0) {
        _songName.text = [NSString stringWithFormat:@"%@_%@", musicInfo.soneName, musicInfo.singerName];
    }
    
    _musicCutSlider.leftPinCenterX = _musicCutSlider.pinWidth / 2;
    _musicCutSlider.rightPinCenterX = _musicCutSlider.width - _musicCutSlider.pinWidth / 2;
    [_musicCutSlider setNeedsLayout];
    
    _startTimeLabel.frame = CGRectMake(_musicCutSlider.x + _musicCutSlider.leftPin.x, _musicCutSlider.bottom + 5, 30, 10);
    _startTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", (int)(_musicCutSlider.leftScale *_musicDuration) / 60, (int)(_musicCutSlider.leftScale *_musicDuration) % 60];
    
    _endTimeLabel.frame = CGRectMake(_musicCutSlider.x + _musicCutSlider.rightPin.x + _musicCutSlider.pinWidth - 30, _musicCutSlider.bottom + 5, 30, 10);
    _endTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", (int)(_musicCutSlider.rightScale *_musicDuration) / 60, (int)(_musicCutSlider.rightScale *_musicDuration) % 60];
    
    _cutTitleLabel.text = [NSString stringWithFormat:@"截取所需音频片段%.02f'", (_musicCutSlider.rightScale - _musicCutSlider.leftScale) * _musicDuration];
    
    _selectView.hidden = YES;
    _editView.hidden = NO;
    
    
    CGFloat videoVolume = _volumeSlider.value;
    CGFloat musicVolume = 1 - videoVolume;
    
    [self.delegate onSetBGMWithFilePath:_selectedFilePath startTime:_musicCutSlider.leftScale * _musicDuration endTime:_musicCutSlider.rightScale * _musicDuration];
    [self.delegate onSetVideoVolume:videoVolume musicVolume:musicVolume];

}


#pragma mark - UI control event Handle
- (void)onDeleteBtnClicked:(UIButton*)sender
{
    _editView.hidden = YES;
    _selectView.hidden = NO;
    _musicDuration = 1;
    
//    NSArray* indexPaths = [_musicCollection indexPathsForSelectedItems];
//    if (indexPaths.count > 0) {
//        [_musicCollection deselectItemAtIndexPath:indexPaths[0] animated:NO];
//        [_musicCollection cellForItemAtIndexPath:indexPaths[0]].selected = NO;
//    }
    
     [self.delegate onSetBGMWithFilePath:nil startTime:0 endTime:0];
}

- (void)onMicBtnClicked:(UIButton*)sender
{
    _volumeSlider.value = 0.f;
    [self.delegate onSetVideoVolume:0.f musicVolume:1.f];
}

- (void)onAccompanyBtnClicked:(UIButton*)sender
{
    _volumeSlider.value = 1.f;
    [self.delegate onSetVideoVolume:1.f musicVolume:0.f];
}

- (void)onSliderValueChange:(UISlider*)sender
{
    CGFloat videoVolume = sender.value;
    CGFloat musicVolume = 1 - videoVolume;
    
    [self.delegate onSetVideoVolume:videoVolume musicVolume:musicVolume];
    
}

//- (void)onSongDeleteBtnClicked:(UIButton*)sender
//{
//    MusicInfo* info = _allMusicArray[sender.tag];
//    [[NSFileManager defaultManager] removeItemAtPath:info.filePath error:nil];
//    [_allMusicArray removeObject:info];
//    
//    [_musicCollection reloadData];
//}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _allMusicArray.count + 1;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identify = @"TCMusicCollectionCell";
    TCMusicCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identify forIndexPath:indexPath];
    
    
    //最后一个
    if (indexPath.row == _allMusicArray.count) {
        cell.iconView.image = [UIImage imageNamed:@"music_load"];
        cell.songNameLabel.text = @"本地音频";
        cell.authorNameLabel.hidden = YES;
        cell.deleteBtn.hidden = YES;
    }
    else if (indexPath.row < _allMusicArray.count) {
        cell.authorNameLabel.hidden = NO;
        TCMusicInfo* musicInfo = _allMusicArray[indexPath.row];
        [cell setModel:musicInfo];
        
        //默认歌曲不删
//        if ([musicInfo.filePath.pathExtension isEqualToString:@"mp3"]) {
//            cell.deleteBtn.hidden = YES;
//        }
//        else {
//            cell.deleteBtn.hidden = NO;
//            cell.deleteBtn.tag = indexPath.row;
//            [cell.deleteBtn removeTarget:self action:@selector(onSongDeleteBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
//            [cell.deleteBtn addTarget:self action:@selector(onSongDeleteBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
//            assert(cell.authorNameLabel.hidden == NO);
//            assert( musicInfo.singerName.length > 0);
//        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == _allMusicArray.count) {
        [self.delegate onOpenLocalMusicList];
    }
    else if (indexPath.row < _allMusicArray.count){
        TCMusicInfo* musicInfo = _allMusicArray[indexPath.row];
        [self showMusicInfo:musicInfo];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(110, 90);
}

//设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 7.5;
}


//设置每个item垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 7.5;
}

#pragma mark - RangeContentDelegate
- (void)onRangeLeftChangeEnded:(TCRangeContent *)sender
{
    CGFloat startTime = _musicCutSlider.leftScale *_musicDuration;
    CGFloat endTime = _musicCutSlider.rightScale * _musicDuration;
    
    assert(startTime >= 0 && endTime >= 0 && endTime >= startTime);
    
    _startTimeLabel.frame = CGRectMake(_musicCutSlider.x + _musicCutSlider.leftPin.x, _musicCutSlider.bottom + 5, 30, 10);
    _startTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", (int)(startTime) / 60, (int)(startTime) % 60];
    _cutTitleLabel.text = [NSString stringWithFormat:@"截取所需音频片段%.02f'", (endTime - startTime)];
    
    [self.delegate onSetBGMWithFilePath:_selectedFilePath startTime:startTime endTime:endTime];

}

- (void)onRangeRightChangeEnded:(TCRangeContent *)sender
{
    CGFloat startTime = _musicCutSlider.leftScale *_musicDuration;
    CGFloat endTime = _musicCutSlider.rightScale * _musicDuration;
    
    assert(startTime >= 0 && endTime >= 0 && endTime >= startTime);
    
    _endTimeLabel.frame = CGRectMake(MAX(_startTimeLabel.right, _musicCutSlider.x + _musicCutSlider.rightPin.x + _musicCutSlider.pinWidth - 30), _musicCutSlider.bottom + 5, 30, 10);
    _endTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", (int)(endTime) / 60, (int)(endTime) % 60];
    _cutTitleLabel.text = [NSString stringWithFormat:@"截取所需音频片段%.02f'", (endTime - startTime)];
    
    [self.delegate onSetBGMWithFilePath:_selectedFilePath startTime:startTime endTime:endTime];
}



@end
