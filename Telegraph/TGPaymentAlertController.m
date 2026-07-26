#import "TGPaymentAlertController.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGArchivedStickerPacksAlert.h"

#import "TGPaymentAlertView.h"

@interface TGPaymentAlertController : TGOverlayController {
    TGPaymentAlertView *_paymentAlertView;
}

@end

@implementation TGPaymentAlertController

- (instancetype)initWithView:(TGPaymentAlertView *)view {
    self = [super init];
    if (self != nil) {
        _paymentAlertView = view;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    _paymentAlertView.frame = self.view.bounds;
    _paymentAlertView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_paymentAlertView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_paymentAlertView animateAppear];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.view.window.layer removeAnimationForKey:@"backgroundColor"];
    [CATransaction begin];
    [CATransaction setDisableActions:true];
    self.view.window.layer.backgroundColor = [UIColor clearColor].CGColor;
    [CATransaction commit];
    
    for (UIView *view in self.view.window.subviews)
    {
        if (view != self.view)
        {
            [view removeFromSuperview];
            break;
        }
    }
}

@end

@implementation TGPaymentAlert

- (instancetype)initWithManager:(id<LegacyComponentsOverlayWindowManager>)manager parentController:(TGViewController *)parentController text:(__unused NSString *)text {
    TGPaymentAlertView *alertView = [[TGPaymentAlertView alloc] init];
    alertView.controller = parentController;
    
    self = [super initWithManager:manager parentController:parentController contentController:[[TGPaymentAlertController alloc] initWithView:alertView]];
    if (self != nil)
    {
        _view = alertView;
    }
    return self;
}

@end
