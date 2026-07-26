#ifndef TG_LEGACY_TL_TLEXPORTEDCHATINVITE_H
#define TG_LEGACY_TL_TLEXPORTEDCHATINVITE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLExportedChatInvite : NSObject <TLObject>


@end

@interface TLExportedChatInvite$chatInviteEmpty : TLExportedChatInvite


@end

@interface TLExportedChatInvite$chatInviteExported : TLExportedChatInvite

@property (nonatomic, retain) NSString *link;

@end

#endif
