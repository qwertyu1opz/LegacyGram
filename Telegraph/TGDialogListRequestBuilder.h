/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "../submodules/LegacyComponents/LegacyComponents/ASActor.h"

#import "TL/TLMetaScheme.h"

@class SSignal;

@interface TGDialogListRequestBuilder : ASActor

+ (NSString *)genericPath;

- (void)dialogListRequestSuccess:(TLmessages_Dialogs *)dialogs;
- (void)dialogListRequestNotModified:(int32_t)count;
- (void)dialogListRequestFailed;

+ (SSignal *)signalForCompleteMessages:(NSArray *)completeMessages channels:(NSDictionary *)channels;

@end
