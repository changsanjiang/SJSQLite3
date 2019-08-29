//
//  SJSQLite3Tests.m
//  SJSQLite3Tests
//
//  Created by changsanjiang@gmail.com on 07/30/2019.
//  Copyright (c) 2019 changsanjiang@gmail.com. All rights reserved.
//

@import XCTest;
#import <SJSQLite3.h>

#import <SJSQLite3.h>
#import <YYModel.h>
#import <SJSQLite3/SJSQLite3+SJSQLite3Extended.h>

@interface _TestObj : NSObject<SJSQLiteTableModelProtocol>
@property (nonatomic) NSInteger id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *unique;
@property (nonatomic, copy) NSString *title;
@end

@implementation _TestObj
- (instancetype)init {
    self = [super init];
    if ( !self ) return nil;
    static int idx;
    _name = [NSString stringWithFormat:@"%d", ++ idx];
    _unique = @"unique";
    _title = @"A'a'b\\c\"A";
    return self;
}

+ (nullable NSString *)sql_primaryKey {
    return @"id";
}
+ (NSArray<NSString *> *)sql_autoincrementlist {
    return @[@"id"];
}
@end

@interface _User : NSObject<SJSQLiteTableModelProtocol>
@property (nonatomic) NSInteger id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<_TestObj *> *arr;
@property (nonatomic, strong) NSString *dss;
@end

@implementation _User
+ (nullable NSString *)sql_primaryKey {
    return @"id";
}
+ (NSArray<NSString *> *)sql_autoincrementlist {
    return @[@"id"];
}
+ (NSDictionary<NSString *,Class<SJSQLiteTableModelProtocol>> *)sql_arrayPropertyGenericClass {
    return @{@"arr":_TestObj.class};
}
@end


@interface _Account : NSObject<SJSQLiteTableModelProtocol>
@property (nonatomic) NSInteger id;
@property (nonatomic, strong) _User *user;
@property (nonatomic, strong) NSString *black;
@property (nonatomic, strong) NSString *dfds;

@property (nonatomic, strong, readonly) NSString *readonly;
@end

@implementation _Account
- (NSString *)description {
    return [self yy_modelDescription];
}

+ (nullable NSString *)sql_primaryKey {
    return @"id";
}

+ (nullable NSArray<NSString *> *)sql_autoincrementlist {
    return @[@"id"];
}

+ (nullable NSDictionary<NSString *, NSString *> *)sql_customKeyMapper {
    return @{@"users":@"sj_users"};
}

+ (nullable NSArray<NSString *> *)sql_whitelist {
    return nil;
}

+ (nullable NSArray<NSString *> *)sql_blacklist {
    return @[@"black"];
}

+ (nullable NSArray<NSString *> *)sql_notnulllist {
    return @[@"user"];
}
@end

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)testSave {
    
    XCTestExpectation *documentOpenExpectation = [self expectationWithDescription:@"document open"];

    
    SJSQLite3 *sqlite3 = [[SJSQLite3 alloc] initWithDatabasePath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test.db"]];
    
    for ( int i = 0 ; i < 100 ; ++ i ) {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            _Account *account = _Account.new;
            account.user = [_User new];
            account.user.name = @"user";
            account.user.arr = @[_TestObj.new, _TestObj.new, _TestObj.new, _TestObj.new, _TestObj.new];
            account.black = @"black";
            account.dfds = @"123123";
            [sqlite3 saveObjects:@[account] error:NULL];
        });
        
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [documentOpenExpectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
#ifdef DEBUG
        NSLog(@"error: %@", error);
#endif
    }];
}


- (void)testExtended {
    SJSQLite3 *sqlite3 = [[SJSQLite3 alloc] initWithDatabasePath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test.db"]];

//    SELECT * FROM '_Account' WHERE "t1" IN ('10','11','12') AND "t2" = '2' AND "t3" IN ('1','3') AND t4 IS NULL ORDER BY "t1" ASC,"t2" DESC,"t3" ASC LIMIT 0, 20;
    [sqlite3 objectsForClass:_Account.class
                  conditions:@[[SJSQLite3Condition conditionWithColumn:@"t1" in:@[@(10), @(11), @(12)]],
                               [SJSQLite3Condition conditionWithColumn:@"t2" relatedBy:SJSQLite3RelationEqual value:@(2)],
                               [SJSQLite3Condition conditionWithColumn:@"t3" between:@(1) and:@(3)],
                               [SJSQLite3Condition conditionWithIsNullColumn:@"t4"]]
                     orderBy:@[[SJSQLite3ColumnOrder orderWithColumn:@"t1" ascending:YES],
                               [SJSQLite3ColumnOrder orderWithColumn:@"t2" ascending:NO],
                               [SJSQLite3ColumnOrder orderWithColumn:@"t3" ascending:YES]]
                       range:NSMakeRange(0, 20)
                       error:NULL];
}

- (void)testExtended1 {
    NSLog(@"%@", NSTemporaryDirectory());
    
    SJSQLite3 *sqlite3 = [[SJSQLite3 alloc] initWithDatabasePath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test.db"]];

    printf("%lu\n", [sqlite3 countOfObjectsForClass:_Account.class conditions:nil error:NULL]);
}

- (void)testExtended2 {
    SJSQLite3 *sqlite3 = [[SJSQLite3 alloc] initWithDatabasePath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test.db"]];
    
    printf("%lu\n", [sqlite3 countOfObjectsForClass:_Account.class conditions:@[[[SJSQLite3Condition alloc] initWithCondition:@"dfds LIKE '123%%'"]] error:NULL]);
}

@end

