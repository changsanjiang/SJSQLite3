# SJDBMap

pod 'SJDBMap' （Please perform " pod update --no-repo-update "）

根据模型自动创建与该类相关的表(多个表), 可以进行增删改查. 当类添加了新的属性的时候, 会自动更新相关的表字段.
Automatically create tables based on the model. To achieve additions and deletions. When the class adds a new attribute, it will automatically update the relevant table field.


#### Use

实现协议方法.   
Imp SJDBMapUseProtocol Method.

```
@interface SampleVideoModel : NSObject<SJDBMapUseProtocol>
@property (nonatomic, assign) NSInteger videoId;
@property (nonatomic, strong) NSArray<SampleVideoTag *> *tags;
@property (nonatomic, strong) NSArray<SampleUser *> *likedUsers;
@property (nonatomic, strong) SampleOrgan *organ;
@end

@implementation SampleVideoModel
+ (NSString *)primaryKey {
    return @"videoId";
}

// model
+ (NSDictionary<NSString *,NSString *> *)correspondingKeys {
    return @{
            @"organ":@"code",
            };
}

// arr
+ (NSDictionary<NSString *,Class> *)arrayCorrespondingKeys {
    return @{
            @"tags":[SampleVideoTag class],
            @"likedUsers":[SampleUser class],
            };
}
@end
```

#### insertOrUpdate 插入数据或更新数据
数据在插入表之前， 会检测是否已经存在相关表。如果不存在，会先创建相关表（可能会创建多个表）， 再进行数据的更新或插入。
如果类中新添了属性， 会自动检测并更新相关表字段。    
Data before the table is inserted, it will detect whether the relevant table already exists. If it does not exist, it will first create a related table (may create multiple tables), and then update the data or insert.
If a new attribute is added to the class, the associated table field is automatically detected and updated.

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
#### delete 删除
删除数据是删除该类对应的表的数据， 与其关联的其他类的数据没有做处理。    
Deleting data is to delete the data of the corresponding table of the class, and the data of the other class associated with it is not processed.

```
- (void)del {
    [[SJDBMap sharedServer] deleteDataWithClass:[Person class] primaryValue:0 callBlock:^(BOOL result) {
       // ...
    }];
}
```
#### query 查询
查询数据会将与该类相关的所有数据都读取出来， 并转换相应的模型。    
The query data will read all the data associated with that class and convert the corresponding model.

```
- (void)query {
    [[SJDBMap sharedServer] queryAllDataWithClass:[Person class] completeCallBlock:^(NSArray<id> * _Nonnull data) {
       // ...
    }];
}
```
#### Use attention 使用注意
   模型需要一个主键或自增主键     
   The model requires a primary key or a self-incrementing key

