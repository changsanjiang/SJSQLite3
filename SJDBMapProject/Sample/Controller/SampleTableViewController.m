//
//  SampleTableViewController.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SampleTableViewController.h"

#import "SampleVideoSection.h"

#import "SampleUser.h"

#import "SampleOrgan.h"

#import "SampleVideoTag.h"

#import "SampleVideoModel.h"

#import "SJDatabaseMap.h"

static NSString *const SampleTableViewCellID = @"SampleTableViewCell";

@interface SampleTableViewController ()

@property (nonatomic, strong) NSArray<SampleVideoSection *> *sections;

@end

@implementation SampleTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setupView];
    
    NSMutableArray<SampleVideoSection *> *sections = [self _convertJsonData];

    __weak typeof(self) _self = self;
    // insert
    [[SJDatabaseMap sharedServer] insertOrUpdateDataWithModels:sections callBlock:^(BOOL result) {
        NSLog(@"插入数据库: %zd", result);
        NSLog(@"database path: %@", [SJDatabaseMap sharedServer].dbPath);
        NSDate* tmpStartData = [NSDate date];
        // query
        [[SJDatabaseMap sharedServer] queryAllDataWithClass:[SampleVideoSection class] completeCallBlock:^(NSArray<id<SJDBMapUseProtocol>> * _Nullable data) {
            double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
            NSLog(@"%lf", deltaTime);
            __strong typeof(_self) self = _self;
            if ( !self ) return;
            self.sections = data;
            [self.tableView reloadData];
        }];
    }];
}

- (void)dealloc {
    NSLog(@"%zd - %s", __LINE__, __func__);
}


// UI
- (void)_setupView {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.tableView registerNib:[UINib nibWithNibName:SampleTableViewCellID bundle:nil] forCellReuseIdentifier:SampleTableViewCellID];
    self.tableView.rowHeight = [UIScreen mainScreen].bounds.size.width * 9 / 16 + 5;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

// Json Data
- (NSMutableArray<SampleVideoSection *> *)_convertJsonData {
    NSData *localJSONData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SampleData.json" ofType:@""]];
    NSDictionary *convertedDict = [NSJSONSerialization JSONObjectWithData:localJSONData options:0 error:nil];
    
    NSMutableArray<SampleVideoModel *> *videosM = [NSMutableArray new];
    NSArray<NSDictionary *> *videoDicts = convertedDict[@"videos"];
    [videoDicts enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull videoDict, NSUInteger idx, BOOL * _Nonnull stop) {
        SampleVideoModel *video = [[SampleVideoModel alloc] initWithDictionary:videoDict];
        [videosM addObject:video];
    }];
    
    NSMutableArray<SampleVideoSection *> *sectionsM = [NSMutableArray new];
    for ( int i = 0 ; i < 999; ++i ) {
        SampleVideoSection *section = [SampleVideoSection new];
        section.sectionId = i;
        section.sectionTitle = [NSString stringWithFormat:@"%03zd", i];
        section.videos = videosM;
        [sectionsM addObject:section];
    }
    
    return sectionsM;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SampleTableViewCellID forIndexPath:indexPath];
    [cell setValue:self.sections[indexPath.section].videos[indexPath.row] forKey:@"model"];
    return cell;
}

@end
