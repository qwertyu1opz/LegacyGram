#ifndef TG_LEGACY_TL_TLPHONE_PHONECALL_H
#define TG_LEGACY_TL_TLPHONE_PHONECALL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLPhoneCall;

@interface TLphone_PhoneCall : NSObject <TLObject>

@property (nonatomic, retain) TLPhoneCall *phone_call;
@property (nonatomic, retain) NSArray *users;

@end

@interface TLphone_PhoneCall$phone_phoneCall : TLphone_PhoneCall


@end

#endif
