//
//  SJDatabaseMap.m
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap.h"
#import "SJDBMapUseProtocol.h"
#import <objc/message.h>
#import "SJDatabaseMap+RealTime.h"
#import "SJDatabaseMap+GetInfo.h"
#import "SJDBMapUnderstandingModel.h"
#import "SJDBMapPrimaryKeyModel.h"
#import "SJDBMapAutoincrementPrimaryKeyModel.h"
#import "SJDBMapCorrespondingKeyModel.h"
#import "SJDBMapArrayCorrespondingKeysModel.h"


/**
 *  数据文件夹
 */
inline static NSString *_sjDatabaseDefaultFolder() {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.sj.databasesDefaultFolder"];
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] ) [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}

// MARK: Root

@interface SJDatabaseMap ()

/*!
 *  数据库路径
 */
@property (nonatomic, strong, readwrite) NSString   *dbPath;

@property (nonatomic, strong, readonly) dispatch_queue_t operationQueue;

@end


@implementation SJDatabaseMap {
    sqlite3 *_sqDb;
}

@synthesize operationQueue = _operationQueue;

/*!
 *  使用此方法, 数据库将使用默认路径创建
 */
+ (instancetype)sharedServer {
    static SJDatabaseMap *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] initWithPath:[_sjDatabaseDefaultFolder() stringByAppendingPathComponent:@"sjdb.db"]];
    });
    return _instance;
}

/*!
 *  自定义数据库路径
 */
- (instancetype)initWithPath:(NSString *)path {
    if ( !(self = [super init] ) ) return nil;
    if ( SQLITE_OK != sqlite3_open(path.UTF8String, &_sqDb) )
        NSLog(@"初始化数据库失败, 请检查路径");
    _dbPath = path;
    return self;
}

- (sqlite3 *)sqDB {
    return _sqDb;
}

- (dispatch_queue_t)operationQueue {
    if ( _operationQueue ) return _operationQueue;
    _operationQueue = dispatch_queue_create("com.sjdb.serialOperationQueue", NULL);
    return _operationQueue;
}

- (void)addOperationWithBlock:(void(^)(void))block {
    dispatch_async(self.operationQueue, ^{
        if ( block ) block();
    });
}

@end


// MARK: Create


@implementation SJDatabaseMap (CreateTab)

/*!
 *  根据类创建一个表
 */
- (void)createTabWithClass:(Class)cls callBlock:(void(^)(BOOL result))block {
    [self addOperationWithBlock:^{
        BOOL result = [self createTabWithClass:cls];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(result);
        });
    }];
}

@end


// MARK: InsertOrUpdate


@implementation SJDatabaseMap (InsertOrUpdate)

/*!
 *  插入数据或更新数据
 *  如果没有表, 会自动创建表
 */
- (void)insertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)model callBlock:(void(^)(BOOL result))block {
    if ( nil == model ) { if ( block ) block(NO); return;}
    [self insertOrUpdateDataWithModels:@[model] callBlock:block];
}

/*!
 *  批量插入或更新
 *  如果没有表, 会自动创建表
 */
- (void)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^)(BOOL result))block {
    if ( 0 == models.count ) { if ( block ) block(NO); return;}
    [self addOperationWithBlock:^{
        BOOL result = [self insertOrUpdateDataWithModels:models];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(result);
        });
    }];
}

/*!
 *  更新指定的属性
 *  如果数据库没有这条数据, 将不会保存
 */
- (void)update:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields callBlock:(void (^ __nullable)(BOOL result))block {
    if ( 0 == fields.count || nil == model ) { if ( block ) block(NO); return;}
    [self addOperationWithBlock:^{
        BOOL result = [self update:model property:fields];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(result);
        });
    }];
}

/*!
 *  提供更详细的信息去更新, 这将提高更新速度
 *  如果数据库没有这个模型, 将不会保存
 *
 *  insertedOrUpdatedValues : key 更新的这个模型对应的属性. value 属性 更新/新增 的模型, 可以是数组, 也可以是单个模型
 */
- (void)update:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> * __nullable)insertedOrUpdatedValues callBlock:(void (^)(BOOL))block {
    if ( 0 == insertedOrUpdatedValues.allKeys ) { if ( block ) block(NO); return; }
    [self addOperationWithBlock:^{
        BOOL result = [self update:model insertedOrUpdatedValues:insertedOrUpdatedValues];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(result);
        });
    }];
}

