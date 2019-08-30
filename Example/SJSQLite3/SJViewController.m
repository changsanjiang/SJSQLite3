//
//  SJViewController.m
//  SJSQLite3
//
//  Created by changsanjiang@gmail.com on 07/30/2019.
//  Copyright (c) 2019 changsanjiang@gmail.com. All rights reserved.
//

#import "SJViewController.h"
#import <SJSQLite3.h>
#import <SJSQLite3/SJSQLite3+SJSQLite3Extended.h>
#import "SJList.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJViewController ()
@property (nonatomic, strong) SJSQLite3 *sqlite3;
@end

@implementation SJViewController
/// 插入或更新.
///
- (IBAction)_insertOrUpdate {
    SJList *list = [SJList new];
    list.name = @"list name";
    list.items = @[[[SJItem alloc] initWithName:@"item1"], [[SJItem alloc] initWithName:@"222"]];
    list.short_var = 12;
    list.int_var = 123;
    list.long_var = 1234;
    list.float_var = 12.0f;
    list.double_var = 123.0;
    
    // 添加或更新数据
    //  - 已存在则更新, 不存在则添加
    //
    // 以下为方法详解:
    // save:list
    //  - 需要保存的对象. ( 该对象必须实现`SJSQLiteTableModelProtocol.sql_primaryKey` )
    //
    // error: &error
    //  - 执行的错误回调.
    //
    NSError *error = nil;
    [self.sqlite3 save:list error:&error];
    if ( error ) NSLog(@"%@", error);
}

/// 更新指定的字段
///
- (IBAction)_update {
    // 此处用了两个方法: 1 获取一条数据(结果已转为相应模型). 2 更新指定字段.
    //
    
    // 1 获取一条数据(结果已转为相应模型)
    // 以下为方法详解:
    // objectForClass:
    //  - 查询SJList中保存的数据
    //
    // primaryKeyValue:
    //  - 主键值
    //
    // error: &error
    //  - 执行的错误回调.
    //
    NSError *error = nil;
    SJList *list = [self.sqlite3 objectForClass:SJList.class primaryKeyValue:@(1) error:&error];
    if ( error ) NSLog(@"%@", error);
    
    if ( list ) {
        
        // 2 更新指定字段.
        // 以下为方法详解:
        // update: list
        //  - 需要更新的数据
        //
        // forKey: @"name"
        //  - 需要更新的字段
        //
        // error: &error
        //  - 执行的错误回调.
        //
        list.name = @"new name";
        [self.sqlite3 update:list forKey:@"name" error:&error];
        if ( error ) NSLog(@"%@", error);
        
        // 更新多个字段
        // [self.sqlite3 update:list forKeys:@[@"name", ....] error:&error];
    }
}

/// 查询数据, 获取到的结果为字典. 未进行模型转换.
///
- (IBAction)_query {
    
    // 以下为方法详解:
    // queryDataForClass: SJList.class
    //  - 查询SJList中保存的数据
    //
    // resultColumns: @[@"name", @"items"]
    //  - 返回的结果(字典)的keys.  例如返回结果: { @"name": ... , @"items" : ... }
    //
    // conditions: @[[SJSQLite3Condition conditionWithColumn:@"id" value:@(1)]]
    //  - 查询条件. 此处为查询 id 等于 1 的数据. 此处为数组, 可以传入多个条件.
    //
    // orderBy: nil
    //  - 对结果排序. 此处填了nil, 不需要排序, 按默认的方式返回
    //
    // error: NULL
    //  - 执行的错误回调.
    //
    __auto_type datas = [self.sqlite3 queryDataForClass:SJList.class resultColumns:@[@"name", @"items"] conditions:@[[SJSQLite3Condition conditionWithColumn:@"id" value:@(1)]] orderBy:nil error:NULL];
    NSLog(@"%@", datas);
}

