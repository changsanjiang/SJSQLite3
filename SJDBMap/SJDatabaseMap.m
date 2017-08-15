//
//  SJDatabaseMap.m
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//
#import "SJDBMap.h"

#import <objc/message.h>

#import "SJDatabaseMap+Server.h"
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

- (void)addOperationWithBlock:(void(^)())block {
    __weak typeof(self) _self = self;
    dispatch_async(self.operationQueue, ^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
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
    if ( nil == cls ) { if ( block ) block(NO); return;}
    [self addOperationWithBlock:^{
        __block BOOL result = YES;
        [[self sjGetRelevanceClasses:cls] enumerateObjectsUsingBlock:^(Class  _Nonnull relevanceCls, BOOL * _Nonnull stop) {
            BOOL r = [self sjCreateOrAlterTabWithClass:relevanceCls];
            if ( !r ) NSLog(@"[%@] 创建或更新表失败.", relevanceCls), result = NO;
        }];
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
        /*!
         *  归类整理
         */
        NSDictionary<NSString *, NSArray<id> *> *modelsDict = [self sjPutInOrderModels:models];
        
        /*!
         *  自动创建表
         */
        [modelsDict.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self sjAutoCreateOrAlterRelevanceTabWithClass:NSClassFromString(obj)];
        }];
        
        /*!
         *  批量插入或更新
         */
        __block BOOL result = YES;
        [modelsDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tabName, NSArray<id> * _Nonnull modelsArr, BOOL * _Nonnull stop) {
            result = [self sjInsertOrUpdateDataWithModels:modelsArr enableTransaction:YES];
            if ( !result ) *stop = YES;
        }];
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
        [self queryDataWithClass:[model class] primaryValue:[[self sjGetPrimaryOrAutoPrimaryValue:model] integerValue] completeCallBlock:^(id<SJDBMapUseProtocol>  _Nullable m) {
            if ( nil == m ) { if ( block ) block(NO); return; }
            [self addOperationWithBlock:^{
                BOOL result = [self sjUpdate:model property:fields];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ( block ) block(result);
                });
            }];
        }];
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
        [self queryDataWithClass:[model class] primaryValue:[[self sjGetPrimaryOrAutoPrimaryValue:model] integerValue] completeCallBlock:^(id<SJDBMapUseProtocol>  _Nullable m) {
            if ( nil == m ) { if ( block ) block(NO); return ; }
            [self addOperationWithBlock:^{
               BOOL result = [self sjUpdate:model insertedOrUpdatedValues:insertedOrUpdatedValues];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ( block ) block(result);
                });
            }];
        }];
    }];
}

/*!
 *  此接口针对数组字段使用.
 *  如果数据库没有这个模型, 将不会保存
 *
 *  deletedValues : key 更新的这个模型对应的属性(字段为数组). value 数组中删除掉的模型.
 */
- (void)updateTheDeletedValuesInTheModel:(id<SJDBMapUseProtocol>)model callBlock:(void (^)(BOOL))block {
    [self addOperationWithBlock:^{
        [self queryDataWithClass:[model class] primaryValue:[[self sjGetPrimaryOrAutoPrimaryValue:model] integerValue] completeCallBlock:^(id<SJDBMapUseProtocol>  _Nullable m) {
            if ( nil == m ) { if ( block ) block(NO); return ; }
            [self addOperationWithBlock:^{
                BOOL result = [self sjInsertOrUpdateDataWithModel:model uM:[self sjGetUnderstandingWithClass:[model class]]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ( block ) block(result);
                });
            }];
        }];
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
        SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
        NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
        NSString *sql = [self sjGetDeleteSQL:cls uM:uM deletePrimary:primaryValue];
        __block BOOL result = YES;
        [self sjExeSQL:sql.UTF8String completeBlock:^(BOOL r) {
            if ( !r ) NSLog(@"[%@] 删除失败.", sql), result = NO;
        }];
        
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
        __block BOOL r = YES;
        NSString *sql = [self sjGetBatchDeleteSQL:cls primaryValues:primaryValues];
        [self sjExeSQL:sql.UTF8String completeBlock:^(BOOL result) {
            if ( !result ) NSLog(@"[%@] 删除失败.", sql), r = NO;
        }];
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
        __block BOOL r = YES;
        [[self sjPutInOrderModels:models] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull clsName, NSArray<id<SJDBMapUseProtocol>> * _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *sql = [self sjGetBatchDeleteSQL:NSClassFromString(clsName) primaryValues:[self sjGetPrimaryValues:obj]];
            [self sjExeSQL:sql.UTF8String completeBlock:^(BOOL result) {
                if ( !result ) NSLog(@"[%@] 删除失败.", sql), r = NO;
            }];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(r);
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
        NSArray *models = [self sjQueryConversionMolding:cls];
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
        id model = [self sjQueryConversionMolding:cls primaryValue:primaryValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(model);
        });
        
    }];
}

/*!
 *  查
 *  queryDict ->  key : property
 */
- (void)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> *data))block {
    if ( nil == cls || 0 == dict.allKeys ) { if ( block ) block(nil); return;}
    [self addOperationWithBlock:^{
        NSArray *models = [self sjQueryConversionMolding:cls dict:dict];
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
        NSArray *models = [self sjFuzzyQueryConversionMolding:cls match:match dict:dict];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(models);
        });
    }];
}

@end
