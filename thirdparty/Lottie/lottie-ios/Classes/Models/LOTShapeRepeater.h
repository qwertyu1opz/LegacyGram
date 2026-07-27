#import "../LOTXcode46Compat.h"
//
//  LOTShapeRepeater.h
//  Lottie
//
//  Created by brandon_withrow on 7/28/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LOTKeyframe.h"



@interface LOTShapeRepeater : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) LOTKeyframeGroup *copies;
@property (nonatomic, readonly) LOTKeyframeGroup *offset;
@property (nonatomic, readonly) LOTKeyframeGroup *anchorPoint;
@property (nonatomic, readonly) LOTKeyframeGroup *scale;
@property (nonatomic, readonly) LOTKeyframeGroup *position;
@property (nonatomic, readonly) LOTKeyframeGroup *rotation;
@property (nonatomic, readonly) LOTKeyframeGroup *startOpacity;
@property (nonatomic, readonly) LOTKeyframeGroup *endOpacity;

@end


