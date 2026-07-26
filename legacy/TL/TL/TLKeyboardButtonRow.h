#ifndef TG_LEGACY_TL_TLKEYBOARDBUTTONROW_H
#define TG_LEGACY_TL_TLKEYBOARDBUTTONROW_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLKeyboardButtonRow : NSObject <TLObject>

@property (nonatomic, retain) NSArray *buttons;

@end

@interface TLKeyboardButtonRow$keyboardButtonRow : TLKeyboardButtonRow


@end

#endif
