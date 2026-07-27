#import "TLUser.h"

#import "TLUserProfilePhoto.h"
#import "TLUserStatus.h"

#ifdef __cplusplus
extern "C" {
#endif

int64_t TGModernUserIdForLegacyId(int32_t uid);
int32_t TGModernLegacyIdForModernId(int64_t modernUserId);
void TGRegisterModernUserId(int32_t uid, int64_t modernUserId);

#ifdef __cplusplus
}
#endif

@interface TLUser$modernUser : TLUser

@property (nonatomic) int32_t flags;
@property (nonatomic) int32_t n_id;
@property (nonatomic) int64_t n_id_long;
@property (nonatomic) int64_t access_hash;
@property (nonatomic, strong) NSString *first_name;
@property (nonatomic, strong) NSString *last_name;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) TLUserProfilePhoto *photo;
@property (nonatomic, strong) TLUserStatus *status;
@property (nonatomic) int32_t bot_info_version;
@property (nonatomic, strong) NSString *restriction_reason;
@property (nonatomic, strong) NSString *inlineBotPlaceholder;
@property (nonatomic) int64_t emojiStatusDocumentId;

@end
