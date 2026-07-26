#import "TLMessage.h"

@class TLReplyMarkup;
@class TLPeer;
@class TLMessageFwdHeader;

@interface TLMessage$modernMessage : TLMessage$messageMeta

@property (nonatomic, strong) NSString *reactionSummary;
@property (nonatomic, strong) NSString *chosenReaction;

@end
