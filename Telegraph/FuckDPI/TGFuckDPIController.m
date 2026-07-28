#import "TGFuckDPIController.h"

@implementation TGFuckDPIController

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        self.title = @"FuckDPI";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:17.0f];
    label.text = @"test";
    [self.view addSubview:label];
}

@end