/// 查询数据, 获取到的结果已转为相应模型.
//
- (IBAction)_getObjects {
    // 以下为方法详解:
    // objectsForClass:SJList.class
    //  - 查询SJList中保存的数据
    //
    // conditions: @[[SJSQLite3Condition conditionWithColumn:@"id" value:@(1)]]
    //  - 查询条件. 此处为查询 id 等于 1 的数据. 此处为数组, 可以传入多个条件.
    //
    // orderBy: nil
    //  - 对结果排序. 此处填了nil, 不需要排序, 按默认的方式返回
    //
    // error: NULL
    //  - 执行的错误回调.
    //
    __auto_type objects = [self.sqlite3 objectsForClass:SJList.class conditions:@[[SJSQLite3Condition conditionWithColumn:@"id" value:@(1)]] orderBy:nil error:NULL];
    NSLog(@"%@", objects);
}

/// 分页获取数据
///
- (IBAction)_getObjects2 {
    
    // 获取到的结果已转为相应模型.
    // 以下为方法详解:
    // objectsForClass:SJList.class
    //  - 查询SJList中保存的数据
    //
    // conditions: @[[SJSQLite3Condition conditionWithColumn:@"id" relatedBy:SJSQLite3RelationLessThanOrEqual value:@(999)]]
    //  - 查询条件. 此处为查询 id <= 999 的数据. 此处为数组, 可以传入多个条件.
    //
    // orderBy: nil
    //  - 对结果排序. 此处填了nil, 不需要排序, 按默认的方式返回
    //
    // range: NSMakeRange(0, 10)
    //  - 获取数据的范围. 此处为返回前10条数据.
    //
    // error: NULL
    //  - 执行的错误回调.
    //
    __auto_type objects = [self.sqlite3 objectsForClass:SJList.class conditions:@[[SJSQLite3Condition conditionWithColumn:@"id" relatedBy:SJSQLite3RelationLessThanOrEqual value:@(999)]] orderBy:nil range:NSMakeRange(0, 10) error:NULL];
    NSLog(@"%@", objects);
    
    
    
    
    // 获取到的结果为字典. 未进行模型转换.
    // 以下为方法详解:
    // queryDataForClass: SJList.class
    //  - 查询SJList中保存的数据
    //
    // resultColumns: @[@"name", @"items"]
    //  - 返回的结果(字典)的keys.  例如返回结果: { @"name": ... , @"items" : ... }
    //
    // conditions: @[[SJSQLite3Condition conditionWithColumn:@"id" relatedBy:SJSQLite3RelationLessThanOrEqual value:@(999)]]
    //  - 查询条件. 此处为查询 id <= 999 的数据. 此处为数组, 可以传入多个条件.
    //
    // orderBy: nil
    //  - 对结果排序. 此处填了nil, 不需要排序, 按默认的方式返回
    //
    // range: NSMakeRange(0, 10)
    //  - 获取数据的范围. 此处为返回前10条数据.
    //
    // error: NULL
    //  - 执行的错误回调.
    //
    __auto_type datas = [self.sqlite3 queryDataForClass:SJList.class resultColumns:@[@"name", @"items"] conditions:@[[SJSQLite3Condition conditionWithColumn:@"id" relatedBy:SJSQLite3RelationLessThanOrEqual value:@(999)]] orderBy:nil range:NSMakeRange(0, 10) error:NULL];
    NSLog(@"%@", datas);
}

/// 删除数据
- (IBAction)_delete {
    // 1. 删除 SJItem, SJList 表
    {
        [self.sqlite3 removeAllObjectsForClass:SJItem.class error:NULL];
        [self.sqlite3 removeAllObjectsForClass:SJList.class error:NULL];
    }
    
//    // 2. 删除 SJList 中的某条数据
//    {
//        [self.sqlite3 removeObjectForClass:SJList.class primaryKeyValue:@(1) error:NULL];
//    }
//
//    // 3. 删除多条数据
//    {
//        [self.sqlite3 removeObjectForClass:SJList.class primaryKeyValue:@[@(1), @(2)] error:NULL];
//    }
}

@synthesize sqlite3 = _sqlite3;
- (SJSQLite3 *)sqlite3 {
    if ( _sqlite3 == nil ) {
        _sqlite3 = [[SJSQLite3 alloc] initWithDatabasePath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"test.db"]];
    }
    return _sqlite3;
}
@end
NS_ASSUME_NONNULL_END
