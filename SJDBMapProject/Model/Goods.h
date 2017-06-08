//
//  Goods.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/8.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"
@interface Goods : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger goodsID;
@property (nonatomic, strong) NSString *name;

@end
