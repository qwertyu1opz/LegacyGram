#ifndef TG_LEGACY_TL_TLHELP_APPPREFS_H
#define TG_LEGACY_TL_TLHELP_APPPREFS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLhelp_AppPrefs : NSObject <TLObject>

@property (nonatomic, retain) NSData *bytes;

@end

@interface TLhelp_AppPrefs$help_appPrefs : TLhelp_AppPrefs


@end

#endif
