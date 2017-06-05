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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"\n%@", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject);
    
    
    //    [self del];
    
    [self insertOrUpdate];
    //
    //    //    [self query];
    //
    //    [self queryWithDict:@{@"name":@"sj"}];
    
    // Do any additional setup after loading the view, typically from a nib.
}


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
    
    //    [[SJDBMap sharedServer] insertOrUpdateDataWithModel:sj callBlock:^(BOOL result) {
    //
    //    }];
    
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

- (void)del {
    [[SJDatabaseMap sharedServer] deleteDataWithClass:[Person class] primaryValue:0 callBlock:^(BOOL result) {
        // ...
    }];
    
    [[SJDatabaseMap sharedServer] deleteDataWithClass:[Person class] primaryValue:1 callBlock:^(BOOL result) {
        // ...
    }];
    [[SJDatabaseMap sharedServer] deleteDataWithClass:[Person class] primaryValue:2 callBlock:^(BOOL result) {
        // ...
    }];
}

- (void)query {
    [[SJDatabaseMap sharedServer] queryAllDataWithClass:[Person class] completeCallBlock:^(NSArray<id> * _Nonnull data) {
        // ...
    }];
}

- (void)queryWithDict:(NSDictionary *)dict {
    [[SJDatabaseMap sharedServer] queryDataWithClass:[Person class] queryDict:dict completeCallBlock:^(NSArray<id> *data) {
        NSLog(@"%@", data);
    }];
}


@end
