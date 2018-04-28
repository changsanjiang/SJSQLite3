//
//  SJDatabaseMap.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap.h"
#import <objc/message.h>
#import "SJDatabaseFunctions.h"
#import "SJDatabaseMap+RealTime.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJDatabaseMap() {
    NSString *_dbPath;
    dispatch_queue_t _operationQueue;
    sqlite3 *_database;
}
@end

@implementation SJDatabaseMap

+ (instancetype)sharedServer {
    static SJDatabaseMap *_instance;
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
- (void)performTasksWithSubThreadTask:(void (^)(SJDatabaseMap * _Nonnull))subThreadTask mainTreadTask:(void (^__nullable)(SJDatabaseMap * _Nonnull))mainTreadTask {
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

@implementation SJDatabaseMap (Create)
/*!
 *  根据类创建一个表
 */
- (void)createOrUpdateTableWithClass:(Class<SJDBMapUseProtocol>)cls callBlock:(void(^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        result = [mapper createOrUpdateTableWithClass:cls];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}
@end


// MARK: InsertOrUpdate

@implementation SJDatabaseMap (InsertOrUpdate)

- (void)insertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)model callBlock:(void(^ __nullable)(BOOL result))block {
    if ( !model ) {
        if ( block ) block(NO);
        return;
    }
    [self insertOrUpdateDataWithModels:@[model] callBlock:block];
}

- (void)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        result = [mapper insertOrUpdateDataWithModels:models];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

- (void)update:(id<SJDBMapUseProtocol>)model properties:(NSArray<NSString *> *)properties callBlock:(void (^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        result = [mapper update:model properties:properties];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

@end

// MARK: Delete

@implementation SJDatabaseMap (Delete)

- (void)deleteDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue callBlock:(void(^ __nullable)(BOOL result))block {
    [self deleteDataWithClass:cls primaryValues:@[@(primaryValue)] callBlock:block];
}

- (void)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues callBlock:(void (^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        result = [mapper deleteDataWithClass:cls primaryValues:primaryValues];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

- (void)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^ __nullable)(BOOL result))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        result = [mapper deleteDataWithModels:models];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

- (void)deleteDataWithClass:(Class)cls callBlock:(void (^ __nullable)(BOOL r))block {
    __block BOOL result = NO;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        result = [mapper deleteDataWithClass:cls];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(result);
    }];
}

@end


// MARK: Query


@implementation SJDatabaseMap (Query)

- (void)queryAllDataWithClass:(Class<SJDBMapUseProtocol>)cls  completeCallBlock:(void(^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper queryAllDataWithClass:cls];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

- (void)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue completeCallBlock:(void (^ __nullable)(id<SJDBMapUseProtocol> _Nullable model))block {
    __block id <SJDBMapUseProtocol> model = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        model = [mapper queryDataWithClass:cls primaryValue:primaryValue];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(model);
    }];
}

- (void)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper queryDataWithClass:cls queryDict:dict];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

- (void)queryDataWithClass:(Class)cls range:(NSRange)range completeCallBlock:(void(^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper queryDataWithClass:cls range:range];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

- (void)queryQuantityWithClass:(Class)cls completeCallBlock:(void (^ __nullable)(NSInteger quantity))block {
    __block NSInteger quantity = 0;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        quantity = [mapper queryQuantityWithClass:cls];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(quantity);
    }];
}

- (void)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    [self fuzzyQueryDataWithClass:cls queryDict:dict match:SJDatabaseMapFuzzyMatchBilateral completeCallBlock:block];
}

- (void)fuzzyQueryDataWithClass:(Class)cls
                      queryDict:(NSDictionary *)dict
                          match:(SJDatabaseMapFuzzyMatch)match
              completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper fuzzyQueryDataWithClass:cls queryDict:dict match:match];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

- (void)fuzzyQueryDataWithClass:(Class)cls
                       property:(NSString *)fields
                          part1:(NSString *)part1
                          part2:(NSString *)part2
              completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper fuzzyQueryDataWithClass:cls property:fields part1:part1 part2:part2];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

- (void)queryDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper queryDataWithClass:cls primaryValues:primaryValues];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

- (void)queryDataWithClass:(Class)cls property:(NSString *)property values:(NSArray *)values completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper queryDataWithClass:cls property:property values:values];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

@end

@implementation SJDatabaseMap (SortQuery)

- (void)sortQueryWithClass:(Class)cls
                  property:(NSString *)property
                  sortType:(SJDatabaseMapSortType)sortType
         completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper sortQueryWithClass:cls property:property sortType:sortType];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

- (void)sortQueryWithClass:(Class)cls
                  property:(NSString *)property
                  sortType:(SJDatabaseMapSortType)sortType
                     range:(NSRange)range
         completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper sortQueryWithClass:cls property:property sortType:sortType range:range];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

- (void)sortQueryWithClass:(Class)cls
                 queryDict:(NSDictionary *)quertyDict
                 sortField:(NSString *)sortField
                  sortType:(SJDatabaseMapSortType)sortType
         completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable))block {
    __block NSArray<id<SJDBMapUseProtocol>> *models = nil;
    [self performTasksWithSubThreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        models = [mapper sortQueryWithClass:cls queryDict:quertyDict sortField:sortField sortType:sortType];
    } mainTreadTask:^(SJDatabaseMap * _Nonnull mapper) {
        if ( block ) block(models);
    }];
}

@end

NS_ASSUME_NONNULL_END
