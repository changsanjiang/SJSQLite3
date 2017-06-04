# SJDBMap
Automatically create tables based on the model. To achieve additions and deletions. Automatically add new fields.
根据模型自动创建与该类相关的表(多个表), 可以进行增删改查. 当类添加了新的属性的时候, 会自动更新相关的表字段.
```
- (void)insertOrUpdate {
    
    Person *sj = [Person new];
    sj.personID = 0;
    sj.name = @"sj";
    sj.tags = @[[PersonTag tagWithID:0 des:@"A"],
                [PersonTag tagWithID:1 des:@"B"],
                [PersonTag tagWithID:2 des:@"C"],
                [PersonTag tagWithID:3 des:@"D"],
                [PersonTag tagWithID:4 des:@"E"],];
    
    [[SJDBMap sharedServer] insertOrUpdateDataWithModel:sj callBlock:^(BOOL result) {
        // ....
    }];
}

- (void)del {
    [[SJDBMap sharedServer] deleteDataWithClass:[Person class] primaryValue:0 callBlock:^(BOOL result) {
       // ...
    }];
}

- (void)query {
    [[SJDBMap sharedServer] queryAllDataWithClass:[Person class] completeCallBlock:^(NSArray<id> * _Nonnull data) {
       // ...
    }];
}

```
