#ifndef TG_LEGACY_TL_TLCONTACTS_SUGGESTED_H
#define TG_LEGACY_TL_TLCONTACTS_SUGGESTED_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLcontacts_Suggested : NSObject <TLObject>

@property (nonatomic, retain) NSArray *results;
@property (nonatomic, retain) NSArray *users;

@end

@interface TLcontacts_Suggested$contacts_suggested : TLcontacts_Suggested


@end

#endif
