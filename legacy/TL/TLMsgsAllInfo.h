#ifndef TG_LEGACY_TL_TLMSGSALLINFO_H
#define TG_LEGACY_TL_TLMSGSALLINFO_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLMsgsAllInfo : NSObject <TLObject>

@property (nonatomic, retain) NSArray *msg_ids;
@property (nonatomic, retain) NSString *info;

@end

@interface TLMsgsAllInfo$msgs_all_info : TLMsgsAllInfo


@end

#endif
