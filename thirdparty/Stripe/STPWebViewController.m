//
//  STPWebViewController.m
//  Stripe
//
//  Created by Brian Dorfman on 9/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPWebViewController.h"
#import "../../submodules/LegacyComponents/WebKit/WKWebView.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPWebViewController ()
@property (nonatomic, strong) NSURL *url;
@end

@implementation STPWebViewController

- (instancetype)initWithURL:(NSURL *)url title:(NSString *)title {
    self = [super init];
    if (self) {
        _url = url;
        self.navigationItem.title = title;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
 
    CGRect frame = CGRectMake(0, 
                              0.0f, 
                              CGRectGetWidth(self.view.frame), 
                              CGRectGetHeight(self.view.frame) - 0.0f - 0.0f);
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:frame];
    [self.view addSubview:webView];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

@end

NS_ASSUME_NONNULL_END
