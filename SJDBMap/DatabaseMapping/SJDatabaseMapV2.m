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

- (void)insertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)model callBlock:(void(^ __nullable)(BOOL result))block {
    if ( !model ) {
        if ( block ) block(nil);
        return;
    }
    [self insertOrUpdateDataWithModels:@[model] callBlock:block];
}

- (void)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        result = [mapper insertOrUpdateDataWithModels:models];
    } mainTreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

- (void)update:(id<SJDBMapUseProtocol>)model properties:(NSArray<NSString *> *)properties callBlock:(void (^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        result = [mapper update:model properties:properties];
    } mainTreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

@end

// MARK: Delete

@implementation SJDatabaseMapV2 (Delete)

- (void)deleteDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue callBlock:(void(^ __nullable)(BOOL result))block {
    [self deleteDataWithClass:cls primaryValues:@[@(primaryValue)] callBlock:block];
}

- (void)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues callBlock:(void (^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        result = [mapper deleteDataWithClass:cls primaryValues:primaryValues];
    } mainTreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

- (void)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        result = [mapper deleteDataWithModels:models];
    } mainTreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

- (void)deleteDataWithClass:(Class)cls callBlock:(void (^ __nullable)(BOOL r))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        result = [mapper deleteDataWithClass:cls];
    } mainTreadTask:^(SJDatabaseMapV2 * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

@end


// MARK: Query


@implementation SJDatabaseMapV2 (Query)

/*!
 *  查所有记录
 *  返回和这个类有关的所有数据
 */
- (void)queryAllDataWithClass:(Class)cls completeCallBlock:(void(^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    
}

/*!
 *  查单条记录
 */
- (void)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue completeCallBlock:(void (^ __nullable)(id<SJDBMapUseProtocol> _Nullable model))block {
    
}

/*!
 *  查询
 *
 *  dict:
 *     @{
 *          @"name": @"A",
 *          @"tag": @"B"
 *      }
 *  or
 *     @{
 *          @"id" : @[@(0), @(2), @(3)],
 *          @"name":@[@"A", @"B", @"C"]
 *      } ==>>>> ... id in (0, 2, 3) and name in ('A', 'B', 'C')
 */
- (void)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    
}

/*!
 *  查询指定区间数据
 */
- (void)queryDataWithClass:(Class)cls range:(NSRange)range completeCallBlock:(void(^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    
}

/*!
 *  查记录的数量
 *
 *  如果 property 指定为 nil, 则返回所有存储的记录数量.
 */
- (void)queryQuantityWithClass:(Class)cls property:(NSString * __nullable)property completeCallBlock:(void (^ __nullable)(NSInteger quantity))block {
    
}


/*!
 *  模糊查询
 *
 *  default SJDatabaseMapFuzzyMatchBilateral
 *  dict: @{@"name":@"A", @"tag":@"B"}  Key -> Property, Value -> Part
 */
- (void)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    
}


/*!
 *  模糊查询
 *  property : value
 */
- (void)fuzzyQueryDataWithClass:(Class)cls
                      queryDict:(NSDictionary *)dict
                          match:(SJDatabaseMapFuzzyMatch)match
              completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    
}

/*!
 *  模糊查询
 *
 *  例如: 匹配以 AB 开头, 以 EF 结尾.
 *       [DatabaseMapping fuzzyQueryDataWithClass:[Example Class]
 *                                       property:@"name"
 *                                          part1:@"AB"
 *                                          part2:@"EF"
 *                              completeCallBlock:nil]
 */
- (void)fuzzyQueryDataWithClass:(Class)cls
                       property:(NSString *)fields
                          part1:(NSString *)part1
                          part2:(NSString *)part2
              completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    
}


/*!
 *  根据多个主键查寻
 **/
- (void)queryDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    
}

/*!
 *  根据多个值查询
 **/
- (void)queryDataWithClass:(Class)cls property:(NSString *)property values:(NSArray *)values completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    
}

@end

@implementation SJDatabaseMapV2 (SortQuery)

- (void)sortQueryWithClass:(Class)cls
                  property:(NSString *)property
                  sortType:(SJDatabaseMapSortType)sortType
         completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    
}

@end
NS_ASSUME_NONNULL_END
