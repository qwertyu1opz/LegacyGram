#import "SSignal.h"

#import "SQueue.h"
#import "SThreadPool.h"

@interface SSignal (Dispatch)

- (SSignal *)deliverOn:(SQueue *)queue;
- (SSignal *)deliverOnThreadPool:(SThreadPool *)threadPool;
- (SSignal *)startOn:(SQueue *)queue;
- (SSignal *)startOnThreadPool:(SThreadPool *)threadPool;
- (SSignal *)throttleOn:(SQueue *)queue delay:(NSTimeInterval)delay;

@end
