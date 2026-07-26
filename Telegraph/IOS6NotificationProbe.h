#import <Foundation/Foundation.h>
#import <stdarg.h>
#import <sys/time.h>
#import <time.h>
#import <unistd.h>

// Keep the flight recorder implementation available for future diagnostics,
// but compile every call out completely during normal use.  This avoids even
// evaluating format arguments, so there are no file opens, fsyncs or hidden
// battery costs while disabled.
#define IOS6_NOTIFICATION_PROBE_ENABLED 0

// A deliberately small synchronous flight recorder for background notification
// diagnosis. Events are rare state transitions, never message bodies or packet
// dumps. Opening and closing the file for each event ensures that the final
// breadcrumb survives suspension or detaching Xcode.

#if IOS6_NOTIFICATION_PROBE_ENABLED
static inline NSString *IOS6NotificationProbeLogPath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
    NSString *documentsPath = paths.count == 0 ? NSTemporaryDirectory() : [paths objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:@"ios6-notification-probe.log"];
}

static inline void IOS6NotificationProbeWrite(NSString *stage, NSString *format, ...)
{
    if (stage.length == 0)
        return;

    @autoreleasepool
    {
        @try
        {
            NSString *details = @"";
            if (format != nil)
            {
                va_list args;
                va_start(args, format);
                NSString *formattedDetails = [[NSString alloc] initWithFormat:format arguments:args];
                va_end(args);
                details = formattedDetails ?: @"";
#if !__has_feature(objc_arc)
                [formattedDetails autorelease];
#endif
            }

            details = [details stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            details = [details stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];

            struct timeval currentTime;
            gettimeofday(&currentTime, NULL);
            struct tm timeInfo;
            localtime_r(&currentTime.tv_sec, &timeInfo);
            char dateBuffer[32] = {0};
            strftime(dateBuffer, sizeof(dateBuffer), "%Y-%m-%d %H:%M:%S", &timeInfo);
            int milliseconds = (int)(currentTime.tv_usec / 1000);
            NSTimeInterval uptime = [[NSProcessInfo processInfo] systemUptime];

            NSString *line = [NSString stringWithFormat:@"%s.%03d pid=%d up=%.1f %@ %@\n",
                              dateBuffer, milliseconds, getpid(), uptime, stage, details];
            NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
            if (data.length == 0)
                return;

            @synchronized([NSFileHandle class])
            {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSString *path = IOS6NotificationProbeLogPath();
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
                if ([[attributes objectForKey:NSFileSize] unsignedLongLongValue] > 256 * 1024)
                {
                    NSString *previousPath = [path stringByAppendingString:@".previous"];
                    [fileManager removeItemAtPath:previousPath error:nil];
                    [fileManager moveItemAtPath:path toPath:previousPath error:nil];
                }

                if (![fileManager fileExistsAtPath:path])
                    [fileManager createFileAtPath:path contents:nil attributes:nil];

                NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];
                [file seekToEndOfFile];
                [file writeData:data];
                [file synchronizeFile];
                [file closeFile];
            }
        }
        @catch (__unused NSException *exception)
        {
            // Diagnostics must never affect the client.
        }
    }
}

#define IOS6NotificationProbe(...) IOS6NotificationProbeWrite(__VA_ARGS__)
#else
#define IOS6NotificationProbe(...) do { } while (0)
#endif
