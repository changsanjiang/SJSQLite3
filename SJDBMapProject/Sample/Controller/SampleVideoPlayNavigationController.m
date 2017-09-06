//
//  SampleVideoPlayNavigationController.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/6.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SampleVideoPlayNavigationController.h"

// 视频专用 导航控制器

@interface SampleVideoPlayNavigationController ()

@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *pan;

@end

@implementation SampleVideoPlayNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    _pan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self.interactivePopGestureRecognizer.delegate action:@selector(handleNavigationTransition:)];
    _pan.edges = UIRectEdgeLeft;
#pragma clang diagnostic pop
    [self.view addGestureRecognizer:_pan];
    
    // 禁用系统手势
    self.interactivePopGestureRecognizer.enabled = NO;
    
    // Do any additional setup after loading the view.
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return self.childViewControllers.count > 0;
}

// 不旋转
- (BOOL)shouldAutorotate {
    return NO;
}

@end
