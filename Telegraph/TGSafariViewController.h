#import "../submodules/LegacyComponents/SafariServices/SafariServices.h"

@interface TGSafariViewController : SFSafariViewController

@property (nonatomic, copy) NSArray *(^externalPreviewActionItems)(void);

@end
