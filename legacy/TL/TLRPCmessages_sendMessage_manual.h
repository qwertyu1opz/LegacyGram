#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPeer;

@interface TLRPCmessages_sendMessage_manual : TLMetaRpc

@property (nonatomic) int32_t flags;
@property (nonatomic, strong) TLInputPeer *peer;
@property (nonatomic) int32_t reply_to_msg_id;
@property (nonatomic, strong) NSString *message;
@property (nonatomic) int64_t random_id;
@property (nonatomic, strong) NSArray *entities;

@end

// Modern reactions are not part of the original layer-26 generated classes,
// so keep the small request serializer beside the existing manual message
// serializer.  The response is a regular TLUpdates object.
@interface TLRPCmessages_sendReaction_manual : TLMetaRpc

@property (nonatomic) int32_t flags;
@property (nonatomic, strong) TLInputPeer *peer;
@property (nonatomic) int32_t msg_id;
@property (nonatomic, strong) NSString *reaction;

@end

// Lightweight modern response objects used only to obtain Telegram's active
// Unicode reaction list.  Animation documents are consumed by the TL parser
// but intentionally not retained on iOS 6.
@interface TLAvailableReaction_manual : NSObject <TLObject>

@property (nonatomic) bool inactive;
@property (nonatomic) bool premium;
@property (nonatomic, strong) NSString *reaction;

@end

@interface TLmessages_AvailableReactions_manual : NSObject <TLObject>

@property (nonatomic, strong) NSArray *reactions;
@property (nonatomic, strong) NSArray *activeEmojis;

@end


@interface TLRPCmessages_getAvailableReactions_manual : TLMetaRpc

@property (nonatomic) int32_t hashValue;

@end
