//
//  ViewController.m
//  LocalServer
//
//  Created by 熊先提 on 2020/12/3.
//

#import "ViewController.h"
#import "XTHTTPServer.h"

@interface ViewController ()
@property (weak) IBOutlet NSScrollView *textScrollView;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSButton *stopButton;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation ViewController
{
    XTHTTPServer *_server;
    NSString *_serverInfoString;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.string = @"请选择要广播的本地文件夹";
    // Do any additional setup after loading the view.
    self.stopButton.enabled = NO;
    self.textView.editable = NO;
}

- (IBAction)startServer:(id)sender {
    [self chooseModelImage];
}

- (IBAction)stopServer:(id)sender {
    [_server stopServer];
    self.stopButton.enabled = NO;
    self.startButton.enabled = YES;
}

- (void)chooseModelImage{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];//是否能选择文件file
    [panel setCanChooseDirectories:YES];//是否能打开文件夹
    [panel setAllowsMultipleSelection:NO];//是否允许多选file
    NSInteger finded = [panel runModal]; //获取panel的响应
    if (finded == NSModalResponseOK) {
        //  NSFileHandlingPanelCancelButton    = NSModalResponseCancel；
        //  NSFileHandlingPanelOKButton    = NSModalResponseOK,
        for (NSURL *url in [panel URLs]) {
            NSLog(@"--->%@",url);
            //这个url是文件的路径
            //同时这里可以处理你要做的事情 do something
            [self startServerFor:url];
            break;
        }
    }
}

- (void)startServerFor:(NSURL *)url {
    if (!_server) {
        _server = [[XTHTTPServer alloc]init];
        __weak typeof(self)weakSelf = self;
        _server.updateServerReourcesBlock = ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf updateList];
        };
    } else {
        [_server stopServer];
    }
   BOOL start = [_server startServerForPath:url.path];
    if (start) {
        self.stopButton.enabled = YES;
        self.startButton.enabled = NO;
        [self updateList];
    }
}

- (void)updateList {
    NSArray <NSString *>*list = [_server resourceServerPathList];
    if (list.count > 0) {
        _serverInfoString = @"当前可以访问的连接: \n";
        [list enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _serverInfoString = [_serverInfoString stringByAppendingFormat:@"%@\n",obj];
        }];
    } else {
        _serverInfoString = [NSString stringWithFormat:@"请将要网络共享的资源文件拖入目录：%@ 中",[_server serverlocalPath]];
    }
    self.textView.string = _serverInfoString;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
