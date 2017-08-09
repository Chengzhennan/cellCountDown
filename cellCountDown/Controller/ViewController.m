//
//  ViewController.m
//  cellCountDown
//
//  Created by Mac on 2016/11/11.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import "ViewController.h"
#import "DataModel.h"
#import "CountDownCell.h"
#import <MJRefresh/MJRefresh.h>

static NSString *const ID = @"count";

@interface ViewController ()
// 保存含有倒计时的模型和indexPath
@property (nonatomic,strong)NSMutableDictionary *countDownTimeDict;
// 保存timer
@property (nonatomic,strong)NSMutableArray *timerArr;
// 数据源
@property (nonatomic,strong)NSMutableArray *dataSource;

// 缓存数据源
@property (nonatomic,strong)NSMutableArray *cacheDataSource;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CountDownCell class]) bundle:nil] forCellReuseIdentifier:ID];
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    
    //判断有没有缓存数据
    self.dataSource = [self JSONSerialisationRead];
    if (self.dataSource.count > 0)
    {
        [self enumerateDatasourceCountDown];
        return;
    }
    [self.tableView.mj_header beginRefreshing];
    

}

#pragma mark - Getters
-(NSMutableDictionary *)countDownTimeDict
{
    if (!_countDownTimeDict) {
        _countDownTimeDict = [NSMutableDictionary dictionary];
    }
    return  _countDownTimeDict;
}

-(NSMutableArray *)dataSource
{
    if (!_dataSource)
    {
        _dataSource = [NSMutableArray array];
    }
    return  _dataSource;
}


-(NSMutableArray *)timerArr
{
    if (!_timerArr) {
        _timerArr = [NSMutableArray array];
    }
    
    return _timerArr;
}


#pragma mark - 加载数据
-(void)loadNewData
{
    [self.tableView.mj_footer endRefreshing];

    NSMutableArray *newDataArr = [NSMutableArray array];
    for (int i = 0; i < 20; ++i)
    {
        //假数据,模型有倒计时是随机的
        DataModel *model = [[DataModel alloc]init];
        NSInteger randomInteger = arc4random() % 100000;
        if (randomInteger > 50000)
        {
            model.countTime = randomInteger;
            model.isCountDown = YES;

        }
        [newDataArr addObject:model];
    }
    self.dataSource = newDataArr;
    [self.countDownTimeDict removeAllObjects];
    [self.timerArr makeObjectsPerformSelector:@selector(invalidate)];
    //缓存数据
    [self JSONSerialisationSaveWithArr:self.dataSource];
    
    [self.tableView reloadData];

    
    //有倒计时数据的模型开始倒计时
    [self enumerateDatasourceCountDown];

  
    [self.tableView.mj_header endRefreshing];
}

-(void)loadMoreData
{
    [self.tableView.mj_header endRefreshing];

    NSMutableArray *moreDataArr = [NSMutableArray array];

    for (int i = 0; i < 10; ++i)
    {
        //假数据,模型有倒计时是随机的
        DataModel *model = [[DataModel alloc]init];
        NSInteger randomInteger = arc4random() % 100000;
        if (randomInteger > 50000)
        {
            model.countTime = randomInteger;
            model.isCountDown = YES;
        }
        [moreDataArr addObject:model];
    }
    [self.dataSource addObjectsFromArray:moreDataArr];

    //缓存数据
    [self JSONSerialisationSaveWithArr:self.dataSource];
    [self.tableView reloadData];
    [self enumerateDatasourceCountDown];
    [self.tableView.mj_footer endRefreshing];

}


#pragma mark - TableView datasource
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}




-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CountDownCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    cell.testLabel.text = [NSString stringWithFormat:@"第%ld行",indexPath.row];
    DataModel *model = self.dataSource[indexPath.row];
    
    cell.model = model;

    return cell;


}


#pragma mark - DownCount
//遍历数据源看下有没有倒计时
-(void)enumerateDatasourceCountDown
{
    for(int i = 0; i < self.dataSource.count; ++i)
    {
        DataModel *model = self.dataSource[i];
        if (model.countTime)
        {
            [self countDownModel:model andIndexPath:i];
        }
    }
}



-(void)countDownModel:(DataModel *)model andIndexPath:(NSInteger )indexInteger
{
    //哪一行的数据有倒计时
    NSString *indexKey = [NSString stringWithFormat:@"%ld",indexInteger];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:indexKey forKey:@"indexPath"];
    [dict setObject:@(model.countTime) forKey:indexKey];
    
    //把模型里的倒计时储存在字典中 以行数index索引为key
    //添加定时器之前先判断这一行的数据是不是已经添加了定时器
    NSNumber *number = self.countDownTimeDict[indexKey];
    NSInteger numberInteger =  [number integerValue];
    
    
    //如果在倒计时的字典中取不到 value 说明还没有添加定时器
    if (numberInteger <= 0)
    {
        //添加定时器
        NSTimer *timer  =  [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(numberCutDown:) userInfo:dict repeats:YES];
        [self.timerArr addObject:timer];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        
        NSLog(@"第%ld行已经添加了定时器",indexInteger);
    }
    [self.countDownTimeDict addEntriesFromDictionary:dict];
    
//    NSLog(@"%@",self.countDownTimeDict);
}

-(void)numberCutDown:(NSTimer *)timer
{
    //取出对应倒计时
    NSString * indexInteger = timer.userInfo[@"indexPath"];
    NSInteger index = [indexInteger integerValue];
    
    DataModel *model = self.dataSource[index];
    //修改模型时间
    model.countTime --;
    //刷新界面
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    if (model.countTime == 0)
    {
        NSLog(@"第%ld行的定时器销毁了",index);
        [timer invalidate];
        timer = nil;
        return;
    }
}



#pragma mark - save
//json存储
-(void)JSONSerialisationSaveWithArr:(NSArray *)array
{
    NSMutableArray *cacheArr = [NSMutableArray array];
    for (DataModel *model in array) {
        //把自定义对象转换成二进制字典对象
        [cacheArr addObject:[model dict]];
    }
    //把数组通过json序列化成二进制数据
    NSData *data = [NSJSONSerialization dataWithJSONObject:cacheArr options:0 error:nil];
    [data writeToFile:[self getDocumentFile] atomically:NO];
}

//json读取
-(NSMutableArray *)JSONSerialisationRead
{
    //取出二进制数据
    NSData *data = [NSData dataWithContentsOfFile:[self getDocumentFile]];
    if (!data) {
        return nil;
    }
    
    NSMutableArray *cacheArr = [NSMutableArray array];
    cacheArr = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    for (NSDictionary *dict in cacheArr)
    {
        DataModel *model =  [DataModel modelWithDict:dict];
        [self.dataSource addObject:model];
    }
 
    return self.dataSource;
}



//储存在document文件夹之下
-(NSString *)getDocumentFile
{
    NSArray *DirArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = DirArr[0];
    NSString *path =  [documentDir stringByAppendingPathComponent:@"cacheData"];
    return path;
}














@end
