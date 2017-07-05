//
//  TCVideoCutView.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCVideoRangeSlider.h"

@protocol TCVideoCutViewDelegate <NSObject>

- (void)onVideoLeftCutChanged:(TCVideoRangeSlider*)sender;
- (void)onVideoRightCutChanged:(TCVideoRangeSlider*)sender;
- (void)onVideoCutChangedEnd:(TCVideoRangeSlider*)sender;
- (void)onVideoCutChange:(TCVideoRangeSlider*)sender seekToPos:(CGFloat)pos;

- (void)onSetSpeedUp:(BOOL)isSpeedUp;
- (void)onSetSpeedUpLevel:(CGFloat)level;

@end

@interface TCVideoCutView : UIView

@property (nonatomic, strong)  TCVideoRangeSlider *videoRangeSlider;
@property (nonatomic, weak) id<TCVideoCutViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame videoPath:(NSString*)videoPath;
- (void)setPlayTime:(CGFloat)time;

@end
