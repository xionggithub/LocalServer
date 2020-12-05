//
//  XTHTTPServer.h
//  XTFileSharing
//
//  Created by Hao Shen on 6/19/20.
//  Copyright © 2020 xiongxianti. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XTHTTPServer : NSObject
@property(nonatomic, copy) void(^updateServerReourcesBlock)(void);
- (BOOL)startServerForPath:(NSString *)path;

- (void)stopServer;
/// 访问ip
- (NSString *)ipAddress;
/// 访问连接样例
- (NSString *)serverURL;
/// 本地共享文件夹
- (NSString *)serverlocalPath;
/// 共享资源连接列表
- (NSArray <NSString *>*)resourceServerPathList;
@end

NS_ASSUME_NONNULL_END
