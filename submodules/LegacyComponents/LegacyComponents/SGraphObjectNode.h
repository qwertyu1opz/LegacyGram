#import "SGraphNode.h"

@interface SGraphObjectNode : SGraphNode

@property (nonatomic, strong) id object;

- (id)initWithObject:(id)object;

@end
