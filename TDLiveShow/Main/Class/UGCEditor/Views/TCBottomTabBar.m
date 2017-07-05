//
//  TCBottomTabBar.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "TCBottomTabBar.h"
#import "ColorMacro.h"
#import "UIView+Additions.h"

#define kButtonCount 4
#define kButtonNormalColor UIColorFromRGB(0x181818);

@implementation TCBottomTabBar
{
    UIButton*       _btnCut;
    UIButton*       _btnFilter;
    UIButton*       _btnMusic;
    UIButton*       _btnText;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        
        _btnCut = [[UIButton alloc] init];
//        _btnCut.backgroundColor = kButtonNormalColor;
        [_btnCut setImage:[UIImage imageNamed:@"cut_nor"] forState:UIControlStateNormal];
        [_btnCut setImage:[UIImage imageNamed:@"cut_pressed"] forState:UIControlStateHighlighted];
        [_btnCut addTarget:self action:@selector(onCutBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnCut];
        
        _btnFilter = [[UIButton alloc] init];
//        _btnFilter.backgroundColor = kButtonNormalColor;
        [_btnFilter setImage:[UIImage imageNamed:@"beautiful_nor"] forState:UIControlStateNormal];
        [_btnFilter setImage:[UIImage imageNamed:@"beautiful_pressed"] forState:UIControlStateNormal];
        [_btnFilter addTarget:self action:@selector(onFilterBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnFilter];
        
        _btnMusic = [[UIButton alloc] init];
//        _btnMusic.backgroundColor = kButtonNormalColor;
        [_btnMusic setImage:[UIImage imageNamed:@"music_pressed"] forState:UIControlStateNormal];
        [_btnMusic addTarget:self action:@selector(onMusicBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnMusic];
        
        _btnText = [[UIButton alloc] init];
//        _btnText.backgroundColor = kButtonNormalColor;
        [_btnText setImage:[UIImage imageNamed:@"word"] forState:UIControlStateNormal];
        [_btnText addTarget:self action:@selector(onTextBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnText];
        
        [self onCutBtnClicked];
        
    }
    
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat buttonWidth= self.width / kButtonCount;
    _btnCut.frame = CGRectMake(0, 0, buttonWidth, self.height);
    _btnFilter.frame = CGRectMake(buttonWidth, 0, buttonWidth, self.height);
    _btnMusic.frame = CGRectMake(buttonWidth * 2, 0, buttonWidth, self.height);
    _btnText.frame = CGRectMake(buttonWidth * 3, 0, buttonWidth, self.height);
}

- (void)resetButtonNormal
{
    [_btnCut setBackgroundImage:[UIImage imageNamed:@"button_gray"] forState:UIControlStateNormal];
    [_btnFilter setBackgroundImage:[UIImage imageNamed:@"button_gray"] forState:UIControlStateNormal];
    [_btnMusic setBackgroundImage:[UIImage imageNamed:@"button_gray"] forState:UIControlStateNormal];
    [_btnText setBackgroundImage:[UIImage imageNamed:@"button_gray"] forState:UIControlStateNormal];
}


#pragma mark - click handle
- (void)onCutBtnClicked
{
    [self resetButtonNormal];
    [_btnCut setBackgroundImage:[UIImage imageNamed:@"tab"] forState:UIControlStateNormal];
    [self.delegate onCutBtnClicked];
}

- (void)onFilterBtnClicked
{
    [self resetButtonNormal];
    [_btnFilter setBackgroundImage:[UIImage imageNamed:@"tab"] forState:UIControlStateNormal];
    [self.delegate onFilterBtnClicked];
}

- (void)onMusicBtnClicked
{
    [self resetButtonNormal];
    [_btnMusic setBackgroundImage:[UIImage imageNamed:@"tab"] forState:UIControlStateNormal];
    [self.delegate onMusicBtnClicked];
}

- (void)onTextBtnClicked
{
    [self resetButtonNormal];
    [_btnText setBackgroundImage:[UIImage imageNamed:@"tab"] forState:UIControlStateNormal];
    [self.delegate onTextBtnClicked];
}

@end
