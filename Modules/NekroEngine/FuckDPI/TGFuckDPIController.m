#import "TGFuckDPIController.h"
#import "TGRouteCoordinator.h"

@interface TGFuckDPIController ()
{
    UISwitch *_enabledSwitch;
    UILabel *_statusLabel;
    UIActivityIndicatorView *_activityIndicator;
    TGRouteCoordinator *_coordinator;
}
@end

@implementation TGFuckDPIController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self != nil)
    {
        self.title = @"FuckDPI";
        _coordinator = [[TGRouteCoordinator alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.94f alpha:1.0f];

    __unsafe_unretained TGFuckDPIController *weakSelf = self;
    _coordinator.stateChanged = ^(TGRouteState state, NSString *message)
    {
        [weakSelf updateForState:state message:message];
    };
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_coordinator refreshState];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"ОБХОД БЛОКИРОВОК";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"LegacyGram автоматически проверит встроенные WARP-профили и выберет первый маршрут, через который доступен Telegram.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"FuckDPIMainSwitchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        _enabledSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [_enabledSwitch addTarget:self action:@selector(enabledChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = _enabledSwitch;

        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }

    cell.textLabel.text = @"Взлом РКН";
    cell.textLabel.font = [UIFont systemFontOfSize:17.0f];
    cell.detailTextLabel.text = @"Выключено";
    cell.detailTextLabel.textColor = [UIColor grayColor];
    _statusLabel = cell.detailTextLabel;

    return cell;
}

- (void)enabledChanged:(UISwitch *)sender
{
    sender.enabled = NO;
    if (sender.on)
        [_coordinator enable];
    else
        [_coordinator disable];
}

- (void)updateForState:(TGRouteState)state message:(NSString *)message
{
    if (![NSThread isMainThread])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateForState:state message:message];
        });
        return;
    }

    BOOL busy = state == TGRouteStateSearching || state == TGRouteStateConnecting;
    BOOL connected = state == TGRouteStateConnected;

    _enabledSwitch.enabled = !busy;
    _enabledSwitch.on = connected || busy;
    _statusLabel.text = message;
    _statusLabel.textColor = connected
        ? [UIColor colorWithRed:0.12f green:0.58f blue:0.24f alpha:1.0f]
        : (state == TGRouteStateFailed ? [UIColor colorWithRed:0.78f green:0.16f blue:0.16f alpha:1.0f] : [UIColor grayColor]);

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (busy)
    {
        [_activityIndicator startAnimating];
        cell.imageView.image = nil;
        cell.accessoryView = _activityIndicator;
    }
    else
    {
        [_activityIndicator stopAnimating];
        cell.accessoryView = _enabledSwitch;
    }
}

@end
