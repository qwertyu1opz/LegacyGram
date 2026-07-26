#ifndef TG_LEGACY_TL_TLCONTACTREQUEST_H
#define TG_LEGACY_TL_TLCONTACTREQUEST_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLContactRequest : NSObject <TLObject>

@property (nonatomic) int32_t user_id;
@property (nonatomic) int32_t date;

@end

@interface TLContactRequest$contactRequest : TLContactRequest


@end

#endif
