#import "TGDialogListCompanion.h"

#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"

@class TGFeed;

@interface TGFeedDialogListCompanion : TGDialogListCompanion <ASWatcher>

@property (nonatomic, strong) ASHandle *actionHandle;

- (instancetype)initWithFeed:(TGFeed *)feed;

@end
