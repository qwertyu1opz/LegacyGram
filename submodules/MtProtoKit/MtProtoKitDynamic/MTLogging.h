

#ifndef MTLogging_H
#define MTLogging_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

BOOL MTLogEnabled();
void MTLog(NSString *format, ...);
void MTLogSetLoggingFunction(void (*function)(NSString *, va_list args));
void MTLogSetEnabled(BOOL);

#ifdef __cplusplus
}
#endif

#endif
