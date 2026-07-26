#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETDIALOGSMETA_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETDIALOGSMETA_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPeer;
@class TLmessages_Dialogs;

@interface TLRPCmessages_getDialogsMeta : TLMetaRpc

@property (nonatomic) int32_t flags;
@property (nonatomic) int32_t feed_id;
@property (nonatomic) int32_t folder_id;
@property (nonatomic) int32_t offset_date;
@property (nonatomic) int32_t offset_id;
@property (nonatomic, retain) TLInputPeer *offset_peer;
@property (nonatomic) int32_t limit;
@property (nonatomic) int64_t hash;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

#endif
