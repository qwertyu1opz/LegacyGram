#import "../LOTXcode46Compat.h"
//
//  LOTAnimatorNode.h
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//

#import <Foundation/Foundation.h>
#import "LOTPlatformCompat.h"
#import "LOTBezierPath.h"
#import "LOTKeypath.h"
#import "LOTValueDelegate.h"

extern NSInteger indentation_level;
@interface LOTAnimatorNode : NSObject

/// Initializes the node with and optional intput node and keyname.
- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                                    keyName:(NSString *)keyname;

/// A dictionary of the value interpolators this node controls
@property (nonatomic, readonly, strong) NSDictionary *  valueInterpolators;

/// The keyname of the node. Used for dynamically setting keyframe data.
@property (nonatomic, readonly, strong) NSString *  keyname;

/// The current time in frames
@property (nonatomic, readonly, strong) NSNumber *  currentFrame;
/// The upstream animator node
@property (nonatomic, readonly, strong) LOTAnimatorNode *  inputNode;

/// This nodes path in local object space
@property (nonatomic, strong) LOTBezierPath *  localPath;
/// The sum of all paths in the tree including this node
@property (nonatomic, strong) LOTBezierPath *  outputPath;

/// Returns true if this node needs to update its contents for the given frame. To be overwritten by subclasses.
- (BOOL)needsUpdateForFrame:(NSNumber *)frame;

/// Sets the current frame and performs any updates. Returns true if any updates were performed, locally or upstream.
- (BOOL)updateWithFrame:(NSNumber *)frame;
- (BOOL)updateWithFrame:(NSNumber *)frame
      withModifierBlock:(void (^)(LOTAnimatorNode *  inputNode))modifier
       forceLocalUpdate:(BOOL)forceUpdate;

- (void)forceSetCurrentFrame:(NSNumber *)frame;

@property (nonatomic, assign) BOOL pathShouldCacheLengths;
/// Update the local content for the frame.
- (void)performLocalUpdate;

/// Rebuild all outputs for the node. This is called after upstream updates have been performed.
- (void)rebuildOutputs;

- (void)logString:(NSString *)string;

- (void)searchNodesForKeypath:(LOTKeypath * )keypath;

- (void)setValueDelegate:(id<LOTValueDelegate> )delegate
              forKeypath:(LOTKeypath * )keypath;

@end
