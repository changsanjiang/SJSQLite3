//
//  SJDatabaseMapV2.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJDatabaseMapV2.h"
#import <objc/message.h>
#import "SJDatabaseFunctions.h"
#import "SJDatabaseMapV2+RealTime.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJDatabaseMapV2() {
    NSString *_dbPath;
    dispatch_queue_t _operationQueue;
    sqlite3 *_database;
}
@end

@implementation SJDatabaseMapV2

+ (instancetype)sharedServer {
    static SJDatabaseMapV2 *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [self new];
    });
    return _instance;
}
- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if ( !self ) return nil;
    NSAssert(sj_checkoutFolder([path stringByDeletingLastPathComponent]), @"请确认路径是否正确!");
    _dbPath = path;
    _operationQueue = dispatch_queue_create("com.sjdb.serialOperationQueue", DISPATCH_QUEUE_SERIAL);
    [self open];
    return self;
}
- (instancetype)init {
    NSString *defaultPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.sj.databasesDefaultFolder"];
    defaultPath = [defaultPath stringByAppendingPathComponent:@"sjdb.db"];
    return [self initWithPath:defaultPath];
}
- (void)dealloc {
    [self close];
}
- (void)performTasksWithSubThreadTask:(void (^)(SJDatabaseMapV2 * _Nonnull))subThreadTask mainTreadTask:(void (^__nullable)(SJDatabaseMapV2 * _Nonnull))mainTreadTask {
    __weak typeof(self) _self = self;
    dispatch_async(_operationQueue, ^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( subThreadTask ) subThreadTask(self);
        if ( mainTreadTask ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(_self) self = _self;
                if ( !self ) return;
                mainTreadTask(self);
            });
        }
    });
}

#pragma mark -
- (sqlite3 *)database {
    return _database;
}
- (void)open {
    sj_database_open(_dbPath.UTF8String, &_database);
}
- (void)close {
    sj_database_close(&_database);
}
@end


#pragma mark - Create

@implementation SJDatabaseMapV2 (Create)
/*!
 *  根据类创建一个表
 */
- (void)createOrUpdateTableWithClass:(Class<SJDBMapUseProtocol>)cls callBlock:(void(^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        result = [mapper createOrUpdateTableWithClass:cls];
    } mainTreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}
@end


// MARK: InsertOrUpdate

@implementation SJDatabaseMapV2 (InsertOrUpdate)


// MARK: ---------------------------------------------------------
/*!
 *  数据库依据模型来存储. 所以在存储之前, 请将模型更新到最新状态, 再进行存储.
 */
// MARK: ---------------------------------------------------------


/*!
 *  插入数据或更新数据
 *  如果没有表, 会自动创建表
 *
 *  如果是模型具有自增主键, 将会随机插入.
 */
- (void)insertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)model callBlock:(void(^ __nullable)(BOOL result))block {
    
}

/*!
 *  批量插入或更新
 *  如果没有表, 会自动创建表
 *  数组中的模型, 可以不同
 *
 *  如果模型具有自增主键, 将会随机插入.
 */
- (void)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^ __nullable)(BOOL result))block {
    [self performTasksWithSubThreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        [mapper insertOrUpdateDataWithModels:models];
    } mainTreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        
    }];
}

/*!
 *  更新指定的属性
 *  如果数据库没有这个模型, 将不会保存
 
 *  property:@[@"name", @"age"]
 */
- (void)update:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields callBlock:(void (^ __nullable)(BOOL result))block {
    
}

/*!
 *  提供更详细的信息去更新, 这将提高更新速度
 *  如果数据库没有这个模型, 将不会保存
 *
 *  insertedOrUpdatedValues : key 更新的这个模型对应的属性. value 属性 更新/新增 的模型, 可以是数组, 也可以是单个模型
 *  更新之前, 请将模型赋值为最新状态.
 *  @{@"tags":@[newTag1, newTag2], @"age":@(newAge)}
 */
- (void)update:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> * __nullable)insertedOrUpdatedValues callBlock:(void (^ __nullable)(BOOL result))block {
    
}

/*!
 *  此接口针对数组字段使用.
 *  如果数据库没有这个模型, 将不会保存
 *
 */
- (void)updateTheDeletedValuesInTheModel:(id<SJDBMapUseProtocol>)model callBlock:(void (^)(BOOL result))block {
    
}

@end

NS_ASSUME_NONNULL_END
