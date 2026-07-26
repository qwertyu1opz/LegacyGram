#ifndef TG_LEGACY_TL_TLCONTACTS_FOUND_H
#define TG_LEGACY_TL_TLCONTACTS_FOUND_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLcontacts_Found : NSObject <TLObject>

@property (nonatomic, retain) NSArray *my_results;
@property (nonatomic, retain) NSArray *results;
@property (nonatomic, retain) NSArray *chats;
@property (nonatomic, retain) NSArray *users;

@end

@interface TLcontacts_Found$contacts_found : TLcontacts_Found


@end

#endif