/*!
 *  此接口针对数组字段使用.
 *  如果数据库没有这个模型, 将不会保存
 *
 */
- (void)updateTheDeletedValuesInTheModel:(id<SJDBMapUseProtocol>)model callBlock:(void (^)(BOOL))block {
    [self addOperationWithBlock:^{
        BOOL result = [self updateTheDeletedValuesInTheModel:model];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(result);
        });
    }];
}

@end


// MARK: Delete


@implementation SJDatabaseMap (Delete)

/*!
 *  删
 *  cls : 对应的类
 *  primaryKey : 主键. 包括自增键.
 */
- (void)deleteDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue callBlock:(void(^)(BOOL result))block {
    if ( nil == cls ) { if ( block ) block(NO); return;}
    [self addOperationWithBlock:^{
        BOOL result = [self deleteDataWithClass:cls primaryValue:primaryValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(result);
        });
    }];
}

/*!
 *  删
 *  primaryValues -> primaryValues
 */
- (void)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues callBlock:(void (^)(BOOL))block {
    if ( nil == cls || 0 == primaryValues.count ) { if ( block ) block(NO); return;}
    [self addOperationWithBlock:^{
        BOOL r = [self deleteDataWithClass:cls primaryValues:primaryValues];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(r);
        });
    }];
}

/*!
 *  删
 */
- (void)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^)(BOOL))block {
    if ( 0 == models.count ) { if ( block ) block(NO); return;}
    [self addOperationWithBlock:^{
        BOOL r = [self deleteDataWithModels:models];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(r);
        });
    }];
}

/*!
 *  删除所有数据
 */
- (void)deleteDataWithClass:(Class)cls callBlock:(void (^)(BOOL))block {
    [self addOperationWithBlock:^{
        BOOL result = [self deleteDataWithClass:cls];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(result);
        });

    }];
}

@end


// MARK: Query

@implementation SJDatabaseMap (Query)

/*!
 *  查
 *  返回和这个类有关的所有数据
 */
- (void)queryAllDataWithClass:(Class)cls completeCallBlock:(void(^)(NSArray<id<SJDBMapUseProtocol>> *data))block {
    if ( nil == cls ) { if ( block ) block(nil); return;}
    [self addOperationWithBlock:^{
        NSArray *models = [self queryAllDataWithClass:cls];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(models);
        });
    }];
}

/*!
 *  查
 */
- (void)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue completeCallBlock:(void (^)(id<SJDBMapUseProtocol> model))block {
    if ( nil == cls ) { if ( block ) block(nil); return;}
    [self addOperationWithBlock:^{
        id model = [self queryDataWithClass:cls primaryValue:primaryValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(model);
        });
        
    }];
}

/*!
 *  查
 */
- (id<SJDBMapUseProtocol>)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue {
    return [self sjQueryDataWithClass:cls primaryValue:primaryValue];;
}
/*!
 *  查
 *  queryDict ->  key : property
 */
- (void)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> *data))block {
    if ( nil == cls || 0 == dict.allKeys ) { if ( block ) block(nil); return;}
    [self addOperationWithBlock:^{
        NSArray *models = [self queryDataWithClass:cls queryDict:dict];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(models);
        });
    }];
}

/*!
 *  查询指定区间数据
 */
- (void)queryDataWithClass:(Class)cls range:(NSRange)range completeCallBlock:(void(^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    if ( nil == cls ) { if ( block ) block(nil); return;}
    [self addOperationWithBlock:^{
        NSArray *models = [self queryDataWithClass:cls range:range];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(models);
        });

    }];
}

/*!
 *  模糊查询
 */
- (void)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    if ( nil == cls || 0 == dict.allKeys ) { if ( block ) block(nil); return;}
    [self fuzzyQueryDataWithClass:cls queryDict:dict match:SJDatabaseMapFuzzyMatchAll completeCallBlock:block];
}

/*!
 *  模糊查询
 */
- (void)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict match:(SJDatabaseMapFuzzyMatch)match completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    [self addOperationWithBlock:^{
        if ( nil == cls || 0 == dict.allKeys ) { if ( block ) block(nil); return;}
        NSArray *models = [self fuzzyQueryDataWithClass:cls queryDict:dict match:match];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(models);
        });
    }];
}

@end
