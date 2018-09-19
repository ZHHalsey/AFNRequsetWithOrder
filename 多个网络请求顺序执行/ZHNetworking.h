//
//  ZHNetworking.h
//  RenheJinfu
//
//  Created by ZH on 2018/8/20.
//  Copyright © 2018年 张豪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import <UIKit/UIKit.h>

@interface ZHNetworking : NSObject

/// 1 > GET请求
+ (void)GETRequestWithUrl:(NSString *)urlStr
               parameters:(id)parameters
                  success:(void(^)(id requestData))success
                  failure:(void(^)(NSError *error))failure;


/// 2 > POST请求, 无请求头
+ (void)POSTRequestWithUrl:(NSString *)urlStr
                parameters:(id)parameters
                   success:(void(^)(id requestData))success
                   failure:(void(^)(NSError *error))failure;


@end
