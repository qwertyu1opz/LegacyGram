#import "../submodules/LegacyComponents/LegacyComponents/TGModernConversationAssociatedInputPanel.h"

#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@class TGBotComandInfo;
@class TGUser;

@interface TGModernConversationCommandsAssociatedPanel : TGModernConversationAssociatedInputPanel

@property (nonatomic, copy) void (^commandSelected)(TGBotComandInfo *, TGUser *, bool);

- (void)setCommandListSignal:(SSignal *)commandListSignal;

@end
