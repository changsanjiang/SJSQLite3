//
//  SJDatabaseMap.m
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//
#import "SJDBMap.h"
#import <objc/message.h>

// MARK: C

/**
 *  数据文件夹
 */
static NSString *_sjDatabaseDefaultFolder();

/*!
 *  操作队列。 只使用了一条子线程.
 */
static NSOperationQueue *_operationQueue;


// MARK: Root

@interface SJDatabaseMap ()

/*!
 *  数据库路径
 */
@property (nonatomic, strong, readwrite) NSString   *dbPath;

/*!
 *  操作队列, 子线程操作
 */
@property (nonatomic, weak, readonly) NSOperationQueue *operationQueue;

@end


@implementation SJDatabaseMap {
    sqlite3 *_sqDb;
}

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

// MARK: 操作队列

- (NSOperationQueue *)operationQueue {
    if ( _operationQueue ) return _operationQueue;
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 1;
    _operationQueue.name = @"com.sjdb.operationQueue";
    //    _operationQueue.qualityOfService = NSQualityOfServiceUtility;
    return _operationQueue;
}

- (void)dealloc {
    [_operationQueue cancelAllOperations];
    _operationQueue = nil;
}

- (sqlite3 *)sqDB {
    return _sqDb;
}

@end


// MARK: Create


@implementation SJDatabaseMap (CreateTab)

/*!
 *  根据类创建一个表
 */
- (void)createTabWithClass:(Class)cls callBlock:(void(^)(BOOL result))block {
    __weak typeof(self) _self = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
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
    __weak typeof(self) _self = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self sjAutoCreateOrAlterRelevanceTabWithClass:[model class]];
        BOOL result = [self sjInsertOrUpdateDataWithModel:model];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block( result );
        });
    }];
}

/*!
 *  批量插入或更新
 *  如果没有表, 会自动创建表
 */
- (void)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^)(BOOL result))block {
    __weak typeof(self) _self = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        
        /*!
         *  整理模型数组
         */
        NSDictionary<NSString *, NSArray<id> *> *modelsDict = [self sjPutInOrderModels:models];
        
        /*!
         *  自动创建表
         */
        [modelsDict.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self sjAutoCreateOrAlterRelevanceTabWithClass:NSClassFromString(obj)];
        }];
        
        /*!
         *  批量插入或更新数据
         */
        __block BOOL result = YES;
        [modelsDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tabName, NSArray<id> * _Nonnull modelsArr, BOOL * _Nonnull stop) {
            //            只做了第一层
            //            SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:NSClassFromString(tabName)];
            //            NSString *prefixSQL  = [self sjGetInsertOrUpdatePrefixSQL:uM];
            //            NSString *subffixSQLM = [self sjGetBatchInsertOrUpdateSubffixSQL:modelsArr];
            //            NSString *sql = [NSString stringWithFormat:@"%@ %@;", prefixSQL, subffixSQLM];
            //            NSLog(@"%@", sql);
            //            if ( !(SQLITE_OK == sqlite3_exec(self.sqDB, sql.UTF8String, NULL, NULL, NULL)) ) NSLog(@"[%@] 创建或更新失败.", sql), result = NO;
            /*!
             *  获取相关的数据模型
             */
            [modelsArr enumerateObjectsUsingBlock:^(id  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( ![self sjInsertOrUpdateDataWithModel:model] ) result = NO;
            }];
        }];
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
    __weak typeof(self) _self = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
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
    __weak typeof(self) _self = self;
    
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
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
    __weak typeof(self) _self = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
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
    __weak typeof(self) _self = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
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
    [self.operationQueue addOperationWithBlock:^{
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
    [self.operationQueue addOperationWithBlock:^{
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
    [self fuzzyQueryDataWithClass:cls queryDict:dict match:SJDatabaseMapFuzzyMatchAll completeCallBlock:block];
}

/*!
 *  模糊查询
 */
- (void)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict match:(SJDatabaseMapFuzzyMatch)match completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block {
    [self.operationQueue addOperationWithBlock:^{
        NSArray *models = [self sjFuzzyQueryConversionMolding:cls match:match dict:dict];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(models);
        });
    }];
}

@end














// MARK: C_Func

static NSString *_sjDatabaseDefaultFolder() {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.sj.databasesDefaultFolder"];
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] ) [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}
