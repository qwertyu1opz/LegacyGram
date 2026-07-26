#ifndef TG_LEGACY_TL_TLDATAJSON_H
#define TG_LEGACY_TL_TLDATAJSON_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLDataJSON : NSObject <TLObject>

@property (nonatomic, retain) NSString *data;

@end

@interface TLDataJSON$dataJSON : TLDataJSON


@end

#endif
