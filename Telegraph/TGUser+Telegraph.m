#import "TGUser+Telegraph.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGSchema.h"

#import "TGDatabase.h"

#import "TGTelegraph.h"

#import "TGImageInfo+Telegraph.h"

#import "TLUser$modernUser.h"

#import "TGNotificationPrivacyAccountSetting.h"

static NSString *modernPeerPhotoUrl(int32_t dcId, int32_t peerType, int64_t peerId, int64_t accessHash, int64_t photoId, bool big)
{
    if (dcId == 0 || peerId == 0 || photoId == 0)
        return nil;
    return [[NSString alloc] initWithFormat:@"peerphoto:%d:%d:%lld:%lld:%lld:%d", dcId, peerType, peerId, accessHash, photoId, big ? 1 : 0];
}

void extractUserPhoto(TLUserProfilePhoto *photo, TGUser *target)
{
    if ([photo isKindOfClass:[TLUserProfilePhoto$userProfilePhoto class]])
    {
        TLUserProfilePhoto$userProfilePhoto *profilePhoto = (TLUserProfilePhoto$userProfilePhoto *)photo;
        if (profilePhoto.photo_id != 0 && profilePhoto.dc_id != 0)
        {
            target.photoUrlSmall = modernPeerPhotoUrl(profilePhoto.dc_id, 1, target.uid, target.phoneNumberHash, profilePhoto.photo_id, false);
            target.photoUrlMedium = nil;
            target.photoUrlBig = modernPeerPhotoUrl(profilePhoto.dc_id, 1, target.uid, target.phoneNumberHash, profilePhoto.photo_id, true);
            // High-volume success path.
            return;
        }
        target.photoUrlSmall = extractFileUrl(profilePhoto.photo_small);
        target.photoUrlMedium = nil;
        target.photoUrlBig = extractFileUrl(profilePhoto.photo_big);
        
        if ([profilePhoto.photo_small isKindOfClass:[TLFileLocation$fileLocation class]])
            target.photoFileReferenceSmall = ((TLFileLocation$fileLocation *)profilePhoto.photo_small).file_reference;
        
        if ([profilePhoto.photo_big isKindOfClass:[TLFileLocation$fileLocation class]])
            target.photoFileReferenceBig = ((TLFileLocation$fileLocation *)profilePhoto.photo_big).file_reference;
    }
    else
    {
        target.photoUrlSmall = nil;
        target.photoUrlMedium = nil;
        target.photoUrlBig = nil;
    }
}

TGUserPresence extractUserPresence(TLUserStatus *status)
{
    if ([status isKindOfClass:[TLUserStatus$userStatusOnline class]])
    {
        TGUserPresence presence;
        presence.online = true;
        presence.lastSeen = ((TLUserStatus$userStatusOnline *)status).expires;
        presence.temporaryLastSeen = 0;
        return presence;
    }
    else if ([status isKindOfClass:[TLUserStatus$userStatusOffline class]])
    {
        TGUserPresence presence;
        presence.online = false;
        presence.lastSeen = ((TLUserStatus$userStatusOffline *)status).was_online;
        presence.temporaryLastSeen = 0;
        
        return presence;
    }
    else if ([status isKindOfClass:[TLUserStatus$userStatusRecently class]])
    {
        TGUserPresence presence;
        presence.online = false;
        presence.lastSeen = TGUserPresenceValueLately;
        presence.temporaryLastSeen = 0;
        return presence;
    }
    else if ([status isKindOfClass:[TLUserStatus$userStatusLastWeek class]])
    {
        TGUserPresence presence;
        presence.online = false;
        presence.lastSeen = TGUserPresenceValueWithinAWeek;
        presence.temporaryLastSeen = 0;
        return presence;
    }
    else if ([status isKindOfClass:[TLUserStatus$userStatusLastMonth class]])
    {
        TGUserPresence presence;
        presence.online = false;
        presence.lastSeen = TGUserPresenceValueWithinAMonth;
        presence.temporaryLastSeen = 0;
        return presence;
    }
    else
    {
        TGUserPresence presence;
        presence.online = false;
        presence.lastSeen = TGUserPresenceValueALongTimeAgo;
        presence.temporaryLastSeen = 0;
        return presence;
    }
}

