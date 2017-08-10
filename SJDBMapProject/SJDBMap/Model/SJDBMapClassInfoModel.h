//
//  SJDBMapClassInfoModel.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/9.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"

@interface SJDBMapClassInfoModel : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger cIMID;

@property (nonatomic, strong) NSArray<Class> *relevanceClasses;

@end
