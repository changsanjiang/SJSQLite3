//
//  SJDatabaseFunctions.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN
@class SJDatabaseMapTableCarrier, SJDatabaseMapCache;

#pragma mark database
extern bool sj_database_open(const char *dbPath, sqlite3 **database); // 打开数据库
extern bool sj_database_close(sqlite3 **database); // 关闭数据库

#pragma mark transaction
extern void sj_transaction(sqlite3 *database, void(^sync_task)(void));
extern void sj_transaction_begin(sqlite3 *database);  // 开启事物
extern void sj_transaction_commit(sqlite3 *database); // 提交事物

#pragma mark sql
extern bool sj_sql_exe(sqlite3 *database, const char *sql); // 执行一条sql语句
extern NSArray<id> *__nullable sj_sql_query(sqlite3 *database, const char *sql, Class __nullable cls); // 执行查询语句, cls为表对应的类, 如果为空, 将返回字典数组

#pragma mark table
extern const char *sj_table_name(Class cls); // 通过类获取表名, 该表可能不存在
extern bool sj_table_create(sqlite3 *database, SJDatabaseMapTableCarrier *carrier); // 只`创建`当前类的表
extern bool sj_table_update(sqlite3 *database, SJDatabaseMapTableCarrier *carrier); // 只`更新`当前类的表, 只添加新增字段
extern bool sj_table_exists(sqlite3 *database, const char *table_name); // 查询表是否存在
extern NSArray<NSString *> *__nullable sj_table_fields(sqlite3 *database, const char *table_name); // 获取表的所有字段
extern bool sj_table_checkout_field(sqlite3 *database, const char *table_name, const char *field, const char *type); // 检出一个字段
extern bool sj_table_add_field(sqlite3 *database, const char *table_name, const char *field, const char *type); // 添加一个字段
extern bool sj_table_delete(sqlite3 *database, const char *table_name); // 删除表 

#pragma mark value
/// 根据模型插入数据库, 自动建表
/// 可能插入多条数据, 因为模型存在套其他模型的情况
/// carrier 可以为空
extern bool sj_value_insert_or_update(sqlite3 *database, id<SJDBMapUseProtocol> model, NSArray<__kindof SJDatabaseMapTableCarrier *> * __nullable container, SJDatabaseMapCache *__nullable cache);
extern long long sj_value_last_id(sqlite3 *database, Class<SJDBMapUseProtocol> cls, SJDatabaseMapTableCarrier *__nullable carrier); // 查询最后一条数据的id, 如果返回-1, 表示该类没有数据, 或未创建
extern bool sj_value_update(sqlite3 *database, id<SJDBMapUseProtocol> model, NSArray<NSString *> *properties, NSArray<__kindof SJDatabaseMapTableCarrier *> * __nullable container, SJDatabaseMapCache *__nullable cache);
extern bool sj_value_exists(sqlite3 *database, id<SJDBMapUseProtocol> model, SJDatabaseMapTableCarrier *__nullable carrier);
extern bool sj_value_delete(sqlite3 *database, const char *table_name, const char *fields, NSArray *values);
extern NSArray<id<SJDBMapUseProtocol>> *sj_value_query(sqlite3 *database, const char *sql, Class<SJDBMapUseProtocol> cls, NSArray<__kindof SJDatabaseMapTableCarrier *> * __nullable container, SJDatabaseMapCache *__nullable cache);
extern id sj_value_filter(id value);

#pragma mark fields
extern char *__nullable sj_fields_sql_type(Class cls, const char *ivar); // 通过实例变量名获取数据库中对应的存储类型

#pragma mark folder or file
extern NSString *__nullable sj_checkoutFolder(NSString *path); // 如果返回nil, 则表示检出失败, 否则返回path.

#pragma mark runtime
extern NSArray<NSString *> *sj_ivar_list(Class cls); // 获取实例变量列表
extern Class __nullable sj_ivar_class(Class cls, const char *ivar); // 如果ivar属于一个对象类型, 则返回它的类型, 否则返回 NULL



#pragma mark -
@class SJDatabaseMapTableCorrespondingCarrier;
@interface SJDatabaseMapTableCarrier : NSObject
- (instancetype)initWithClass:(Class<SJDBMapUseProtocol>)cls;
- (void)parseCorrespondingKeysAddToContainer:(NSMutableArray<__kindof SJDatabaseMapTableCarrier *> *)container;

- (NSString *)primaryKeyOrAutoincrementPrimaryKey;
- (BOOL)isArrCorrespondingKeyWithIvar:(const char *)instance_ivar;
- (BOOL)isCorrespondingKeyWithIvar:(const char *)instance_ivar key:(NSString * __autoreleasing *)key;
- (const char *)isCorrespondingKeyWithCorresponding:(const char *)corresponding;  // return ivar

@property (nonatomic, readonly) BOOL isUsingPrimaryKey;
@property (nonatomic, readonly) Class<SJDBMapUseProtocol> cls;
@property (nonatomic, strong, readonly, nullable) NSString *primaryKey;
@property (nonatomic, strong, readonly, nullable) NSString *autoincrementPrimaryKey;
@property (nonatomic, strong, readonly, nullable) NSArray<SJDatabaseMapTableCorrespondingCarrier *> *correspondingKeys_arr;
@property (nonatomic, strong, readonly, nullable) NSArray<SJDatabaseMapTableCorrespondingCarrier *> *arrayCorrespondingKeys_arr;
@end


@interface SJDatabaseMapTableCorrespondingCarrier : SJDatabaseMapTableCarrier
- (instancetype)initWithClass:(Class<SJDBMapUseProtocol>)cls property:(NSString *)property;
@property (nonatomic, strong) NSString *property; // 上级类中的属性字段
@end

#pragma mark -
@interface SJDatabaseMapCache : NSObject
- (void)addObject:(id<SJDBMapUseProtocol>)object; // 添加时,并不检测是否已包含该object
- (BOOL)containsObject:(id<SJDBMapUseProtocol>)anObject;
- (nullable id<SJDBMapUseProtocol>)containsObjectWithClass:(Class<SJDBMapUseProtocol>)cls primaryValue:(NSInteger)primaryValue;
@end
NS_ASSUME_NONNULL_END
