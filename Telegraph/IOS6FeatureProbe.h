#import <Foundation/Foundation.h>
#import <stdarg.h>

#ifndef IOS6_FEATURE_PROBE_ENABLED
#define IOS6_FEATURE_PROBE_ENABLED 0
#endif

static inline void IOS6FeatureProbe(NSString *format, ...)
{
#if IOS6_FEATURE_PROBE_ENABLED
    if (format == nil)
        return;

    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSLog(@"IOS6FEATURE %@", message);
#else
    (void)format;
#endif
}
