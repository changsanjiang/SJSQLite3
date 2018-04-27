//
//  Book.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"

@interface Book : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger bookID;

@property (nonatomic, strong) NSString *name;

@property (nonatomic) BOOL like;

//@property (nonatomic, strong) Book *BBBBB;


+ (instancetype)bookWithID:(NSInteger)bid name:(NSString *)name;
@end
