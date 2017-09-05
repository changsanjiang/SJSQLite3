//
//  SampleVideoSection.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJDBMapUseProtocol.h"

@class SampleVideoModel;

@interface SampleVideoSection : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger sectionId;
@property (nonatomic, strong) NSString *sectionTitle;
@property (nonatomic, strong) NSArray<SampleVideoModel *> *videos;

@end
