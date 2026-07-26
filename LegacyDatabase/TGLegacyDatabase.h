#import <Foundation/Foundation.h>

@class TGLegacyUser;
@class TGChatModel;
@class SSignal;

@interface TGLegacyDatabase : NSObject

- (instancetype)initWithPath:(NSString *)path;
//- (SSignal *)contactUsersMatchingQuery:(NSString *)query;
- (SSignal *)contactUsersMatchingPhone:(NSString *)phoneNumber;
- (NSArray *)contactUsersMatchingPhoneSync:(NSString *)phoneNumber;
- (NSArray *)topUsers;
- (NSDictionary *)unreadCountsForUsers:(NSArray *)users;

- (TGLegacyUser *)userWithIdSync:(int32_t)userId;
- (TGChatModel *)conversationWithIdSync:(int64_t)conversationId;

- (NSData *)customPropertySync:(NSString *)name;

+ (NSString *)cleanPhone:(NSString *)phone clip:(bool)clip;

@end
