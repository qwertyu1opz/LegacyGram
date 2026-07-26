#import <Foundation/Foundation.h>
#import "PSCoding.h"

@interface TGMessageViewCountContentProperty : NSObject <PSCoding>

@property (nonatomic, readonly) int32_t viewCount;

- (instancetype)initWithViewCount:(int32_t)viewCount;

@end


@interface TGMessageEditDateContentProperty : NSObject <PSCoding>

@property (nonatomic, readonly) NSTimeInterval editDate;

- (instancetype)initWithEditDate:(NSTimeInterval)editDate;

@end


@interface TGMessageGroupedIdContentProperty : NSObject <PSCoding>

@property (nonatomic, readonly) int64_t groupedId;

- (instancetype)initWithGroupedId:(int64_t)groupedId;

@end

@interface TGMessageReactionSummaryContentProperty : NSObject <PSCoding>

@property (nonatomic, copy, readonly) NSString *summary;
@property (nonatomic, copy, readonly) NSString *chosenReaction;

- (instancetype)initWithSummary:(NSString *)summary;
- (instancetype)initWithSummary:(NSString *)summary chosenReaction:(NSString *)chosenReaction;

@end
