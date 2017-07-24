//
//  TDPlayDecorateView.h
//  TDLiveShow
//
//  Created by TD on 2017/7/5.
//  Copyright © 2017年 TD. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDPlayDecorateDelegate <NSObject>

@end

/**
 *  播放模块逻辑view，里面展示了消息列表，弹幕动画，观众列表等UI，其中与SDK的逻辑交互需要交给主控制器处理
 */
@interface TDPlayDecorateView : UIView


@end
