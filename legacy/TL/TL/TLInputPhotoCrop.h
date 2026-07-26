#ifndef TG_LEGACY_TL_TLINPUTPHOTOCROP_H
#define TG_LEGACY_TL_TLINPUTPHOTOCROP_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLInputPhotoCrop : NSObject <TLObject>


@end

@interface TLInputPhotoCrop$inputPhotoCropAuto : TLInputPhotoCrop


@end

@interface TLInputPhotoCrop$inputPhotoCrop : TLInputPhotoCrop

@property (nonatomic) double crop_left;
@property (nonatomic) double crop_top;
@property (nonatomic) double crop_width;

@end

#endif
