//
//  UIView+TDAdd.h
//  TuanDaiV4
//
//  Created by WuSiJun on 2017/3/7.
//  Copyright © 2017年 Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (TDAdd)

@property (nonatomic) CGFloat left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  size;        ///< Shortcut for frame.size.


/**
 返回当前view controller code snap
 */
@property (nullable, nonatomic, readonly) UIViewController *viewController;


/**
 设置视图单个圆角

 @param corner 圆角的左右，底部左右
 @param size   大小
 */
- (void)makeCornerWithDirection:(UIRectCorner)corner cornerSize:(CGSize)size;

/**
 *  @author AndreaArlex, 16-04-09 11:04:55
 *
 *  设置圆角
 *
 *  @param radius 圆角角度
 */
- (void)cornerRadius:(float)radius;

/**
 截图

 @return 截图后的image
 */
- (nonnull UIImage *)imageFromView;

@end
