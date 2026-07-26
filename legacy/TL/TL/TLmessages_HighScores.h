#ifndef TG_LEGACY_TL_TLMESSAGES_HIGHSCORES_H
#define TG_LEGACY_TL_TLMESSAGES_HIGHSCORES_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLmessages_HighScores : NSObject <TLObject>

@property (nonatomic, retain) NSArray *scores;
@property (nonatomic, retain) NSArray *users;

@end

@interface TLmessages_HighScores$messages_highScores : TLmessages_HighScores


@end

#endif
