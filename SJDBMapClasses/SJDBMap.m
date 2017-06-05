//
//  SJDBMap.m
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//
#import "SJDBMapHeader.h"
#import <objc/message.h>
#import <FMDB.h>

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


@interface SJDBMap ()

/*!
 *  数据库对象
 */
@property (nonatomic, strong, readwrite) FMDatabase *database;

/*!
 *  数据库路径
 */
@property (nonatomic, strong, readwrite) NSString   *dbPath;

/*!
 *  操作队列, 子线程操作
 */
@property (nonatomic, weak, readonly) NSOperationQueue *operationQueue;

@end

@implementation SJDBMap

/*!
 *  使用此方法, 数据库将使用默认路径创建
 */
+ (instancetype)sharedServer {
    static id _instance;
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
    self.database = [FMDatabase databaseWithPath:path];
    if ( ![_database open] ) NSLog(@"初始化数据库失败, 请检查路径");
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

/*!
 *  开启事物
 */
- (BOOL)sjTransactionWithExeSQL:(NSString *)sql {
    [self.database beginTransaction];
    [self.database executeUpdate:sql];
    if ( [self.database commit] )  return YES;
    else [self.database rollback]; return NO;
}

/*!
 *  根据类创建一个表
 */
- (void)createTabWithClass:(Class)cls callBlock:(void(^)(BOOL result))block {
    [self.operationQueue addOperationWithBlock:^{
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

/*!
 *  增数据或更新数据
 *  如果没有表, 会自动创建表
 */
- (void)insertOrUpdateDataWithModel:(id)model callBlock:(void(^)(BOOL result))block {
    [self.operationQueue addOperationWithBlock:^{
        [self sjAutoCreateOrAlterRelevanceTabWithClass:[model class]];
        __block BOOL result = YES;
        [[self sjGetRelevanceObjs:model] enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
            SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:[obj class]];
            NSString *prefixSQL  = [self sjGetInsertOrUpdatePrefixSQL:uM];
            NSString *subffixSQL = [self sjGetInsertOrUpdateSuffixSQL:obj];
            NSString *sql = [NSString stringWithFormat:@"%@ %@;", prefixSQL, subffixSQL];
            if ( ![self sjTransactionWithExeSQL:sql] ) result = NO;
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block( result );
        });
    }];
}

/*!
 *  删
 *  cls : 对应的类
 *  primaryKey : 主键. 包括自增键.
 */
- (void)deleteDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue callBlock:(void(^)(BOOL result))block {
    [self.operationQueue addOperationWithBlock:^{
        SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
        NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
        NSString *sql = [self sjGetDeleteSQL:cls uM:uM deletePrimary:primaryValue];
        BOOL result = [self sjTransactionWithExeSQL:sql];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(result);
        });
    }];
}

/*!
 *  查
 *  返回和这个类有关的所有数据
 */
- (void)queryAllDataWithClass:(Class)cls completeCallBlock:(void(^)(NSArray<id> *data))block {
    [self.operationQueue addOperationWithBlock:^{
        NSArray *models = [self sjQueryConversionMolding:cls];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(models);
        });
    }];
}

/*!
 *  查一条数据
 */
- (void)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue completeCallBlock:(void (^)(id model))block {
    [self.operationQueue addOperationWithBlock:^{
        id model = [self sjQueryConversionMolding:cls primaryValue:primaryValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( block ) block(model);
        });

    }];
}

/*!
 *  自定义查询
 *  queryDict ->  key : property
 */
- (void)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^)(NSArray<id> *data))block {
    [self.operationQueue addOperationWithBlock:^{
        NSArray *models = [self sjQueryConversionMolding:cls dict:dict];
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
