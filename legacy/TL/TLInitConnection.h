#ifndef TG_LEGACY_TL_TLINITCONNECTION_H
#define TG_LEGACY_TL_TLINITCONNECTION_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLInitConnection : NSObject <TLObject>

@property (nonatomic) int32_t api_id;
@property (nonatomic, retain) NSString *device_model;
@property (nonatomic, retain) NSString *system_version;
@property (nonatomic, retain) NSString *app_version;
@property (nonatomic, retain) NSString *lang_code;
@property (nonatomic) id<NSObject> query;

@end

@interface TLInitConnection$initConnection : TLInitConnection


@end

#endif
