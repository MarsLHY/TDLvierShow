//
//  TCVideoJoinController.m
//  TCLVBIMDemo
//
//  Created by annidyfeng on 2017/4/19.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "TCVideoJoinViewController.h"
#import "TCVideoJoinCell.h"
#import "TCVideoEditPrevViewController.h"
#import <TXRTMPSDK/TXVideoEditer.h>

static NSString *indetifer = @"TCVideoJoinCell";

@interface TCVideoJoinViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak) IBOutlet UITableView *tableView;
@end

@implementation TCVideoJoinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_tableView registerNib:[UINib nibWithNibName:@"TCVideoJoinCell" bundle:nil] forCellReuseIdentifier:indetifer];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView setEditing:YES animated:YES];
    
    _reorderVideoList = [NSMutableArray new];
    for (NSString *videoPath in self.videoList) {
        TCVideoJoinCellModel *model = [TCVideoJoinCellModel new];
        model.videoPath = videoPath;
        
        TXVideoInfo *info = [TXVideoInfoReader getVideoInfo:videoPath];
        model.cover = info.coverImage;
        model.duration = info.duration;
        model.width = info.width;
        model.height = info.height;

        [_reorderVideoList addObject:model];
    }
    
    UIBarButtonItem *customBackButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goBack)];
    customBackButton.tintColor = UIColorFromRGB(0x0accac);    
    self.navigationItem.leftBarButtonItem = customBackButton;
    self.navigationItem.title = @"视频合成";
}

- (void)goBack
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"视频将按照列表顺序进行合成，您可以拖动进行片段顺序调整。";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 75;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.reorderVideoList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TCVideoJoinCell *cell = [tableView dequeueReusableCellWithIdentifier:indetifer];
    cell.model = self.reorderVideoList[indexPath.row];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSString *toMove = [self.reorderVideoList objectAtIndex:sourceIndexPath.row];
    [self.reorderVideoList removeObjectAtIndex:sourceIndexPath.row];
    [self.reorderVideoList insertObject:toMove atIndex:destinationIndexPath.row];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.reorderVideoList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }
}

- (IBAction)preview:(id)sender {
    if (self.reorderVideoList.count < 1)
        return;
    
    TCVideoEditPrevViewController *vc = [TCVideoEditPrevViewController new];
    NSMutableArray *list = [NSMutableArray new];
    for (TCVideoJoinCellModel *model in self.reorderVideoList) {
        [list addObject:model.videoPath];
    }
    vc.composeArray = list;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
