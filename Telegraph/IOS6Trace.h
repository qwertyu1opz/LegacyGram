#import <Foundation/Foundation.h>
#import <stdarg.h>

#ifndef IOS6_FULL_TRACE_ENABLED
#define IOS6_FULL_TRACE_ENABLED 0
#endif

static inline NSString *IOS6TraceLogPath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
    NSString *documentsPath = paths.count == 0 ? NSTemporaryDirectory() : [paths objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:@"ios6-full-trace.log"];
}

static inline NSString *IOS6TraceSanitize(NSString *string)
{
    if (string == nil)
        return @"(null)";
    
    NSMutableString *result = [[NSMutableString alloc] initWithString:string];
    [result replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, result.length)];
    return result;
}

static inline void IOS6Trace(NSString *format, ...)
{
#if IOS6_FULL_TRACE_ENABLED
    if (format == nil)
        return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *line = [[NSString alloc] initWithFormat:@"%@ %@\n", [formatter stringFromDate:[NSDate date]], IOS6TraceSanitize(message)];
    
    NSLog(@"%@", IOS6TraceSanitize(message));
    
    @synchronized([NSFileHandle class])
    {
        NSString *path = IOS6TraceLogPath();
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path])
            [fileManager createFileAtPath:path contents:nil attributes:nil];
        
        NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];
        [file seekToEndOfFile];
        [file writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [file closeFile];
    }
#else
    (void)format;
#endif
}

static inline void IOS6TraceSeparator(NSString *label)
{
    IOS6Trace(@"IOS6FULL ===== %@ ===== log=%@", label == nil ? @"" : label, IOS6TraceLogPath());
}
