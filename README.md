# SJDBMap

Automatically create tables based on the model. To achieve additions and deletions. Automatically add new fields.
根据模型自动创建与该类相关的表(多个表), 可以进行增删改查. 当类添加了新的属性的时候, 会自动更新相关的表字段.

#### 插入数据或更新数据
数据在插入表之前， 会检测是否已经存在相关表。如果不存在，会先创建相关表（可能会创建多个表）， 再进行数据的更新或插入。
如果类中新添了属性， 会自动检测并更新相关表字段。
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
```
#### 删除数据
删除数据是删除该类对应的表的数据， 与其关联的其他类的数据没有做处理。
```
- (void)del {
    [[SJDBMap sharedServer] deleteDataWithClass:[Person class] primaryValue:0 callBlock:^(BOOL result) {
       // ...
    }];
}
```
#### 查询
查询数据会将与该类相关的所有数据都读取出来， 并转换相应的模型。
```
- (void)query {
    [[SJDBMap sharedServer] queryAllDataWithClass:[Person class] completeCallBlock:^(NSArray<id> * _Nonnull data) {
       // ...
    }];
}
```
#### 使用注意
1. 使用需要遵守 SJDBMapUseProtocol
1. 模型需要一个主键或自增主键
