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
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSLog(@"\n%@", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject);
    
    
#warning - if it can't run. please perform " pod update --no-repo-update " to update the project. The update may be a bit slow.
    
    // sample 1
    [self insertOrUpdate];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sample" style:UIBarButtonItemStyleDone target:self action:@selector(clickedItem:)];
    
    // Do any additional setup after loading the view, typically from a nib.
}

// sample 2
- (void)clickedItem:(UIBarButtonItem *)item {
    [self.navigationController pushViewController:[NSClassFromString(@"SampleTableViewController") new] animated:YES];
}

@end


@implementation ViewController (InsertOrUpdate)

- (void)insertOrUpdate {
    Goods *g = [Goods new];
    g.name = @"G1";
    g.price = [[Price alloc] initWithPriceId:1 price:20];
    
    Goods *g2 = [Goods new];
    g2.name = @"G2";
    g2.price = [[Price alloc] initWithPriceId:2 price:33];

    Goods *g3 = [Goods new];
    g3.name = @"G3";
    g3.price = [[Price alloc] initWithPriceId:3 price:223];

    Goods *g4 = [Goods new];
    g4.name = @"G4";
    g4.price = [[Price alloc] initWithPriceId:4 price:3232];

    
    NSArray<Goods *> *goods = @[g, g2, g3, g4];
    
    NSArray *tags = @[
                     [PersonTag tagWithID:0 des:@"A"],
                     [PersonTag tagWithID:1 des:@"B"],
                     [PersonTag tagWithID:2 des:@"C"],
                     [PersonTag tagWithID:3 des:@"'D'"],
                     [PersonTag tagWithID:4 des:@"E"],];
    
    NSMutableArray <Person *> *arrM = [NSMutableArray new];
    for ( int i = 0 ; i < 3 ; i ++ ) {
        Person *sj = [Person new];
        sj.personID = i;
        sj.name = @"sj";
        sj.tags = tags;
        
        sj.aBook = [Book bookWithID:123 name:@"How Are You?"];
        sj.age = 20;
        
        sj.goods = goods;
        [arrM addObject:sj];
    
    }

    
    // insert or update  sample
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModels:arrM callBlock:^(BOOL r) {
        
        // update sample
        [self update];
        
    }];
}

- (void)update {

    [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] primaryValue:2 completeCallBlock:^(id<SJDBMapUseProtocol>  _Nullable model) {
        if ( nil == model ) return ;
        
        NSLog(@"query single person");
        
        Person *person = model;
        
        NSMutableArray *tagsM = [NSMutableArray new];
        [tagsM addObject:[PersonTag tagWithID:7 des:@"从前有一座links"]];
        [tagsM addObject:[PersonTag tagWithID:8 des:@"links"]];
        
        // insert two data
        person.tags = [person.tags arrayByAddingObjectsFromArray:tagsM];
        
        // update tags first object
        person.tags.firstObject.des = @"UUUUUuuuUUUuUUUUUUuUu";
        
        // update goods first object
        person.goods.firstObject.name = @"OOOOOOOOOOOOOOOOOOOOO";
        
        
        // mixed
        [tagsM addObject:person.tags.firstObject];
        [[SJDatabaseMap sharedServer] update:person insertedOrUpdatedValues:@{@"tags":tagsM, @"goods":person.goods.firstObject} callBlock:^(BOOL r) {
            NSLog(@"update end");
            
            // query sample
            [self queryWithDict:@{@"personID":@"33"}];
            
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
    [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] queryDict:@{@"name":@"sj", @"age":@(20)} completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
        
        NSLog(@"%zd", data.count);
        
        // range query
        [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] range:NSMakeRange(2, 10) completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
            NSLog(@"%zd", data.count);
            
            
            // fuzzy query
            [[SJDatabaseMap sharedServer] fuzzyQueryDataWithClass:[Person class] queryDict:@{@"name":@"s"} completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
                NSLog(@"%zd", data.count);
                
                // 匹配以 's' 开头的name.
                [[SJDatabaseMap sharedServer] fuzzyQueryDataWithClass:[Person class] queryDict:@{@"name":@"s"} match:SJDatabaseMapFuzzyMatchFront completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
                    NSLog(@"%zd", data.count);
                }];
                
            }];
    
        }];
        
    }];
}

@end
