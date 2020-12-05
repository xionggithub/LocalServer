//
//  XTHTTPServer.m
//  XTFileSharing
//
//  Created by Hao Shen on 6/19/20.
//  Copyright © 2020 xiongxianti. All rights reserved.
//

#import "XTHTTPServer.h"
#import <HTTPServer.h>
#import <sys/socket.h>
#import <ifaddrs.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

//#define PORT 8080
#define PORT 80
@implementation XTHTTPServer
{
    HTTPServer *httpServer;
    UInt16      _listeningPort;
    NSString    *_publishedName;
    NSString    *_interface;
    NSString    *_IPAddress;
    NSTimer     *_timer;
    NSArray     *_subPaths;
}

- (void)startServer{
    [self startServerForPath:[self tmpServerFileRootPath]];
}

- (BOOL)startServerForPath:(NSString *)path{
    httpServer = [[HTTPServer alloc] init];
    [httpServer setType:@"_http._tcp."];
     [httpServer setPort:PORT]; //此处可设置成80端口，如果是80端口，访问手机服务器的时候可以不用写端口号了
    [httpServer setDocumentRoot:path];
    NSLog(@"Setting document root: %@", path);
    NSError * error;
    if([httpServer start:&error])
    {
        _listeningPort = [httpServer listeningPort];
        _publishedName = [httpServer publishedName];
        _interface = [httpServer interface];
        _IPAddress = [self getDeviceIPAddress];
        NSLog(@"start server success in port %d publisname： %@  interface:%@",_listeningPort,_publishedName,_interface);
        NSLog(@"start server success in ip %@",_IPAddress);
        if (!_timer) {
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkoutFileChanged) userInfo:nil repeats:YES];
            [_timer setFireDate:[NSDate distantPast]];
        }
        return  YES;
    }
    else
    {
        if (_timer) {
            [_timer setFireDate:[NSDate distantFuture]];
        }
        NSLog(@"启动失败 %@",error);
        return NO;
    }
}

- (void)stopServer{
    [httpServer stop];
    if (_timer) {
        [_timer setFireDate:[NSDate distantFuture]];
    }
}

- (void)checkoutFileChanged {
    NSString *rootPath = [httpServer documentRoot];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray <NSString *>*subPaths = [fm subpathsAtPath:rootPath];
    BOOL needUpdate = NO;
    if (!_subPaths) {
        needUpdate = YES;
    } else {
        for (NSString *obj in subPaths) {
            if (![_subPaths containsObject:obj]) {
                needUpdate = YES;
                break;
            }
        }
    }
    _subPaths = subPaths;
    
    if (needUpdate) {
        if (self.updateServerReourcesBlock) {
            self.updateServerReourcesBlock();
        }
    }
}

- (NSArray <NSString *>*)resourceServerPathList {
    NSMutableArray *list = [NSMutableArray array];
    NSString *rootPath = [httpServer documentRoot];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *subPaths = [fm subpathsAtPath:rootPath];
    NSString *url = @"http://";
    url = [url stringByAppendingFormat:@"%@",[self ipAddress]];
    [subPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [list addObject: [NSString stringWithFormat:@"%@/%@",url,obj]];
    }];
    return list;
}

- (NSString *)serverlocalPath {
    return [httpServer documentRoot];
}

#pragma mark - Get the device IP address
- (NSString *)getDeviceIPAddress {
    NSString *address = @"an error occurred when obtaining ip address";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    success = getifaddrs(&interfaces);
    
    if (success == 0) { // 0 表示获取成功
        
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                for(int i = 0; i < 4; i++){
                    if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:[NSString stringWithFormat:@"en%d", i]]) {
                        // Get NSString from C String
                        struct sockaddr_in *sockaddr = (struct sockaddr_in *)temp_addr->ifa_addr;
                        address = [NSString stringWithUTF8String:inet_ntoa(sockaddr->sin_addr)];
                        if (![address isEqualToString:@"an error occurred when obtaining ip address"])
                        {
                            break;
                        }
                    }
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    NSLog(@"本机的IP是：%@", address);
    return address;
}


#pragma mark - Get the device MAC address
- (NSString *) getDeviceMacAddress

{
    
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1/n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    
    ifm = (struct if_msghdr *)buf;
    
    sdl = (struct sockaddr_dl *)(ifm + 1);
    
    ptr = (unsigned char *)LLADDR(sdl);
    
    
    NSString *outstring = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    
    // release pointer
    free(buf);
    
    return [outstring lowercaseString];
}
- (NSString *)serverRootPath{
    return [self tmpServerFileRootPath];
}
- (NSString *)tmpServerFileRootPath{
    NSString *docPath  = [self documentDirectory];
    NSString *tmpServerRootPath = [docPath stringByAppendingPathComponent:@"Server"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:tmpServerRootPath]) {
        NSError *error = nil;
        BOOL create = [fm createDirectoryAtPath:tmpServerRootPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (!create || error) {
            NSLog(@"创建server 根目录失败");
        }
    }
    return tmpServerRootPath;
}
- (NSString *)documentDirectory{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return path;
}
- (NSString *)cacheDirectory{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    return path;
}
- (NSString *)serverURL{
    NSString *url = @"http://";
    url = [url stringByAppendingFormat:@"%@",[self ipAddress]];
    url = [url stringByAppendingString:@"/index.html"];
    return url;
}
- (NSString *)ipAddress{
    if (_IPAddress.length == 0) {
        _IPAddress = [self getDeviceIPAddress];
    }
    return _IPAddress;
}
@end
