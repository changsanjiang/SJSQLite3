//
//  Person.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/4.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"

@class Book;
@class PersonTag;
@class Goods;
@class TestTest;

@interface Person : NSObject<SJDBMapUseProtocol>

@property (nonatomic, strong) Book *aBook;

@property (nonatomic, assign) NSInteger personID;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSArray<PersonTag *> *tags;

@property (nonatomic, strong) NSString *test;

@property (nonatomic, strong) NSString *teet;

@property (nonatomic, strong) NSString *ttttt;

@property (nonatomic, strong) NSArray<Goods *> *goods;

@property (nonatomic, assign) NSInteger age;

@property (nonatomic, assign) NSInteger group;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, assign) NSInteger ID;

@property (nonatomic, assign) NSInteger unique;

@property (nonatomic, strong) NSURL *tessss;

@property (nonatomic, strong) NSString *teesssf;

@property (nonatomic, strong) TestTest *testTest;

@end
