//
//  ZHNetworking.m
//  RenheJinfu
//
//  Created by ZH on 2018/8/20.
//  Copyright © 2018年 张豪. All rights reserved.
//

#import "ZHNetworking.h"

@implementation ZHNetworking

/// 1 > GET请求
+ (void)GETRequestWithUrl:(NSString *)urlStr parameters:(id)parameters success:(void(^)(id requestData))success failure:(void(^)(NSError *error))failure{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager GET:urlStr parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];

}


/// 2 > POST请求, 无请求头, 自带网络请求提示框
+ (void)POSTRequestWithUrl:(NSString *)urlStr parameters:(id)parameters success:(void(^)(id requestData))success failure:(void(^)(NSError *error))failure{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];// 没有这行会失败
    
    // *********以下是两种头的设置
//    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];// 防止中文请求出现??乱码
//    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"x-www-form-urlencoded"];// 防止中文请求出现??乱码
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json", @"text/plain", @"text/html", nil]; // 防止出现500错误
    // *********以上是两种头的设置
    
    
    // 设置请求时间(超过了就是超时, 就会走到failure的回调里面)
    manager.requestSerializer.timeoutInterval = 15; // 请求超时时间(15秒提示请求超时)
    [manager POST:urlStr parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        // 这里可以获取到目前的数据请求的进度
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSLog(@"请求成功了, 数据是--%@", responseObject);
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
//        success(responseObject); // 返回给VC的数据就是在这, 这是直接返回的不解析的responseObject
        success(resultDic); // 这里返回的是解析后的字典
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSData * data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
        NSString * str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"服务器的错误原因:%@",str);
        failure(error);
        
    }];

}

@end
