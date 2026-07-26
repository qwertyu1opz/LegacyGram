#ifndef TG_LEGACY_TL_TLSECUREPLAINDATA_H
#define TG_LEGACY_TL_TLSECUREPLAINDATA_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLSecurePlainData : NSObject <TLObject>

@end

@interface TLSecurePlainData$securePlainPhone : TLSecurePlainData

@property (nonatomic, retain) NSString *phone;

@end

@interface TLSecurePlainData$securePlainEmail : TLSecurePlainData

@property (nonatomic, retain) NSString *email;

@end

#endif