int extractUserLink(TLcontacts_Link *link)
{
    int value = 0;
    
    if ([link.my_link isKindOfClass:[TLContactLink$contactLinkContact class]])
        value |= TGUserLinkMyContact | TGUserLinkKnown;
    else if ([link.my_link isKindOfClass:[TLContactLink$contactLinkHasPhone class]])
        value |= TGUserLinkForeignHasPhone | TGUserLinkKnown;
    else if ([link.my_link isKindOfClass:[TLContactLink$contactLinkNone class]])
        value |= TGUserLinkKnown;
    
    if ([link.foreign_link isKindOfClass:[TLContactLink$contactLinkContact class]])
        value |= TGUserLinkForeignHasPhone | TGUserLinkKnown;
    else if ([link.foreign_link isKindOfClass:[TLContactLink$contactLinkHasPhone class]])
        value |= TGUserLinkForeignHasPhone | TGUserLinkKnown;
    else if ([link.foreign_link isKindOfClass:[TLContactLink$contactLinkNone class]])
        value |= TGUserLinkKnown;
    
    return value;
}

int extractUserLinkFromUpdate(TLUpdate$updateContactLink *linkUpdate)
{
    int value = 0;
    
    if ([linkUpdate.my_link isKindOfClass:[TLContactLink$contactLinkContact class]])
        value |= TGUserLinkMyContact | TGUserLinkKnown;
    else if ([linkUpdate.my_link isKindOfClass:[TLContactLink$contactLinkHasPhone class]])
        value |= TGUserLinkForeignHasPhone | TGUserLinkKnown;
    else if ([linkUpdate.my_link isKindOfClass:[TLContactLink$contactLinkNone class]])
        value |= TGUserLinkKnown;

    if ([linkUpdate.foreign_link isKindOfClass:[TLContactLink$contactLinkContact class]])
        value |= TGUserLinkForeignHasPhone | TGUserLinkKnown;
    else if ([linkUpdate.foreign_link isKindOfClass:[TLContactLink$contactLinkHasPhone class]])
        value |= TGUserLinkForeignHasPhone | TGUserLinkKnown;
    else if ([linkUpdate.foreign_link isKindOfClass:[TLContactLink$contactLinkNone class]])
        value |= TGUserLinkKnown;
    
    return value;
}

@implementation TGUser (Telegraph)

