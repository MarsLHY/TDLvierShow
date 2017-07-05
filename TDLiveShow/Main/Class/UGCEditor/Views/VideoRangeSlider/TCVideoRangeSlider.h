//
//  TCVideoRangeSlider.h
//  SAVideoRangeSliderExample
//
//  Created by annidyfeng on 2017/4/18.
//  Copyright © 2017年 Andrei Solovjev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCRangeContent.h"


@protocol TCVideoRangeSliderDelegate;

@interface TCVideoRangeSlider : UIView

@property (weak) id<TCVideoRangeSliderDelegate> delegate;

@property (nonatomic) UIScrollView  *bgScrollView;
@property (nonatomic) UIImageView   *middleLine;
@property (nonatomic) TCRangeContentConfig* appearanceConfig;
@property (nonatomic) TCRangeContent *rangeContent;
@property (nonatomic) CGFloat        durationMs;
@property (nonatomic) CGFloat        currentPos;
@property (readonly)  CGFloat        leftPos;
@property (readonly)  CGFloat        rightPos;

- (void)setImageList:(NSArray *)images;
- (void)updateImage:(UIImage *)image atIndex:(NSUInteger)index;

@end


@protocol TCVideoRangeSliderDelegate <NSObject>
- (void)onVideoRangeLeftChanged:(TCVideoRangeSlider *)sender;
- (void)onVideoRangeLeftChangeEnded:(TCVideoRangeSlider *)sender;
- (void)onVideoRangeRightChanged:(TCVideoRangeSlider *)sender;
- (void)onVideoRangeRightChangeEnded:(TCVideoRangeSlider *)sender;
- (void)onVideoRangeLeftAndRightChanged:(TCVideoRangeSlider *)sender;
- (void)onVideoRange:(TCVideoRangeSlider *)sender seekToPos:(CGFloat)pos;
@end
