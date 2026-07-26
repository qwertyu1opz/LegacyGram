#import "TGModernConversationAssociatedInputPanel.h"

#import "../../../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGModernConversationHashtagsAssociatedPanel : TGModernConversationAssociatedInputPanel

@property (nonatomic, copy) void (^hashtagSelected)(NSString *);

- (void)setHashtagListSignal:(SSignal *)hashtagListSignal;

@end
