#ifndef TG_LEGACY_TL_TLCONTACTS_FOREIGNLINK_H
#define TG_LEGACY_TL_TLCONTACTS_FOREIGNLINK_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLcontacts_ForeignLink : NSObject <TLObject>


@end

@interface TLcontacts_ForeignLink$contacts_foreignLinkUnknown : TLcontacts_ForeignLink


@end

@interface TLcontacts_ForeignLink$contacts_foreignLinkRequested : TLcontacts_ForeignLink

@property (nonatomic) bool has_phone;

@end

@interface TLcontacts_ForeignLink$contacts_foreignLinkMutual : TLcontacts_ForeignLink


@end

#endif
