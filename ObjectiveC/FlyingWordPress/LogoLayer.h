//
//  LogoLayer.h
//  FlyingWordPress
//
//  Created by Gergely on 22/04/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class LogoLayer;

@protocol LogoLayerDelegate

- (void) logoShouldBeRemoved:(LogoLayer*)logo;

@end

@interface LogoLayer : CALayer <CAAnimationDelegate>

@property id<LogoLayerDelegate> logoDelegate;

@property (readonly) CABasicAnimation *scaleAnimation;
@property (readonly) CABasicAnimation *zposAnimation;
@property (readonly) CABasicAnimation *moveAnimation;

- (instancetype) initWithImage:(NSImage*)image tintedToColor:(NSColor*)tintColor;

- (void) setScaleAnimationFromScale:(CGFloat)fromScale toScale:(CGFloat)toScale;
- (void) setMovementAnimationFromPosition:(CGPoint)fromPosition toPosition:(CGPoint)toPosition;
- (void) animate;

@end
