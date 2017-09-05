//
//  SampleTableViewCell.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SampleTableViewCell.h"

#import "SampleVideoModel.h"

#import "SampleOrgan.h"

#import "SampleUser.h"

#import <UIImageView+YYWebImage.h>

@interface SampleTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *organLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView0;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView2;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView3;

@end

@implementation SampleTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _coverImageView.backgroundColor = [UIColor colorWithRed:1.0 * (arc4random() % 256 / 255.0)
                                                      green:1.0 * (arc4random() % 256 / 255.0)
                                                       blue:1.0 * (arc4random() % 256 / 255.0)
                                                      alpha:1];
    // Initialization code
}

- (void)setModel:(SampleVideoModel *)model  {
    _model = model;
    [_coverImageView setImageWithURL:[NSURL URLWithString:model.videoCoverUrl] options:YYWebImageOptionSetImageWithFadeAnimation];
    _titleLabel.text = model.title;
    _organLabel.text = model.organ.identification;
    if ( model.likedUsers.count > 0 ) _userImageView0.image = [UIImage imageNamed:model.likedUsers[0].avatar];
    if ( model.likedUsers.count > 1 ) _userImageView1.image = [UIImage imageNamed:model.likedUsers[1].avatar];
    if ( model.likedUsers.count > 2 ) _userImageView2.image = [UIImage imageNamed:model.likedUsers[2].avatar];
    if ( model.likedUsers.count > 3 ) _userImageView3.image = [UIImage imageNamed:model.likedUsers[3].avatar];
}

@end
