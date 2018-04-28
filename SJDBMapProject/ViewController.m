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



#import "SJDatabaseFunctions.h"
#import "TestTest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"\n%@", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject);

//    char *test = malloc(sizeof(char) * 100);
//    test[0] = '\0';
    
    Class person = [Person class];
    
    NSLog(@"%d", person == [Person class]);
    
    
//    sj_table_update([SJDatabaseMapV2 sharedServer].database, carrier);
    
//    const char *test2 = "H";
    
//    Protocol *pro = @protocol(SJDBMapUseProtocol);
//    Book *dd = [Book new];
//    NSLog(@"%d", [dd conformsToProtocol:pro]);
//    NSLog(@"%d", [cls conformsToProtocol:pro]);
//
//    printf("%s - %ld\n", strcat(test, test2), strlen(test));
    
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    
#warning - if it can't run. please perform " pod update " to update the project. The update may be a bit slow.
    
    // sample 1
    [self insertOrUpdate];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sample" style:UIBarButtonItemStyleDone target:self action:@selector(clickedItem:)];
    
    // Do any additional setup after loading the view, typically from a nib.
}

// sample 2
- (void)clickedItem:(UIBarButtonItem *)item {
    [self.navigationController pushViewController:[NSClassFromString(@"SampleTableViewController") new] animated:YES];
}






- (IBAction)insertOrUpdate:(id)sender {
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
    
    Book *aBook = [Book bookWithID:123 name:@"How Are You?"];;
    
    NSMutableArray <Person *> *arrM = [NSMutableArray new];
    for ( int i = 0 ; i < 5 ; i ++ ) {
        Person *sj = [Person new];
        sj.personID = i;
        sj.name = [NSString stringWithFormat:@"%d", i];
        if ( i == 4 ) sj.name = [NSString stringWithFormat:@"1"];
        sj.tags = tags;
        sj.group = 100;
        sj.index = i;
        
        sj.aBook = aBook;
        sj.age = 20;
        
        sj.ID = 21321;
        sj.goods = goods;
        [arrM addObject:sj];
        
        sj.unique = i;
    }
    
    arrM.firstObject.unique = 1;
    
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModels:arrM callBlock:^(BOOL result) {
        if ( result ) {
            NSLog(@"插入成功!");
        }
    }];
}

- (IBAction)query:(id)sender {
//    [[SJDatabaseMapV2 sharedServer] queryAllDataWithClass:[Person class] completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
//        if ( data ) {
//            printf("查询成功!\n");
//            NSLog(@"%@", [data firstObject]);
//        }
//    }];
    
//    [[SJDatabaseMapV2 sharedServer] queryDataWithClass:[Person class] primaryValue:2 completeCallBlock:^(id<SJDBMapUseProtocol>  _Nullable model) {
//        if ( model ) {
//            NSLog(@"%@", model);
//        }
//    }];

//    [[SJDatabaseMapV2 sharedServer] queryDataWithClass:[Person class] queryDict:@{@"personID":@[@(1)]} completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
//        
//    }];
    
//    [[SJDatabaseMapV2 sharedServer] queryDataWithClass:[Person class] range:NSMakeRange(0, 2) completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
//        NSLog(@"%ld", data.count);
//    }];
    
//    [[SJDatabaseMapV2 sharedServer] queryQuantityWithClass:[Person class] completeCallBlock:^(NSInteger quantity) {
//        NSLog(@"-- %ld", quantity);
//    }];
    
    // fuzzy query
//    [[SJDatabaseMapV2 sharedServer] fuzzyQueryDataWithClass:[Person class] queryDict:@{@"name":@"1"} completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
//        NSLog(@"%zd", data.count);
//    }];
        
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
    for ( int i = 0 ; i < 5 ; i ++ ) {
        Person *sj = [Person new];
        sj.personID = i;
        sj.name = @"A'''B\"C'D\"";
        sj.tags = tags;
        sj.group = 100;
        sj.index = i;
        
        sj.aBook = [Book bookWithID:123 name:@"How Are You?"];
        sj.age = 20;

        sj.ID = 21321;
        sj.goods = goods;
        [arrM addObject:sj];
        
        sj.unique = i;
    }
    
    arrM.firstObject.unique = 1;
    // insert or update  sample
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModels:arrM callBlock:^(BOOL r) {

        [[SJDatabaseMap sharedServer] queryAllDataWithClass:[Person class] completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
            // update sample
            [self update];
        }];
        
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
        
        // update group and index
        person.group = 121;
        person.index = 32112;
        person.name = @"B''''B\"\"\"BBBB";
        
        // mixed
        [tagsM addObject:person.tags.firstObject];
        
        
        [[SJDatabaseMap sharedServer] update:person properties:@[@"tags", @"goods", @"group", @"index", @"name"] callBlock:^(BOOL result) {
            // query sample
            [self queryWithDict:@{@"name":@"B''''B\"\"\"BBBB", @"group":@(121), @"index":@(32112)}];
        }];
    }];
    
}




