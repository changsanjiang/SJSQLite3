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

#import <Masonry.h>


typedef NS_ENUM(NSUInteger, _SJMaskStyle) {
    _SJMaskStyle_bottom,
    _SJMaskStyle_top,
};

@interface _SJMaskView : UIView
- (instancetype)initWithStyle:(_SJMaskStyle)style;
@end


@interface SampleTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *organLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView0;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView2;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView3;

@property (nonatomic, strong, readonly) _SJMaskView *bottomMaskView;

@end

@implementation SampleTableViewCell

@synthesize bottomMaskView = _bottomMaskView;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.coverImageView addSubview:self.bottomMaskView];
    [_bottomMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.bottom.trailing.offset(0);
        make.top.equalTo(_userImageView0);
    }];
    
    // Initialization code
}

- (void)setModel:(SampleVideoModel *)model  {
    _model = model;
    [_coverImageView setImageWithURL:[NSURL URLWithString:model.videoCoverUrl] placeholder:[UIImage imageNamed:@"placehodler"]];
    _titleLabel.text = model.title;
    _organLabel.text = model.organ.identification;
    if ( model.likedUsers.count > 0 ) _userImageView0.image = [UIImage imageNamed:model.likedUsers[0].avatar];
    if ( model.likedUsers.count > 1 ) _userImageView1.image = [UIImage imageNamed:model.likedUsers[1].avatar];
    if ( model.likedUsers.count > 2 ) _userImageView2.image = [UIImage imageNamed:model.likedUsers[2].avatar];
    if ( model.likedUsers.count > 3 ) _userImageView3.image = [UIImage imageNamed:model.likedUsers[3].avatar];
}

- (_SJMaskView *)bottomMaskView {
    if ( _bottomMaskView ) return _bottomMaskView;
    _bottomMaskView = [[_SJMaskView alloc] initWithStyle:_SJMaskStyle_bottom];
    return _bottomMaskView;
}

@end




@interface _SJMaskView ()
@property (nonatomic, assign, readwrite) _SJMaskStyle style;
@end

@implementation _SJMaskView {
    CAGradientLayer *_maskGradientLayer;
}

- (instancetype)initWithStyle:(_SJMaskStyle)style {
    self = [super initWithFrame:CGRectZero];
    if ( !self ) return nil;
    self.style = style;
    [self initializeGL];
    return self;
}

- (void)initializeGL {
    self.backgroundColor = [UIColor clearColor];
    _maskGradientLayer = [CAGradientLayer layer];
    switch (_style) {
        case _SJMaskStyle_top: {
            _maskGradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0 alpha:0.42].CGColor,
                                          (__bridge id)[UIColor clearColor].CGColor];
        }
            break;
        case _SJMaskStyle_bottom: {
            _maskGradientLayer.colors = @[(__bridge id)[UIColor clearColor].CGColor,
                                          (__bridge id)[UIColor colorWithWhite:0 alpha:0.42].CGColor];
        }
            break;
    }
    [self.layer addSublayer:_maskGradientLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _maskGradientLayer.frame = self.bounds;
}

@end
