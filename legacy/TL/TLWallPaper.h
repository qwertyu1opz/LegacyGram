#ifndef TG_LEGACY_TL_TLWALLPAPER_H
#define TG_LEGACY_TL_TLWALLPAPER_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLWallPaper : NSObject <TLObject>

@property (nonatomic) int32_t n_id;
@property (nonatomic, retain) NSString *title;
@property (nonatomic) int32_t color;

@end

@interface TLWallPaper$wallPaper : TLWallPaper

@property (nonatomic, retain) NSArray *sizes;

@end

@interface TLWallPaper$wallPaperSolid : TLWallPaper

@property (nonatomic) int32_t bg_color;

@end

#endif
