//
//  LiverListCell.m
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "LiverListCell.h"

@implementation LiverListCell

//单元格初始化方法
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        //去掉单元格选中效果
        self.selectionStyle = UITableViewCellAccessoryNone;
        self.backgroundColor = [UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1];
        //创建cell控件
        [self creatUI];
    }
    return self;
}

- (void)creatUI{
    UIImageView *bgImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 118)];
    bgImg.image = [UIImage imageNamed:@"loginBG.jpg"];
    [self addSubview:bgImg];
}

@end
