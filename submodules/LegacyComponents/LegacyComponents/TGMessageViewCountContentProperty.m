#import "TGMessageViewCountContentProperty.h"

#import "PSKeyValueCoder.h"

@implementation TGMessageViewCountContentProperty

- (instancetype)initWithViewCount:(int32_t)viewCount {
    self = [super init];
    if (self != nil) {
        _viewCount = viewCount;
    }
    return self;
}

- (instancetype)initWithKeyValueCoder:(PSKeyValueCoder *)coder {
    return [self initWithViewCount:[coder decodeInt32ForCKey:"vc"]];
}

- (void)encodeWithKeyValueCoder:(PSKeyValueCoder *)coder {
    [coder encodeInt32:_viewCount forCKey:"vc"];
}

@end


@implementation TGMessageEditDateContentProperty

- (instancetype)initWithEditDate:(NSTimeInterval)editDate {
    self = [super init];
    if (self != nil) {
        _editDate = editDate;
    }
    return self;
}

- (instancetype)initWithKeyValueCoder:(PSKeyValueCoder *)coder {
    return [self initWithEditDate:[coder decodeDoubleForCKey:"ed"]];
}

- (void)encodeWithKeyValueCoder:(PSKeyValueCoder *)coder {
    [coder encodeDouble:_editDate forCKey:"ed"];
}

@end

@implementation TGMessageGroupedIdContentProperty

- (instancetype)initWithGroupedId:(int64_t)groupedId {
    self = [super init];
    if (self != nil) {
        _groupedId = groupedId;
    }
    return self;
}

- (instancetype)initWithKeyValueCoder:(PSKeyValueCoder *)coder {
    return [self initWithGroupedId:[coder decodeInt64ForCKey:"gi"]];
}

- (void)encodeWithKeyValueCoder:(PSKeyValueCoder *)coder {
    [coder encodeInt64:_groupedId forCKey:"gi"];
}

@end

@implementation TGMessageReactionSummaryContentProperty

- (instancetype)initWithSummary:(NSString *)summary {
    return [self initWithSummary:summary chosenReaction:nil];
}

- (instancetype)initWithSummary:(NSString *)summary chosenReaction:(NSString *)chosenReaction {
    self = [super init];
    if (self != nil) {
        _summary = [summary copy];
        _chosenReaction = [chosenReaction copy];
    }
    return self;
}

- (instancetype)initWithKeyValueCoder:(PSKeyValueCoder *)coder {
    return [self initWithSummary:[coder decodeStringForCKey:"rs"] chosenReaction:[coder decodeStringForCKey:"rc"]];
}

- (void)encodeWithKeyValueCoder:(PSKeyValueCoder *)coder {
    [coder encodeString:_summary ?: @"" forCKey:"rs"];
    [coder encodeString:_chosenReaction ?: @"" forCKey:"rc"];
}

@end