- (id)initWithTelegraphUserDesc:(TLUser *)user
{
    self = [self init];
    if (self != nil)
    {
        int32_t uid = 0;
        NSString *userPhone = nil;
        if ([user isKindOfClass:[TLUser$modernUser class]])
        {
            TLUser$modernUser *concreteUser = (TLUser$modernUser *)user;
            
	            uid = concreteUser.n_id;
	            self.uid = uid;
	            self.phoneNumberHash = concreteUser.access_hash;
            self.firstName = concreteUser.first_name;
            self.lastName = concreteUser.last_name;
            self.userName = concreteUser.username;
            userPhone = concreteUser.phone;
	            extractUserPhoto(concreteUser.photo, self);
	            if ([concreteUser.photo isKindOfClass:[TLUserProfilePhoto$userProfilePhoto class]])
	            {
	                TLUserProfilePhoto$userProfilePhoto *profilePhoto = (TLUserProfilePhoto$userProfilePhoto *)concreteUser.photo;
	                int64_t peerPhotoUserId = concreteUser.n_id_long != 0 ? concreteUser.n_id_long : concreteUser.n_id;
	                if (profilePhoto.photo_id != 0 && profilePhoto.dc_id != 0 && peerPhotoUserId != self.uid)
	                {
	                    self.photoUrlSmall = modernPeerPhotoUrl(profilePhoto.dc_id, 1, peerPhotoUserId, self.phoneNumberHash, profilePhoto.photo_id, false);
	                    self.photoUrlMedium = nil;
	                    self.photoUrlBig = modernPeerPhotoUrl(profilePhoto.dc_id, 1, peerPhotoUserId, self.phoneNumberHash, profilePhoto.photo_id, true);
	                }
	            }
	            self.presence = extractUserPresence(concreteUser.status);
            
            if (concreteUser.flags & (1 << 14))
                self.kind = TGUserKindBot;
            if (concreteUser.flags & (1 << 15))
                self.kind = TGUserKindSmartBot;
            self.botKind = (concreteUser.flags & (1 << 16)) ? TGBotKindPrivate : TGBotKindGeneric;
            self.botInfoVersion = concreteUser.bot_info_version;
            
            self.isVerified = concreteUser.flags & (1 << 17);
            self.hasExplicitContent = concreteUser.flags & (1 << 18);
            self.restrictionReason = concreteUser.restriction_reason;
            self.contextBotPlaceholder = concreteUser.inlineBotPlaceholder;
            self.isContextBot = concreteUser.flags & (1 << 19);
            self.minimalRepresentation = concreteUser.flags & (1 << 20);
            self.botInlineGeo = concreteUser.flags & (1 << 21);
            self.emojiStatusDocumentId = concreteUser.emojiStatusDocumentId;
        }
        else if ([user isKindOfClass:[TLUser$userEmpty class]])
        {
            uid = ((TLUser$userEmpty *)user).n_id;
            self.minimalRepresentation = true;
        }
        
        if (userPhone.length != 0)
        {
            if (![userPhone hasPrefix:@"+"])
                userPhone = [[NSString alloc] initWithFormat:@"+%@", userPhone];
            self.phoneNumber = userPhone;
        }
        
        if (uid != 0 && userPhone.length != 0)
        {   
            TGContactBinding *binding = [TGDatabaseInstance() contactBindingWithId:self.contactId];
            if (binding != nil)
            {
                if (uid != TGTelegraphInstance.clientUserId)
                {
                    self.phonebookFirstName = binding.firstName;
                    self.phonebookLastName = binding.lastName;
                }
            }
        }
    }
    return self;
}

- (TGUser *)applyPrivacyRules:(TGNotificationPrivacyAccountSetting *)privacyRules currentTime:(NSTimeInterval)currentTime
{
    if (privacyRules == nil)
        return self;
    
    bool approximatePresenceRequired = false;
    
    switch (privacyRules.lastSeenPrimarySetting)
    {
        case TGPrivacySettingsLastSeenPrimarySettingEverybody:
            if ([privacyRules.neverShareWithUserIds containsObject:@(self.uid)])
                approximatePresenceRequired = true;
            break;
        case TGPrivacySettingsLastSeenPrimarySettingContacts:
            if ([TGDatabaseInstance() uidIsRemoteContact:self.uid])
            {
                if ([privacyRules.neverShareWithUserIds containsObject:@(self.uid)])
                    approximatePresenceRequired = true;
            }
            else
            {
                if (![privacyRules.alwaysShareWithUserIds containsObject:@(self.uid)])
                    approximatePresenceRequired = true;
            }
            break;
        case TGPrivacySettingsLastSeenPrimarySettingNobody:
            if (![privacyRules.alwaysShareWithUserIds containsObject:@(self.uid)])
                approximatePresenceRequired = true;
            break;
    }
    
    if (approximatePresenceRequired)
    {
        TGUser *user = [self copy];
        user.presence = [TGUser approximatePresenceFromPresence:self.presence currentTime:currentTime];
        return user;
    }
    
    return self;
}

@end
