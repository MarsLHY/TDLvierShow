//
//  FirstViewController.m
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "FirstViewController.h"
#import "LiverListCell.h"
#import "TDBaseAppdelegate.h"
@interface FirstViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    UITableView *_tableView;
    BOOL         _hasEnterplayVC;   //是否已经进入直播
    
}
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"首页";
    //创建一个直播列表
    [self createUI];
    
    //1.添加下拉刷新的控件
    _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_loadData)];
    [_tableView.mj_header beginRefreshing];
    //默认【上拉加载】
    _tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
}

- (void)createUI{
    //创建一个tablview
    //1、创建表视图
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.f, 0.f, kScreenWidth, kScreenHeight)];
    //2、设置代理
    //去除底部多余单元格分割线
    [_tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];

}

//加载数据
- (void)_loadData{
    [_tableView.mj_header endRefreshing];
}

- (void)loadMore{
    [_tableView.mj_footer endRefreshing];
}

#pragma mark - UITableViewDelegate
//返回单元格个数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 10;
}

//创建单元格
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellId = @"LiverListCell";
    LiverListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if(cell == nil)
    {
        cell = [[LiverListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    /*
    if (_data.count!=0) {
        cell.YhjModel = _data[indexPath.section];
    }
     */
    return cell;
}

//返回单元格高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 128;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    LiverListCell *cell = (LiverListCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    //打开播放界面
    [[TDBaseAppdelegate sharedAppDelegate] pushViewController:_playVC animated:YES];
    if (_playVC==nil) {
      
    }
}

@end
