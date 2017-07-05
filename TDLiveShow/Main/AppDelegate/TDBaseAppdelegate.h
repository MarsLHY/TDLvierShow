//
//  TDBaseAppdelegate.h
//  TDLiveShow
//
//  Created by TD on 2017/7/5.
//  Copyright © 2017年 TD. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDBaseAppdelegate : UIResponder<UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;

+ (instancetype)sharedAppDelegate;

- (UINavigationController *)navigationViewController;

- (UIViewController *)topViewController;

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (NSArray *)popToViewController:(UIViewController *)viewController;

- (UIViewController *)popViewController:(BOOL)animated;

- (NSArray *)popToRootViewController;

- (void)presentViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)())completion;
- (void)dismissViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)())completion;

@end
