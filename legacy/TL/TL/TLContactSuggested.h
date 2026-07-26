#ifndef TG_LEGACY_TL_TLCONTACTSUGGESTED_H
#define TG_LEGACY_TL_TLCONTACTSUGGESTED_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLContactSuggested : NSObject <TLObject>

@property (nonatomic) int32_t user_id;
@property (nonatomic) int32_t mutual_contacts;

@end

@interface TLContactSuggested$contactSuggested : TLContactSuggested


@end

#endif
