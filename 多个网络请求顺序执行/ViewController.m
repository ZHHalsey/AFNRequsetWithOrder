//
//  ViewController.m
//  多个网络请求顺序执行
//
//  Created by ZH on 2018/9/19.
//  Copyright © 2018年 张豪. All rights reserved.
//
#define isRegister @"http://118.190.132.71:8081/RHJF11023"
#define sendCode @"http://118.190.132.71:8081/RHJF11042"


#import "ViewController.h"
#import "ZHNetworking.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // 需求是先判断手机号是否注册过, 如果注册过就返回, 没注册过继续请求发送验证码接口
    /*
     1 >
     手机号是否注册过接口 : http://118.190.132.71:8081/RHJF1103
     参数:
     mobile = 15001135618;
     "user_type" = 2;
     username = Adsfdf;
     /// 上面请求成功后 才会进行下面的这个请求
     2 >
     发送验证码接口 : http://118.190.132.71:8081/RHJF1102
     参数:
     mobile = 15001135600;
     "user_type" = 2;
     username = Adsfdf;
     */
    
    // 两个接口请求代码按先后顺序写(没实现需求, 请求不是顺序执行的)
//    [self requestData];
    
    // 第二个请求在第一个请求成功的回调里进行(能够实现需求, 请求是顺序执行的)
//    [self requestDataInBlock];
    
    // 用GCD任务和组(没实现需求, 代码执行是按顺序, 但是请求结果不是顺序执行的, 因为AFN本身就是异步加载)
    // 没实现顺序请求, 但是实现了多个请求全都完成后, 再进行另一个请求或者操作
    [self requestWithDispatchGroup];
    
// 用NSOperation操作依赖(没实现需求, 代码执行是按顺序, 但是请求结果不是顺序执行的, 因为AFN本身就是异步加载)
//    [self requestWithOperationDependency];
    
// 用GCD信号量实现(能够实现需求, 请求是顺序执行的)
//    [self requestWithDispatchSemaphore];
    
// 用GCD的barrier函数实现(没有实现需求, 代码执行是顺序的, 但是请求结果不是顺序执行的, 由于AFN本身就是异步加载)
//    [self requestWithGCDBarrier];
}
#pragma mark - 用GCD信号量实现(能够实现需求, 请求是顺序执行的)
- (void)requestWithDispatchSemaphore{
    // 创建一个信号量, 作为全局变量
    dispatch_semaphore_t semaphore;
    // 初始化信号量为0
    semaphore = dispatch_semaphore_create(0);
    // 创建一个队列(不是创建组)
    dispatch_queue_t queue = dispatch_queue_create("ZHSemaphore", NULL);
    dispatch_async(queue, ^{
        NSLog(@"当前线程--%@", [NSThread currentThread]);
        
        // 第一个请求手机号是否注册过
        NSDictionary *dic1 = @{@"username":@"Adsfdf",@"mobile":@"15001135618",@"user_type":@"2"}; // 参数字典
        [ZHNetworking POSTRequestWithUrl:isRegister parameters:dic1 success:^(id requestData) {
            NSLog(@"\n第一个请求线程--%@\n数据--%@", [NSThread currentThread], requestData);
            if ([[requestData[@"error"][@"code"] stringValue] isEqualToString:@"1"]) { // 请求错误
                NSLog(@"请求失败了, 信息是--%@", requestData[@"error"][@"message"]);
            }else{
//                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER); // 信号量 - 1
                dispatch_semaphore_signal(semaphore); // 信号量 + 1
            }
        } failure:^(NSError *error) {
            /*
             失败的这里信号量加不加1视情况而定
             如果请求失败后, 需要继续走后面的第二个请求, 这里就 + 1
             如果请求失败后, 不用继续走后面的第二个请求, 这里就不用 + 1
             这里是先判断手机号是否注册过, 然后在发验证码, 如果第一个请求都失败了, 也就没必要走第二个, 所以这里不用 + 1
             */
//            dispatch_semaphore_signal(semaphore);
            NSLog(@"第一个发送验证码请求失败了--%@", error);
        }];
        // *************************************
        
        NSLog(@"来到这里了1");
        // ********重点就是这个wait, 这行代码的作用是先对信号量进行 - 1 然后更0做对比, 当信号少于0的时候, 就会一直等待, 直到这里的不小于(大于)0了, 代码才会往下走
        // 等待信号, 先对信号量 - 1, 然后跟0对比, 当信号总量少于0的还是就会一直等待, 否则就可以正常的执行, 并让信号量 - 1
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSLog(@"来到这里了2");
        
        // 第二个发送验证码请求
        NSDictionary *dic2 = @{@"type":@"1",@"mobile":@"15001135618",@"P8":@"Ios"}; // 参数字典
        [ZHNetworking POSTRequestWithUrl:sendCode parameters:dic2 success:^(id requestData) {
            NSLog(@"\n第二个请求线程--%@\n数据--%@", [NSThread currentThread], requestData);
            if ([[requestData[@"error"][@"code"] stringValue] isEqualToString:@"1"]) { // 请求错误
                NSLog(@"请求失败了, 信息是--%@", requestData[@"error"][@"message"]);
            }else{

            }
        } failure:^(NSError *error) {
            // 失败的时候信号量也 + 1
            NSLog(@"第二个发送验证码请求失败了--%@", error);
        }];
        // *************************************
    });
}

