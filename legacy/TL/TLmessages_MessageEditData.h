#ifndef TG_LEGACY_TL_TLMESSAGES_MESSAGEEDITDATA_H
#define TG_LEGACY_TL_TLMESSAGES_MESSAGEEDITDATA_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLmessages_MessageEditData : NSObject <TLObject>

@property (nonatomic) int32_t flags;

@end

@interface TLmessages_MessageEditData$messages_messageEditData : TLmessages_MessageEditData


@end

#endif
