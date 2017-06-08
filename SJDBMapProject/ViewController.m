//
//  ViewController.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/6.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "ViewController.h"
#import "SJDBMap.h"
#import "Person.h"
#import "PersonTag.h"
#import "Book.h"
#import "Goods.h"

@interface ViewController (InsertOrUpdate)

- (void)insertOrUpdate;

@end

@interface ViewController (Delete)

- (void)del;

- (void)delWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues;

- (void)delWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models;

@end

@interface ViewController (Query)

- (void)query;

- (void)queryWithDict:(NSDictionary *)dict;

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"\n%@", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject);
    
    Goods *g = [Goods new];
    g.name = @"哈哈";
    
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModel:g callBlock:^(BOOL result) {
        
    }];
    
    Goods *g2 = [Goods new];
    g2.name = @"哈哈";

    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModel:g2 callBlock:^(BOOL result) {
        
    }];
    
    [self insertOrUpdate];

    // Do any additional setup after loading the view, typically from a nib.
}

@end


@implementation ViewController (InsertOrUpdate)



- (void)insertOrUpdate {
    
    Person *sj = [Person new];
    sj.personID = 0;
    sj.name = @"sj";
    sj.tags = @[[PersonTag tagWithID:0 des:@"A"],
                [PersonTag tagWithID:1 des:@"B"],
                [PersonTag tagWithID:2 des:@"C"],
                [PersonTag tagWithID:3 des:@"D"],
                [PersonTag tagWithID:4 des:@"E"],];
    
    sj.aBook = [Book bookWithID:123 name:@"How Are You?"];
    
    
    Person *sj2 = [Person new];
    sj2.personID = 2;
    sj2.name = @"sj";
    sj2.tags = @[[PersonTag tagWithID:0 des:@"A"],
                 [PersonTag tagWithID:1 des:@"B"],
                 [PersonTag tagWithID:2 des:@"C"],
                 [PersonTag tagWithID:3 des:@"D"],
                 [PersonTag tagWithID:4 des:@"E"],];
    
    sj2.aBook = [Book bookWithID:123 name:@"How Are You?"];
    
    
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModels:@[sj, sj2] callBlock:^(BOOL r) {
        
    }];
}

@end

@implementation ViewController (Delete)

- (void)del {
    [[SJDatabaseMap sharedServer] deleteDataWithClass:[Person class] primaryValue:0 callBlock:^(BOOL result) {
        // ...
    }];
}

- (void)delWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues {
    [[SJDatabaseMap sharedServer] deleteDataWithClass:[Person class] primaryValues:primaryValues callBlock:^(BOOL r) {
        
    }];
}

- (void)delWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models {
    [[SJDatabaseMap sharedServer] deleteDataWithModels:models callBlock:^(BOOL result) {
       
    }];
}

@end


@implementation ViewController (Query)


- (void)query {
    [[SJDatabaseMap sharedServer] queryAllDataWithClass:[Person class] completeCallBlock:^(NSArray<id> * _Nonnull data) {
        // ...
    }];
}

- (void)queryWithDict:(NSDictionary *)dict {
    [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] queryDict:dict completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
        [data enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"%@", obj);
        }];
    }];
}

@end
