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

- (void)update;

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
    
    
//    [self insertOrUpdate];
    
    [self update];
    
//    [[SJDatabaseMap sharedServer] fuzzyQueryDataWithClass:[Person class] queryDict:@{@"name":@"j"} match:SJDatabaseMapFuzzyMatchLater completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
//        [data enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            NSLog(@"%@", obj);
//        }];
//    }];
    
    // Do any additional setup after loading the view, typically from a nib.
}

@end


@implementation ViewController (InsertOrUpdate)

- (void)insertOrUpdate {
    Goods *g = [Goods new];
    g.name = @"G1";
    g.price = [[Price alloc] initWithPriceId:0 price:20];
    
    Goods *g2 = [Goods new];
    g2.name = @"G2";
    g2.price = [[Price alloc] initWithPriceId:1 price:33];
    
    NSArray *tags = @[
                     [PersonTag tagWithID:0 des:@"A"],
                     [PersonTag tagWithID:1 des:@"B"],
                     [PersonTag tagWithID:2 des:@"C"],
                     [PersonTag tagWithID:3 des:@"'D'"],
                     [PersonTag tagWithID:4 des:@"E"],];
    
    NSMutableArray <Person *> *arrM = [NSMutableArray new];
    for ( int i = 0 ; i < 4000 ; i ++ ) {
        Person *sj = [Person new];
        sj.personID = i;
        sj.name = @"sj";
        sj.tags = tags;
        
        sj.aBook = [Book bookWithID:123 name:@"How Are You?"];
        sj.age = 20;
        
        sj.goods = @[g, g2];
        [arrM addObject:sj];
    }
    
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModels:arrM callBlock:^(BOOL r) {
        
    }];
}

- (void)update {
    
    [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] primaryValue:2 completeCallBlock:^(id<SJDBMapUseProtocol>  _Nullable model) {
        if ( nil == model ) return ;
        Person *person = model;
        person.name = @"xiaoHHHHHHH";
        person.age = 9999999;
        person.test = @"ttetetetetetetetet't'eteettet";
        [[SJDatabaseMap sharedServer] updateProperty:@[@"name", @"age", @"test"] target:person callBlock:^(BOOL result) {
            NSLog(@"end");
        }];
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
        [data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"%@", obj);
        }];
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
