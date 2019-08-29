//
//  SJViewController.m
//  SJSQLite3
//
//  Created by changsanjiang@gmail.com on 07/30/2019.
//  Copyright (c) 2019 changsanjiang@gmail.com. All rights reserved.
//

#import "SJViewController.h"
#import <SJSQLite3.h>
#import <YYModel/YYModel.h>
#import <SJSQLite3/SJSQLite3+SJSQLite3Extended.h>

@interface TestObj : NSObject<SJSQLiteTableModelProtocol>
@property (nonatomic) NSInteger id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *unique;
@property (nonatomic, copy) NSString *title;
@end

@implementation TestObj
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

@interface User : NSObject
@property (nonatomic) NSInteger id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<TestObj *> *arr;
@property (nonatomic, strong) NSString *dss;
@end

@implementation User
+ (nullable NSString *)sql_primaryKey {
    return @"id";
}
+ (NSArray<NSString *> *)sql_autoincrementlist {
    return @[@"id"];
}
+ (NSDictionary<NSString *,Class<SJSQLiteTableModelProtocol>> *)sql_arrayPropertyGenericClass {
    return @{@"arr":TestObj.class};
}
@end


@interface Account : NSObject
@property (nonatomic) NSInteger id;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSString *black;
@property (nonatomic, strong) NSString *dfds;

@property (nonatomic, strong, readonly) NSString *readonly;
@end

@implementation Account
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

@interface SJViewController ()
@property (nonatomic, strong) SJSQLite3 *sqlite3;
@end

@implementation SJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"%@", NSTemporaryDirectory());
    
    _sqlite3 = [[SJSQLite3 alloc] initWithDatabasePath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test.db"]];
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)test:(id)sender {
    for ( int i = 0 ; i < 100 ; ++ i ) {

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            Account *account = Account.new;
            account.user = [User new];
            account.user.name = @"user";
            account.user.arr = @[TestObj.new, TestObj.new, TestObj.new, TestObj.new, TestObj.new];
            account.black = @"black";
            account.dfds = @"123123";
            [self.sqlite3 save:account error:NULL];
            
            NSLog(@"%ld", account.user.id);
        });

    }
}

- (IBAction)delete:(id)sender {
    [self.sqlite3 removeObjectForClass:TestObj.class primaryKeyValue:@(1) error:NULL];
}

- (IBAction)get:(id)sender {
    NSError *error = nil;
    Account *account = [self.sqlite3 objectForClass:Account.class primaryKeyValue:@(1) error:NULL];
    NSLog(@"%@ - error: %@", account, error);
}

- (IBAction)update:(id)sender {
    Account *account = [self.sqlite3 objectForClass:Account.class primaryKeyValue:@(1) error:NULL];
    account.dfds = nil;
    [self.sqlite3 update:account forKey:@"dfds" error:NULL];
}

- (IBAction)query:(id)sender {
    NSError *error = nil;
    NSLog(@"%@ - %@", [self.sqlite3 queryDataForClass:Account.class resultColumns:@[@"user"] conditions:@[[SJSQLite3Condition conditionWithColumn:@"user" in:@[@(64), @(2)]]] orderBy:nil error:&error], error);
}

@end
