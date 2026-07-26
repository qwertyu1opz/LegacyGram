#ifndef TG_LEGACY_TL_TLCONTACTS_RESOLVEDPEER_H
#define TG_LEGACY_TL_TLCONTACTS_RESOLVEDPEER_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLPeer;

@interface TLcontacts_ResolvedPeer : NSObject <TLObject>

@property (nonatomic, retain) TLPeer *peer;
@property (nonatomic, retain) NSArray *chats;
@property (nonatomic, retain) NSArray *users;

@end

@interface TLcontacts_ResolvedPeer$contacts_resolvedPeer : TLcontacts_ResolvedPeer


@end

#endif
