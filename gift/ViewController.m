//
//  ViewController.m
//  gift
//
//  Created by ShanCheli on 17/5/23.
//  Copyright © 2017年 shancheli. All rights reserved.
//

#import "ViewController.h"
#import "WXApi.h"
#import "WXApiManager.h"
#import "AFNetworking.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

#define APPID       @"wxf539a3b14221c6fa"
#define APPSECRET   @"08c1aa6b505a498266fd52a976a30933"


#define login @"http://app.qagbpz.cn/login"
#define webUrl @"http://app.qagbpz.cn/menu"

@interface ViewController ()<UIWebViewDelegate, WXApiDelegate, UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webview;

@property (nonatomic, copy) NSString *token;

@property (nonatomic, copy) NSString *openid;

@property (nonatomic, copy) NSDictionary *userInfoDic;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getAccess_tokenWithString) name:@"loginSuccess" object:nil];
    
    self.title = @"强强分";

    
    [self creatWebview];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self getUserInfo];
}




- (void)getUserInfo {
    
    SendAuthReq *req = [[SendAuthReq alloc]init];
    req.scope = @"snsapi_userinfo";
    req.openID = @"wxf539a3b14221c6fa";
    
    [WXApi sendReq:req];
}




//请求
- (void)postMessageWithDic:(NSDictionary *)dicData {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer= [AFHTTPRequestSerializer serializer];

    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    dic[@"openid"] = self.openid;
    dic[@"nickname"] = dicData[@"nickname"];
    dic[@"sex"] = dicData[@"sex"];
    dic[@"province"] = dicData[@"province"];
    dic[@"city"] = dicData[@"city"];
    dic[@"country"] = dicData[@"country"];
    dic[@"headimgurl"] = dicData[@"headimgurl"];

    
    [manager GET:login parameters:dic progress:^(NSProgress * _Nonnull downloadProgress) {
        
    }
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             NSString *urlString = [NSString stringWithFormat:@"%@?token=%@", webUrl, self.openid];
             NSURL *url = [NSURL URLWithString:urlString];
             NSURLRequest *request =[NSURLRequest requestWithURL:url];
             [self.webview loadRequest:request];
         }
     
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull   error) {
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             NSLog(@"%@",error);  //这里打印错误信息
             
         }];
}

-(void)getAccess_tokenWithString {
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString *code = [[NSUserDefaults standardUserDefaults] objectForKey:@"code"];

    
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code",APPID,APPSECRET, code];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *zoneUrl = [NSURL URLWithString:url];
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                self.token = [dic objectForKey:@"access_token"];
                self.openid = [dic objectForKey:@"openid"];
                [self getUserInfoweixin];
            }
        });
    });
}


-(void)getUserInfoweixin {
    
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@",self.token,self.openid];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *zoneUrl = [NSURL URLWithString:url];
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                self.userInfoDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                [self postMessageWithDic:self.userInfoDic];
            }
        });
        
    });
}

#pragma mark- webView 代理

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self resetLeftBarButtonItem];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self resetLeftBarButtonItem];
}



#pragma mark- UI
- (void)creatWebview {
    //    self.webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height - 20)];
    self.webview = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webview.backgroundColor = [UIColor whiteColor];
    self.webview.delegate = self;
    self.webview.scrollView.bounces = NO;
    [self.view addSubview:self.webview];
}

- (void)resetLeftBarButtonItem {
    UIImage *image;
    if ([self.webview canGoBack]) {
        image = [UIImage imageNamed:@"back"];
    } else {
        image = nil;
    }
    
    UIBarButtonItem *navLeftButton = [[UIBarButtonItem alloc] initWithImage:image
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(leftButtonAction)];
    [self.navigationItem setLeftBarButtonItems:@[navLeftButton]];
}

- (void)leftButtonAction {
    [self.webview goBack];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end









