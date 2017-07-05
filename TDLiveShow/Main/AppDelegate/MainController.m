//
//  MainController.m
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "MainController.h"
#import "TDNavigationController.h"
@interface MainController ()
{
    NSMutableArray *_tabbarButtons;
    UIImageView *_bgView;
    UIImageView *_selectedImgView;
    
    //接收设置好的标签栏Button，用于设置填充式选中效果
    UIButton *button1;
    UIButton *button2;
    UIButton *button3;
    UIButton *button4;
    UIButton *button5;
}
@end

@implementation MainController

- (void)viewDidLoad {
    [super viewDidLoad];
    //1.创建选项工具栏
    [self _createTabbarView];
    //2.创建子控制器
    [self _createViewControllers];
    
    //获取创建好的标签栏Button，用于填充式选择效果的实现
    button1 = _tabbarButtons[0];
    button1.selected = YES;
    button2 = _tabbarButtons[1];
    button3 = _tabbarButtons[2];
    button4 = _tabbarButtons[3];
}
//1.创建选项工具栏
- (void)_createTabbarView{
    
    //存储自己创建的标签栏Button
    _tabbarButtons = [NSMutableArray array];
    
    //标签栏背景颜色设置
    _bgView = [[UIImageView alloc] initWithFrame:self.tabBar.bounds];
    _bgView.backgroundColor = [UIColor blackColor];
    [self.tabBar addSubview:_bgView];
    
    //标签栏个模块图片设置
    NSArray *imgNames = @[
                          @"home_tab_icon_1.png",
                          @"home_tab_icon_2.png",
                          @"home_tab_icon_3.png",
                          @"home_tab_icon_4.png",
                          ];
    NSArray *selectimgNames = @[
                                @"home_tab_icon_select_1.png",
                                @"home_tab_icon_select_2.png",
                                @"home_tab_icon_select_3.png",
                                @"home_tab_icon_select_4.png",
                                ];
    
    CGFloat itemWidth = kScreenWidth/imgNames.count;
    for (int i=0; i<imgNames.count; i++) {
        NSString *name = imgNames[i];
        NSString *ImgselectName = selectimgNames[i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(itemWidth*i, 0, itemWidth, 49);
        [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [button setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:ImgselectName] forState:UIControlStateSelected];
        button.tag = i;
        [button addTarget:self action:@selector(selectTab:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabBar addSubview:button];
        [_tabbarButtons addObject:button];
    }
}

//2.创建子控制器
- (void)_createViewControllers{
    //1.定义各个模块的故事版的名字
    NSArray *viewControllerNames = @[@"FirstViewController",@"SecondViewController",@"ThirdViewController",@"FourthViewController"];
    NSMutableArray *viewControllers = [NSMutableArray array];
    for(int i=0;i<viewControllerNames.count;i++) {
        //2.获取控制器名
        UIViewController *ctrl = [[NSClassFromString(viewControllerNames[i]) alloc] init];
        //3.加载每个Nav的跟控制器
        TDNavigationController *navigation = [[TDNavigationController alloc] initWithRootViewController:ctrl];
        [viewControllers addObject:navigation];
    }
    self.viewControllers = viewControllers;
}

//设置选中效果方法
- (void)selectTab:(UIButton *)button {
    NSInteger index = button.tag;
    self.selectedIndex = index;
    switch (index) {
        case 0:
            button1.selected = YES;
            button2.selected = NO;
            button3.selected = NO;
            button4.selected = NO;
            break;
        case 1:
            button1.selected = NO;
            button2.selected = YES;
            button3.selected = NO;
            button4.selected = NO;
            break;
        case 2:
            button1.selected = NO;
            button2.selected = NO;
            button3.selected = YES;
            button4.selected = NO;
            break;
        case 3:
            button1.selected = NO;
            button2.selected = NO;
            button3.selected = NO;
            button4.selected = YES;
            break;
        default:
            break;
    }
}

//渲染，当快要显示时候调用此方法
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //移除tabbar上的按钮出现在
    NSArray *subViews = self.tabBar.subviews;
    for (UIView *view in subViews) {
        Class cla = NSClassFromString(@"UITabBarButton");
        //判断view对象是否是UITabBarButton类型
        if ([view isKindOfClass:cla]) {
            [view removeFromSuperview];
        }
    }
    //布局
    CGFloat itemWidth = kScreenWidth/_tabbarButtons.count;
    for (int i=0; i<_tabbarButtons.count; i++) {
        UIButton *button = _tabbarButtons[i];
        button.frame = CGRectMake(itemWidth*i, 0, itemWidth, 49.f);
    }
    _bgView.frame = self.tabBar.bounds;
}

@end
