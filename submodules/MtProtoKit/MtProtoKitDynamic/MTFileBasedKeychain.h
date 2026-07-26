#import <Foundation/Foundation.h>

#if defined(MtProtoKitDynamicFramework)
#   import <MTProtoKitDynamic/MTKeychain.h>
#elif defined(MtProtoKitMacFramework)
#   import <MTProtoKitMac/MTKeychain.h>
#else
#   import <MTProtoKit/MTKeychain.h>
#endif

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#endif

#ifndef NS_ASSUME_NONNULL_END
#define NS_ASSUME_NONNULL_END
#endif

NS_ASSUME_NONNULL_BEGIN

@interface MTFileBasedKeychain : NSObject <MTKeychain>

+ (instancetype)unencryptedKeychainWithName:(NSString * )name documentsPath:(NSString *)documentsPath;
+ (instancetype)keychainWithName:(NSString * )name documentsPath:(NSString * )documentsPath;

- (NSDictionary *)contentsForGroup:(NSString *)group;

@end

NS_ASSUME_NONNULL_END
