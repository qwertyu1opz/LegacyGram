#ifndef TG_LEGACY_TL_TLINPUTSTICKEREDMEDIA_H
#define TG_LEGACY_TL_TLINPUTSTICKEREDMEDIA_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPhoto;
@class TLInputDocument;

@interface TLInputStickeredMedia : NSObject <TLObject>


@end

@interface TLInputStickeredMedia$inputStickeredMediaPhoto : TLInputStickeredMedia

@property (nonatomic, retain) TLInputPhoto *n_id;

@end

@interface TLInputStickeredMedia$inputStickeredMediaDocument : TLInputStickeredMedia

@property (nonatomic, retain) TLInputDocument *n_id;

@end

#endif
