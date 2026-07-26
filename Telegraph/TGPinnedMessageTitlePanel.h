#import "TGModernConversationTitlePanel.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMenuSheetButtonItemView.h"

@class TGMessage;

@interface TGPinnedMessageTitlePanel : TGModernConversationTitlePanel

@property (nonatomic, readonly) TGMessage *message;
@property (nonatomic, copy) void (^dismiss)();
@property (nonatomic, copy) void (^tapped)();

- (instancetype)initWithMessage:(TGMessage *)message;

- (void)updateMessage:(TGMessage *)message;
- (void)setMessageCount:(NSUInteger)messageCount;

@end

@interface TGPinnedMessagesMenuHeaderItemView : TGMenuSheetItemView

- (instancetype)initWithMessageCount:(NSUInteger)messageCount;

@end

@interface TGPinnedMessageMenuItemView : TGMenuSheetButtonItemView

- (instancetype)initWithTitle:(NSString *)title index:(NSUInteger)index action:(void (^)(void))action;

@end