// ..
- (void)insertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)model callBlock:(void(^)(BOOL result))block {
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModel:[Person new] callBlock:nil];
}

- (void)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^)(BOOL result))block {
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModels:@[[Person new], [Person new]] callBlock:nil];
}

- (void)update:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields callBlock:(void (^ __nullable)(BOOL result))block {
    Person *xiaoMing = [Person new];
    xiaoMing.name = @"xiaoMing";
    xiaoMing.age = 20;
    xiaoMing.group = 121;
    
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModel:xiaoMing callBlock:^(BOOL result) {
        
        xiaoMing.age = 30;
        xiaoMing.name = @"xiaoMMM";
        
        // update
        [[SJDatabaseMap sharedServer] update:xiaoMing properties:@[@"age", @"name"] callBlock:nil];

    }];
}

- (void)update:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> * __nullable)insertedOrUpdatedValues callBlock:(void (^ __nullable)(BOOL result))block {
    
    Person *xiaoMing = [Person new];
    xiaoMing.name = @"xiaoMing";
    xiaoMing.age = 20;
    xiaoMing.group = 121;
    
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModel:xiaoMing callBlock:^(BOOL result) {
        
        xiaoMing.age = 30;
        xiaoMing.name = @"xiaoMMM";
        
        [[SJDatabaseMap sharedServer] update:xiaoMing properties:@[@"age", @"name"] callBlock:nil];
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
    [[SJDatabaseMap sharedServer] deleteDataWithClass:[Person class] primaryValues:primaryValues callBlock:nil];
}

- (void)delWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models {
    [[SJDatabaseMap sharedServer] deleteDataWithModels:models callBlock:nil];
}

- (void)delWithClass:(Class)cls {
    [[SJDatabaseMap sharedServer] deleteDataWithClass:cls callBlock:nil];
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
        
        NSLog(@"%zd", data.count);
        
        // range query
        [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] range:NSMakeRange(2, 10) completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
            NSLog(@"%zd", data.count);
            
            
            // fuzzy query
            [[SJDatabaseMap sharedServer] fuzzyQueryDataWithClass:[Person class] queryDict:@{@"name":@"A"} completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
                NSLog(@"%zd", data.count);
                
                // 匹配以 'B' 开头的name.
                [[SJDatabaseMap sharedServer] fuzzyQueryDataWithClass:[Person class] queryDict:@{@"name":@"B"} match:SJDatabaseMapFuzzyMatchFront completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
                    NSLog(@"%zd", data.count);
                    
                    // 清空某张表. 只会清空此表, 相关联的类不会删除
//                    [[SJDatabaseMap sharedServer] deleteDataWithClass:[Person class] callBlock:^(BOOL r) {
//                        NSLog(@"%zd", r);
//                    }];
                    
                    // 查询数量
                    [[SJDatabaseMap sharedServer] queryQuantityWithClass:[Person class] completeCallBlock:^(NSInteger quantity) {
                        NSLog(@"%zd", quantity);
                        
                        [[SJDatabaseMap sharedServer] fuzzyQueryDataWithClass:[Person class] property:@"name" part1:@"A" part2:@"\"" completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
                            NSLog(@"%zd", data.count);
                            
                            
                            [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] primaryValues:@[@(0), @(1), @(2)] completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
                                NSLog(@"%zd", data.count);
                                [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] property:@"name" values:@[@"A'''B\"C'D\"", @"B''''B\"\"\"BBBB"] completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
                                        NSLog(@"%zd", data.count);
                                    [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] queryDict:@{@"name":@[@"A'''B\"C'D\"", @"B''''B\"\"\"BBBB"]} completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
                                        NSLog(@"%zd", data.count);
                                        [[SJDatabaseMap sharedServer] sortQueryWithClass:[Person class] property:@"index" sortType:SJDatabaseMapSortType_Desc completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
                                            NSArray<Person *> *models = data;
                                            [models enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                                NSLog(@"sort(desc) query result : %zd", obj.index);
                                            }];
                                         
                                        }];
                                    }];
                                    
                                }];
                                
                            }];
                            
                        }];
                        
                    }];
                    
                }];
                
            }];
    
        }];
        
    }];
}

@end
