//
//  TCVideoCutView.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "TCVideoCutView.h"
#import "TCVideoRangeConst.h"
#import "TCVideoRangeSlider.h"
#import "ColorMacro.h"
#import "UIView+Additions.h"
#import <TXRTMPSDK/TXVideoEditer.h>

@interface TCVideoCutView ()<TCVideoRangeSliderDelegate>

@end

@implementation TCVideoCutView
{
    UILabel*        _cutTipLabel;
    NSMutableArray  *_imageList;
    CGFloat         _duration;
    UILabel         *_timeTipsLabel;
    NSString*       _videoPath;
    
    UIButton*      _speedUpBtn;
    BOOL           _isSpeedUp;
    
    UILabel*      _speedTipLabel;
    UISlider*     _speedUpSlider;
    UILabel*      _speedLabel;

}

- (id)initWithFrame:(CGRect)frame videoPath:(NSString *)videoPath
{
    if (self = [super initWithFrame:frame]) {
        _videoPath = videoPath;
        _isSpeedUp = NO;
        
        _cutTipLabel = [[UILabel alloc] init];
        _cutTipLabel.text = @"设定想要截取的片段";
        _cutTipLabel.textAlignment = NSTextAlignmentCenter;
        _cutTipLabel.textColor = UIColorFromRGB(0x777777);
        [self addSubview:_cutTipLabel];
        
        _timeTipsLabel = [[UILabel alloc] init];
        _timeTipsLabel.text = @"0 s";
        _timeTipsLabel.textAlignment = NSTextAlignmentCenter;
        _timeTipsLabel.font = [UIFont systemFontOfSize:14];
        _timeTipsLabel.textColor = UIColorFromRGB(0x777777);
        [self addSubview:_timeTipsLabel];
        
        _speedUpBtn = [UIButton new];
        [_speedUpBtn setBackgroundImage:[UIImage imageNamed:@"2xspeed"] forState:UIControlStateNormal];
        [_speedUpBtn addTarget:self action:@selector(onSpeedUpBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_speedUpBtn];
        _speedUpBtn.hidden = YES;
        
        _speedTipLabel = [UILabel new];
        _speedTipLabel.text = @"设置加速";
        _speedTipLabel.font = [UIFont systemFontOfSize:14];
        _speedTipLabel.textColor = UIColorFromRGB(0x777777);
        [self addSubview:_speedTipLabel];
        
        _speedUpSlider = [UISlider new];
        _speedUpSlider.minimumValue = 1.0;
        _speedUpSlider.maximumValue = 4.0;
        _speedUpSlider.tintColor = UIColorFromRGB(0x0accac);
        [_speedUpSlider setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
        [_speedUpSlider addTarget:self action:@selector(onSpeedUpSliderValueChange:) forControlEvents:UIControlEventValueChanged];
        _speedUpSlider.continuous = NO;
        [self addSubview:_speedUpSlider];
        
        _speedLabel = [UILabel new];
        _speedLabel.text = [NSString stringWithFormat:@" %.1f", 1.0];
        _speedLabel.font = [UIFont systemFontOfSize:14];
        _speedLabel.textColor = UIColorFromRGB(0x777777);
        _speedLabel.textAlignment = NSTextAlignmentRight;
        [_speedLabel sizeToFit];
        [self addSubview:_speedLabel];
        
        TXVideoInfo *videoMsg = [TXVideoInfoReader getVideoInfo:_videoPath];
        _duration   = videoMsg.duration;
        
        
        //显示微缩图列表
        _imageList = [NSMutableArray new];
        int imageNum = 10;
        
        [TXVideoInfoReader getSampleImages:imageNum videoPath:_videoPath progress:^(int number, UIImage *image) {
            if (number == 1) {
                _videoRangeSlider = [[TCVideoRangeSlider alloc] initWithFrame:CGRectMake(0, _cutTipLabel.bottom + 50 * kScaleY, self.width, MIDDLE_LINE_HEIGHT)];
                [self addSubview:_videoRangeSlider];
                _videoRangeSlider.delegate = self;
                for (int i = 0; i < imageNum; i++) {
                    [_imageList addObject:image];
                }
                [_videoRangeSlider setImageList:_imageList];
                [_videoRangeSlider setDurationMs:_duration];
            } else {
                if (number > imageNum) {
                    return;
                }
                _imageList[number-1] = image;
                [_videoRangeSlider updateImage:image atIndex:number-1];
            }
        }];
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _cutTipLabel.frame = CGRectMake(0, 0, self.width, 14);
    _timeTipsLabel.frame = CGRectMake(0, _cutTipLabel.bottom + 20 * kScaleY, self.width, 20);
    _videoRangeSlider.frame = CGRectMake(0, _timeTipsLabel.bottom + 10 * kScaleY, self.width, MIDDLE_LINE_HEIGHT);
    _speedUpBtn.frame = CGRectMake(self.width / 2 - 18 * kScaleX, _videoRangeSlider.bottom + 30 * kScaleY, 36 * kScaleX, 36 * kScaleY);
    
    [_speedTipLabel sizeToFit];
    [_speedLabel sizeToFit];
    _speedTipLabel.frame = CGRectMake(15 * kScaleX, _videoRangeSlider.bottom + 25 * kScaleY, _speedTipLabel.width, 20);
    _speedUpSlider.frame = CGRectMake(_speedTipLabel.right + 10 * kScaleX, _speedTipLabel.y, self.width - 50 * kScaleX - _speedLabel.width - _speedTipLabel.width, 20);
    _speedLabel.frame = CGRectMake(_speedUpSlider.right + 10 * kScaleX, _speedTipLabel.y, _speedLabel.width, 20);
}

- (void)dealloc
{
    NSLog(@"VideoCutView dealloc");
}

- (void)setPlayTime:(CGFloat)time
{
    _videoRangeSlider.currentPos = time;
    _timeTipsLabel.text = [NSString stringWithFormat:@"%.2f s",time];
}


#pragma mark - UI Control event handle
- (void)onSpeedUpSliderValueChange:(UISlider*)slider
{
    CGFloat level = slider.value;
    _speedLabel.text = [NSString stringWithFormat:@"%.1f", level];
    [self.delegate onSetSpeedUpLevel:level];
}

- (void)onSpeedUpBtnClicked:(UIButton*)sender
{
    if (_isSpeedUp) {
        [sender setBackgroundImage:[UIImage imageNamed:@"2xspeed" ] forState:UIControlStateNormal];
    } else {
        [sender setBackgroundImage:[UIImage imageNamed:@"2xspeedpressed"] forState:UIControlStateNormal];
    }
    
    _isSpeedUp = !_isSpeedUp;
    [self.delegate onSetSpeedUp:_isSpeedUp];
}

#pragma mark - VideoRangeDelegate
- (void)onVideoRangeLeftChanged:(TCVideoRangeSlider *)sender
{
    [self.delegate onVideoLeftCutChanged:sender];
}

- (void)onVideoRangeLeftChangeEnded:(TCVideoRangeSlider *)sender
{
    _videoRangeSlider.currentPos = sender.leftPos;
    _timeTipsLabel.text = [NSString stringWithFormat:@"%.2f s",sender.leftPos];
    [self.delegate onVideoCutChangedEnd:sender];
}


- (void)onVideoRangeRightChanged:(TCVideoRangeSlider *)sender {
    [self.delegate onVideoRightCutChanged:sender];
}

- (void)onVideoRangeRightChangeEnded:(TCVideoRangeSlider *)sender
{
    _videoRangeSlider.currentPos = sender.leftPos;
    _timeTipsLabel.text = [NSString stringWithFormat:@"%.2f s",sender.leftPos];
    [self.delegate onVideoCutChangedEnd:sender];
}

- (void)onVideoRangeLeftAndRightChanged:(TCVideoRangeSlider *)sender {
    
}

- (void)onVideoRange:(TCVideoRangeSlider *)sender seekToPos:(CGFloat)pos {
    _timeTipsLabel.text = [NSString stringWithFormat:@"%.2f s",pos];
    [self.delegate onVideoCutChange:sender seekToPos:pos];
}

@end
