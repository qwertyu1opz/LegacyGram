

#import "MTLogging.h"

static void (*loggingFunction)(NSString *, va_list args) = NULL;
static BOOL MTLogEnabledValue = true;

BOOL MTLogEnabled() {
    return loggingFunction != NULL && MTLogEnabledValue;
}

void MTLog(NSString *format, ...) {
    va_list L;
    va_start(L, format);
    if (loggingFunction != NULL) {
        loggingFunction(format, L);
    }
    va_end(L);
}

void MTLogSetLoggingFunction(void (*function)(NSString *, va_list args)) {
    loggingFunction = function;
}

void MTLogSetEnabled(BOOL enabled) {
    MTLogEnabledValue = enabled;
}
