#import <Foundation/Foundation.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@class TGMediaOriginInfo;

@interface TGAudioMediaAttachment (TG)

@property (nonatomic, strong) TGMediaOriginInfo *ios6OriginInfo;

- (NSString *)localFilePath;
 
+ (NSString *)localAudioFileDirectoryForLocalAudioId:(int64_t)audioId;
+ (NSString *)localAudioFileDirectoryForRemoteAudioId:(int64_t)audioId;
+ (NSString *)localAudioFilePathForLocalAudioId:(int64_t)audioId;
+ (NSString *)localAudioFilePathForRemoteAudioId:(int64_t)audioId;

@end
