//
//  SampleVideoPlayViewController.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/6.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SampleVideoPlayViewController.h"

#import "SampleVideoModel.h"

#import <SJVideoPlayer/SJVideoPlayer.h>

#import <Masonry/Masonry.h>

@interface SampleVideoPlayViewController ()

@property (nonatomic, strong, readwrite) SampleVideoModel *video;

@property (nonatomic, strong, readonly) UIView *playerView;

@end

@implementation SampleVideoPlayViewController

- (instancetype)initWithModel:(SampleVideoModel *)video {
    self = [super init];
    if ( !self ) return nil;
    self.video = video;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self _setupView];
    
    [SJVideoPlayer sharedPlayer].assetURL = [NSURL URLWithString:self.video.videoUrl];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self pause];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stop];
}

- (void)play {
    [[SJVideoPlayer sharedPlayer] play];
}

- (void)pause {
    [[SJVideoPlayer sharedPlayer] pause];
}

- (void)stop {
    [[SJVideoPlayer sharedPlayer] stop];
}

- (void)_setupView {
    [self.view addSubview:self.playerView];
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(20);
        make.leading.trailing.offset(0);
        make.height.equalTo(self.playerView.mas_width).multipliedBy(9.0 / 16);
    }];
}

- (UIView *)playerView {
    return [SJVideoPlayer sharedPlayer].view;
}

@end
