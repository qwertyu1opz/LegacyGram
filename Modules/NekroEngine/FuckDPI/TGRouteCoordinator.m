#import "TGRouteCoordinator.h"

#import <spawn.h>
#import <sys/wait.h>
#import <signal.h>
#import <unistd.h>

static NSString *TGEnginePath(void)
{
    NSString *bundled = [[NSBundle mainBundle] pathForResource:@"FuckDPID" ofType:nil];
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:bundled])
        return bundled;

    // Migration path for development builds. It will be removed when FuckDPID
    // is packaged and installed from the LegacyGram bundle.
    return @"/usr/bin/nekrowarp";
}

@implementation TGRouteCoordinator

- (void)emit:(TGRouteState)state message:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.stateChanged != nil)
            self.stateChanged(state, message);
    });
}

- (int)runArguments:(NSArray *)arguments
{
    NSString *path = TGEnginePath();
    NSUInteger count = [arguments count] + 1;
    char **argv = calloc(count + 1, sizeof(char *));
    argv[0] = strdup([path fileSystemRepresentation]);
    for (NSUInteger i = 0; i < [arguments count]; i++)
        argv[i + 1] = strdup([[arguments objectAtIndex:i] UTF8String]);

    pid_t pid = 0;
    int result = posix_spawn(&pid, [path fileSystemRepresentation], NULL, NULL, argv, NULL);
    if (result == 0)
    {
        int status = 0;
        if (waitpid(pid, &status, 0) == pid && WIFEXITED(status))
            result = WEXITSTATUS(status);
        else
            result = -1;
    }

    for (NSUInteger i = 0; i < count; i++)
        free(argv[i]);
    free(argv);
    return result;
}

- (void)refreshState
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int result = [self runArguments:[NSArray arrayWithObject:@"netcheck"]];
        if (result == 0)
            [self emit:TGRouteStateConnected message:@"Telegram работает через WARP"];
        else
            [self emit:TGRouteStateDisabled message:@"Выключено"];
    });
}

- (NSDictionary *)profileAtPath:(NSString *)path
{
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (text == nil)
        return nil;

    NSMutableDictionary *profile = [NSMutableDictionary dictionary];
    NSCharacterSet *trim = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSString *rawLine in [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]])
    {
        NSString *line = [rawLine stringByTrimmingCharactersInSet:trim];
        if ([line length] == 0 || [line hasPrefix:@"#"] || [line hasPrefix:@";"] || [line hasPrefix:@"["])
            continue;

        NSRange equals = [line rangeOfString:@"="];
        if (equals.location == NSNotFound)
            continue;

        NSString *key = [[[line substringToIndex:equals.location] stringByTrimmingCharactersInSet:trim] lowercaseString];
        NSString *value = [[line substringFromIndex:equals.location + 1] stringByTrimmingCharactersInSet:trim];
        if ([value length] != 0)
            [profile setObject:value forKey:key];
    }
    return profile;
}

- (NSArray *)bundledProfiles
{
    NSArray *names = [NSArray arrayWithObjects:@"WARP_STR1606", @"WARP_STR4718", @"WARP_STR7521", @"WARP_STR8986", @"WARP_STR9433", nil];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *name in names)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"conf"];
        NSDictionary *profile = path == nil ? nil : [self profileAtPath:path];
        if (profile != nil)
            [result addObject:profile];
    }
    return result;
}

- (NSArray *)argumentsForProfile:(NSDictionary *)profile
{
    NSString *endpoint = [profile objectForKey:@"endpoint"];
    NSString *host = endpoint;
    NSString *port = @"4500";
    NSRange colon = [endpoint rangeOfString:@":" options:NSBackwardsSearch];
    if (colon.location != NSNotFound)
    {
        host = [endpoint substringToIndex:colon.location];
        port = [endpoint substringFromIndex:colon.location + 1];
    }

    NSString *address = [profile objectForKey:@"address"];
    NSArray *addresses = [address componentsSeparatedByString:@","];
    NSString *ipv4 = @"172.16.0.2";
    NSString *ipv6 = @"";
    for (NSString *rawAddress in addresses)
    {
        NSString *one = [rawAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSRange slash = [one rangeOfString:@"/"];
        if (slash.location != NSNotFound)
            one = [one substringToIndex:slash.location];
        if ([one rangeOfString:@":"].location == NSNotFound)
            ipv4 = one;
        else
            ipv6 = one;
    }

    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:
        @"warp-tunnel",
        host ?: @"engage.cloudflareclient.com",
        port,
        [profile objectForKey:@"privatekey"] ?: @"",
        [profile objectForKey:@"publickey"] ?: @"",
        ipv4,
        ipv6,
        [profile objectForKey:@"dns"] ?: @"1.1.1.1,8.8.8.8",
        [profile objectForKey:@"reserved"] ?: @"AAAA",
        [profile objectForKey:@"mtu"] ?: @"1280",
        [profile objectForKey:@"persistentkeepalive"] ?: @"25",
        nil];

    NSString *psk = [profile objectForKey:@"presharedkey"];
    if ([psk length] != 0)
        [arguments addObject:[NSString stringWithFormat:@"psk=%@", psk]];
    NSString *allowed = [profile objectForKey:@"allowedips"];
    if ([allowed length] != 0)
        [arguments addObject:[NSString stringWithFormat:@"allowedips=%@", allowed]];

    NSArray *awgKeys = [NSArray arrayWithObjects:@"jc", @"jmin", @"jmax", @"s1", @"s2", @"s3", @"s4",
        @"h1", @"h2", @"h3", @"h4", @"i1", @"i2", @"i3", @"i4", @"i5", nil];
    for (NSString *key in awgKeys)
    {
        NSString *value = [profile objectForKey:key];
        if ([value length] != 0)
            [arguments addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }

    [arguments addObject:@"routeguard=1"];
    [arguments addObject:@"bindwarp=1"];
    [arguments addObject:@"kpatch=1"];
    [arguments addObject:@"surgery=1"];
    return arguments;
}

- (void)enable
{
    [self emit:TGRouteStateSearching message:@"Подбираем рабочий маршрут…"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *profiles = [self bundledProfiles];
        NSUInteger index = 0;
        for (NSDictionary *profile in profiles)
        {
            index++;
            [self emit:TGRouteStateConnecting
                message:[NSString stringWithFormat:@"Проверяем маршрут %lu из %lu…",
                    (unsigned long)index, (unsigned long)[profiles count]]];

            [self runArguments:[NSArray arrayWithObject:@"stop"]];
            if ([self runArguments:[self argumentsForProfile:profile]] != 0)
                continue;

            sleep(4);
            if ([self runArguments:[NSArray arrayWithObject:@"netcheck"]] == 0)
            {
                [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)index - 1 forKey:@"FuckDPIWorkingProfile"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self emit:TGRouteStateConnected message:@"Telegram работает через WARP"];
                return;
            }
        }

        [self runArguments:[NSArray arrayWithObject:@"stop"]];
        [self emit:TGRouteStateFailed message:@"Рабочий WARP-профиль не найден"];
    });
}

- (void)disable
{
    [self emit:TGRouteStateConnecting message:@"Отключаем маршрут…"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self runArguments:[NSArray arrayWithObject:@"stop"]];
        [self emit:TGRouteStateDisabled message:@"Выключено"];
    });
}

@end
