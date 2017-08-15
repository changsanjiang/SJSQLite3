//
//  SJDatabaseMap.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@protocol SJDBMapUseProtocol;

NS_ASSUME_NONNULL_BEGIN

/**
 *  父类字段未做处理.
 */
@interface SJDatabaseMap : NSObject

@property (nonatomic, assign, readonly) sqlite3 *sqDB;

/*!
 *  数据库路径
 */
@property (nonatomic, strong, readonly) NSString   *dbPath;

/*!
 *  使用此方法, 数据库将使用默认路径创建
 */
+ (instancetype)sharedServer;

/*!
 *  自定义数据库路径
 */
- (instancetype)initWithPath:(NSString *)path;

@end



// MARK: Create

@interface SJDatabaseMap (CreateTab)

/*!
 *  根据类创建一个表
 */
- (void)createTabWithClass:(Class)cls callBlock:(void(^ __nullable)(BOOL result))block;

@end



// MARK: InsertOrUpdate

@interface SJDatabaseMap (InsertOrUpdate)

/*!
 *  插入数据或更新数据
 *  如果没有表, 会自动创建表
 *
 *  如果是模型具有自增主键, 将会随机插入.
 */
- (void)insertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)model callBlock:(void(^ __nullable)(BOOL result))block;

/*!
 *  批量插入或更新
 *  如果没有表, 会自动创建表
 *  数组中的模型, 可以不同
 *  如果是模型具有自增主键, 将会随机插入.
 */
- (void)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^ __nullable)(BOOL result))block;

/*!
 *  更新指定的属性
 *  如果数据库没有这个模型, 将不会保存
 */
- (void)update:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields callBlock:(void (^ __nullable)(BOOL result))block;

/*!
 *  提供更详细的信息去更新, 这将提高更新速度
 *  如果数据库没有这个模型, 将不会保存
 *
 *  insertedOrUpdatedValues : key 更新的这个模型对应的属性. value 属性 更新/新增 的模型, 可以是数组, 也可以是单个模型
 */
- (void)update:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> * __nullable)insertedOrUpdatedValues callBlock:(void (^)(BOOL))block;

/*!
 *  此接口针对数组字段使用.
 *  如果数据库没有这个模型, 将不会保存
 *
 *  deletedValues : key 更新的这个模型对应的属性(字段为数组). value 数组中删除掉的模型.
 */
- (void)updateTheDeletedValuesInTheModel:(id<SJDBMapUseProtocol>)model callBlock:(void (^)(BOOL))block;

@end



// MARK: Delete

@interface SJDatabaseMap (Delete)

/*!
 *  删
 *  cls : 对应的类
 *  primaryValue : 主键或自增键值.
 */
- (void)deleteDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue callBlock:(void(^ __nullable)(BOOL result))block;

/*!
 *  删
 *  primaryValues -> primaryValues
 */
- (void)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues callBlock:(void (^ __nullable)(BOOL result))block;

/*!
 *  删
 */
- (void)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^ __nullable)(BOOL result))block;

@end



// MARK: Query


@interface SJDatabaseMap (Query)

/*!
 *  查
 *  返回和这个类有关的所有数据
 */
- (void)queryAllDataWithClass:(Class)cls completeCallBlock:(void(^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

/*!
 *  查
 */
- (void)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue completeCallBlock:(void (^ __nullable)(id<SJDBMapUseProtocol> _Nullable model))block;

/*!
 *  查
 *  queryDict ->  key : property
 */
- (void)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;


/*!
 *  模糊查询
 *  default SJDatabaseMapFuzzyMatchAll
 */
- (void)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;


typedef NS_ENUM(NSUInteger, SJDatabaseMapFuzzyMatch) {
    /*!
     *  匹配左右两边
     *  ...A...
     */
    SJDatabaseMapFuzzyMatchAll = 0,
    /*!
     *  匹配以什么开头
     *  ABC.....
     */
    SJDatabaseMapFuzzyMatchFront,
    /*!
     *  匹配以什么结尾
     *  ...DEF
     */
    SJDatabaseMapFuzzyMatchLater,
};

/*!
 *  模糊查询
 */
- (void)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict match:(SJDatabaseMapFuzzyMatch)match completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

@end


NS_ASSUME_NONNULL_END
