//
//  SJDBMapUniqueKeysModel.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/11/1.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SJDBMapUniqueKeysModel : NSObject

@property (nonatomic, assign) Class ownerCls;
@property (nonatomic, strong) NSArray<NSString *> *keys;

@end
