#ifndef TG_LEGACY_TL_TLRPCHELP_GETRECENTMEURLS_H
#define TG_LEGACY_TL_TLRPCHELP_GETRECENTMEURLS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class NSArray_string;

@interface TLRPChelp_getRecentMeUrls : TLMetaRpc

@property (nonatomic, retain) NSString *referer;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPChelp_getRecentMeUrls$help_getRecentMeUrls : TLRPChelp_getRecentMeUrls


@end

#endif
