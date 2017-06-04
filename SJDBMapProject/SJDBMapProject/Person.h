//
//  Person.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/4.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"

@class PersonTag;

@interface Person : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger personID;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSArray<PersonTag *> *tags;

@end