#pragma mark - 用NSOperation操作依赖
/// 用NSOperation操作依赖(没实现需求, 代码执行是按顺序, 但是请求不是顺序执行的, 因为AFN本身就是异步加载)
- (void)requestWithOperationDependency{
    /*
        下面的逻辑是
     创建一个队列, 然后创建两个操作, 操作2依赖操作1, 然后两个操作加到线程中
     这个方法跟dispath一样也是一般的顺序执行有用, 但是对于网络请求没用, 因为网络请求AFN本身就是异步请求的
     */
    // 创建队列
    NSOperationQueue * queue = [[NSOperationQueue alloc]init];
    // 创建操作2
    NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
        [self firstRequest];
        NSLog(@"执行第1次操作，线程：%@",[NSThread currentThread]);
    }];
    // 创建操作2
    NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
        [self secondRequest];
        NSLog(@"执行第2次操作，线程：%@",[NSThread currentThread]);
    }];
    //添加依赖
    [operation2 addDependency:operation1]; // 队列2依赖队列1
    // 操作添加到队列中
    [queue addOperation:operation1];
    [queue addOperation:operation2];

}
#pragma mark - 用GCD任务和组实现(没实现顺序请求, 但是实现了多个请求全都完成后, 再进行另一个请求或者操作)
/// 用GCD任务和组(没实现需求, 代码执行是按顺序, 但是请求不是顺序执行的, 因为AFN本身就是异步加载)
- (void)requestWithDispatchGroup{
    // 方式1 > 以前的写法
//    /*
//        下面的逻辑是
//     创建一个组, 然后把任务放到组中, 然后等组中的任务都执行完了, 就会去执行dispatch_group_notify里面
//     这个方法对一般的顺序执行有用, 但是对于网络请求没用, 因为网络请求AFN本身就是异步请求的
//     */
//    // 创建一个组
//    dispatch_group_t group = dispatch_group_create();
//    // 创建全局队列
//    dispatch_queue_t global_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    // 开启任务执行第一个请求任务
//    dispatch_group_async(group, global_queue, ^{
//        // 第一个请求手机号是否注册过
//        [self firstRequest];
//        // *************************************
//        NSLog(@"单独的打印1");
//    });
//
//    // 获取main_queue
//    dispatch_queue_t main_queue = dispatch_get_main_queue();
//    // 等group中的队列执行完毕后, 再执行下面的操作
//    dispatch_group_notify(group, main_queue, ^{
//        // 第二个发送验证码请求
//        [self secondRequest];
//        // *************************************
//        NSLog(@"单独的打印2");
//
//    });
    
    
    
    
    // 方式2 > 关于GCD组的新写法, 加入了enter和leave函数 by ZH 2020.5.15
    /*
        下面这个写法最大的场景用处在于, 需要几个操作全都完成后, 然后再进行另外的操作, 如果操作本身是异步的话, 就需要通过enter和leave来控制了, 如果只有两个网络请求的话, 这两个网络请求也能实现顺序进行, 如果3个及以上的网络请求的话, 就不能了, 因为notify只能保证前面的几个请求都完成了, 当时前面几个请求的顺序是保证不了的, 谁快谁就先执行完
     */
    dispatch_group_t group = dispatch_group_create(); // 创建组
    dispatch_queue_t queue = dispatch_queue_create("groupQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_group_enter(group);// 通知group, 下个任务要放group中执行
    dispatch_group_async(group, queue, ^{
        NSLog(@"000");
        NSLog(@"开始进行登录请求");
        NSDictionary *loginDic = @{@"userName":@"lgys06", @"password":@"123321"};
        NSString *loginUrl = @"http://mm-dev.ebnew.com/mobile/user/login";
        [ZHNetworking POSTRequestWithUrl:loginUrl parameters:loginDic success:^(id requestData) {
            NSLog(@"登录请求成功--%@", requestData);
            dispatch_group_leave(group); // 通知 group,任务成功完成,要移除,与 enter成对出现
        } failure:^(NSError *error) {
            NSLog(@"登录请求失败--%@", error);
            // 失败里面要不要leave视情况而定, 如果最后notify里面的执行的任务, 必须要这里成功才能执行, 那么这里就不要leave, 调用了几个enter, 就需要调用几个leave, 如果调用了3个enter, 调用了2个leave, 也不会走到notify函数中
//            dispatch_group_leave(group);
        }];

        NSLog(@"111");
    });
    NSLog(@"222");
    dispatch_group_enter(group);
    dispatch_group_async(group, queue, ^{
        NSLog(@"333");
        NSLog(@"开始进行检查版本请求");
        NSDictionary *checkVersionDic = @{@"resource":@"ios", @"version":@"83"};
        NSString *checkVersionUrl = @"http://mm-dev.ebnew.com/mobile/version/getAppVersion";
        [ZHNetworking GETRequestWithUrl:checkVersionUrl parameters:checkVersionDic success:^(id requestData) {
            NSLog(@"检查版本请求成功--%@", requestData);
            dispatch_group_leave(group); // 通知 group,任务成功完成,要移除,与 enter成对出现
        } failure:^(NSError *error) {
            NSLog(@"检查版本请求失败--%@", error);
//            dispatch_group_leave(group); // 通知 group,任务成功完成,要移除,与 enter成对出现
        }];

        NSLog(@"444");
    });
    NSLog(@"555");
    
    /*
     通过打印结果可知, 上面的两个请求方式并没有按照顺序执行, 哪个快哪个就先完成, 然后上面的请求全部完成后, 才会走到下面这个notify里面, 这个场景也很有用, 比如异步下载图片, 下载很多张, 然后合成一张图, 这个场景就需要你下载图片的几个操作要同时完成才能进行图片合成, 但是下载图片的几个操作顺序任意, 哪张图先下载完没关系, 重要的是这些图片都要全部下载完然后才能进行合成, 这种场景下就可以用GCD组的这种方式来实现
     不过需要注意的点有 : leave函数需要跟enter成对出现, 并且leave需要放在请求的回调中, 如果不放在回调中的话, 因为请求本身就是异步的, 所以也会直接走到notify里面, 所以需要leave放在请求陈宫的回调中
     */
    dispatch_group_notify(group, queue, ^{ // 只要上面的 任务组完成，就会调用，不完成不会调用
        NSLog(@"666");
        [self LiveTrading];
        NSLog(@"777");
    });
    NSLog(@"888");
    
    
}
#pragma mark - 两个接口进行请求(结果是不分顺序的, 不能实现需求)
/// 两个接口进行请求(不分顺序的)
- (void)requestData{
    /*
     这么请求有个弊端, 有时候第一个请求先完成, 有时候第二个请求先完成, 没顺序, 哪个快哪个就先完成
     */
    // 第一个请求手机号是否注册过
    [self firstRequest];
    // *************************************
    
    // 第二个发送验证码请求
    [self secondRequest];
    // *************************************
}

#pragma mark - 第二个请求在第一个请求成功的回调里进行(实现需求, 请求是顺序执行的)
// 第二个请求在第一个请求成功的回调里进行
- (void)requestDataInBlock{
    // 第一个请求手机号是否注册过
    NSDictionary *dic1 = @{@"username":@"Adsfdf",@"mobile":@"15001135333",@"user_type":@"2"}; // 参数字典
    [ZHNetworking POSTRequestWithUrl:isRegister parameters:dic1 success:^(id requestData) {
        NSLog(@"\n第一个请求线程--%@\n数据--%@", [NSThread currentThread], requestData);
        if ([[requestData[@"error"][@"code"] stringValue] isEqualToString:@"1"]) { // 请求错误
            NSLog(@"请求失败了, 信息是--%@", requestData[@"error"][@"message"]);
        }else{
            // 第二个发送验证码请求
            NSDictionary *dic2 = @{@"type":@"1",@"mobile":@"15001135618",@"P8":@"Ios"}; // 参数字典
            [ZHNetworking POSTRequestWithUrl:sendCode parameters:dic2 success:^(id requestData) {
                NSLog(@"\n第二个请求线程--%@\n数据--%@", [NSThread currentThread], requestData);
                if ([[requestData[@"error"][@"code"] stringValue] isEqualToString:@"1"]) { // 请求错误
                    NSLog(@"请求失败了, 信息是--%@", requestData[@"error"][@"message"]);
                }else{}
            } failure:^(NSError *error) {
                NSLog(@"请求失败了--%@", error);
            }];
            // *************************************
        }
    } failure:^(NSError *error) {
        NSLog(@"请求失败了--%@", error);
    }];
}

#pragma mark - 第一个请求手机号是否注册过
/// 第一个请求手机号是否注册过
- (void)firstRequest{
    // 第一个请求手机号是否注册过
    NSDictionary *dic1 = @{@"username":@"Adsfdf",@"mobile":@"15001135618",@"user_type":@"2"}; // 参数字典
    [ZHNetworking POSTRequestWithUrl:isRegister parameters:dic1 success:^(id requestData) {
        NSLog(@"\n第一个请求线程--%@\n数据--%@", [NSThread currentThread], requestData);
        if ([[requestData[@"error"][@"code"] stringValue] isEqualToString:@"1"]) { // 请求错误
            NSLog(@"请求失败了, 信息是--%@", requestData[@"error"][@"message"]);
        }else{}
    } failure:^(NSError *error) {
        NSLog(@"请求失败了--%@", error);
    }];
    // *************************************
    
}
#pragma mark - 第二个发送验证码请求
/// 第二个发送验证码请求
- (void)secondRequest{
    // 第二个发送验证码请求
    NSDictionary *dic2 = @{@"type":@"1",@"mobile":@"15001135618",@"P8":@"Ios"}; // 参数字典
    [ZHNetworking POSTRequestWithUrl:sendCode parameters:dic2 success:^(id requestData) {
        NSLog(@"\n第二个请求线程--%@\n数据--%@", [NSThread currentThread], requestData);
        if ([[requestData[@"error"][@"code"] stringValue] isEqualToString:@"1"]) { // 请求错误
            NSLog(@"请求失败了, 信息是--%@", requestData[@"error"][@"message"]);
        }else{}
    } failure:^(NSError *error) {
        NSLog(@"请求失败了--%@", error);
    }];
    // *************************************
    
}


#pragma mark - 新增加的栅栏函数 by ZH 2020.5.15
// 栅栏函数实现顺序请求(不能实现顺序请求, 因为添加到queue中任务本身就是异步的, 所以不行)
- (void)requestWithGCDBarrier{
    // DISPATCH_QUEUE_CONCURRENT : 并发队列
    // DISPATCH_QUEUE_SERIAL : 串行队列
    dispatch_queue_t queue = dispatch_queue_create("ZHQueue", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"000");
    dispatch_async(queue, ^{
        NSLog(@"111");
        [self loginRequest]; // 请求本身就是异步, 当程序过了这一行, 就能走到barrier里面
        NSLog(@"222");
    });
    NSLog(@"333");
    // 这里用barrier_syns请求结果一样, 就是打印结果不同, 主要区别就是sync这个会阻塞主线程
    dispatch_barrier_async(queue, ^{
        NSLog(@"444");
        [self checkVersionRequest];
        NSLog(@"555");
    });
    NSLog(@"666");
}
// 1 > 登录请求
- (void)loginRequest{
    NSLog(@"开始进行登录请求");
    NSDictionary *loginDic = @{@"userName":@"lgys06", @"password":@"123321"};
    NSString *loginUrl = @"http://mm-dev.ebnew.com/mobile/user/login";
    [ZHNetworking POSTRequestWithUrl:loginUrl parameters:loginDic success:^(id requestData) {
        NSLog(@"登录请求成功--%@", requestData);
    } failure:^(NSError *error) {
        NSLog(@"登录请求失败--%@", error);
    }];
}
// 2 > 检查版本请求(get)
- (void)checkVersionRequest{
    NSLog(@"开始进行检查版本请求");
    NSDictionary *checkVersionDic = @{@"resource":@"ios", @"version":@"83"};
    NSString *checkVersionUrl = @"http://mm-dev.ebnew.com/mobile/version/getAppVersion";
    [ZHNetworking GETRequestWithUrl:checkVersionUrl parameters:checkVersionDic success:^(id requestData) {
        NSLog(@"检查版本请求成功--%@", requestData);
    } failure:^(NSError *error) {
        NSLog(@"检查版本请求失败--%@", error);
    }];
}
// 3 > 实时交易量请求
- (void)LiveTrading{
    NSLog(@"开始交易量请求");
    NSString *url = @"http://mm-dev.ebnew.com/mobile/filter/search/findLiveTrading";
    [ZHNetworking GETRequestWithUrl:url parameters:nil success:^(id requestData) {
        NSLog(@"交易量请求成功--%@", requestData);
    } failure:^(NSError *error) {
        NSLog(@"交易量请求失败--%@", error);
    }];

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
