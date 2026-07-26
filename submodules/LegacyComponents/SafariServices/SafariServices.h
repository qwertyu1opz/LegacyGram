#import <UIKit/UIKit.h>

@class SFSafariViewController;

@protocol SFSafariViewControllerDelegate <NSObject>
@optional
- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller;
@end

@interface SFSafariViewController : UIViewController
@property (nonatomic, weak) id<SFSafariViewControllerDelegate> delegate;
- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithURL:(NSURL *)URL entersReaderIfAvailable:(BOOL)entersReaderIfAvailable;
- (NSArray *)previewActionItems;
@end
