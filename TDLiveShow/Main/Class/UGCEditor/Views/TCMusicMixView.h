//
//  MusicMixView.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/12.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCMusicCollectionCell.h"


@protocol TCMusicMixViewDelegate <NSObject>

- (void)onOpenLocalMusicList;
- (void)onSetVideoVolume:(CGFloat)videoVolume musicVolume:(CGFloat)musicVolume;
- (void)onSetBGMWithFilePath:(NSString*)filePath startTime:(CGFloat)startTime endTime:(CGFloat)endTime;

@end

@interface TCMusicMixView : UIView

@property (nonatomic, weak) id<TCMusicMixViewDelegate> delegate;

- (void)addMusicInfo:(TCMusicInfo*)musicInfo;

@end
