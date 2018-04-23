//
//  FlyingWordPressView.m
//  FlyingWordPress
//
//  Created by Gergely on 22/04/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

#import "FlyingWordPressView.h"
#import "LogoLayer.h"

@implementation FlyingWordPressView
{
	NSImage *logoImage;
	
	NSMutableArray *logoArray;
	NSUInteger maximumNumberOfLogos;
	
	CGFloat spreadFactor;
	
	CGFloat logoStartingSizeMultiplier;
	CGFloat logoEndingSizeMultiplier;
}

- (instancetype) initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
		logoArray = [NSMutableArray arrayWithCapacity:maximumNumberOfLogos];
		maximumNumberOfLogos = 100;
		
		spreadFactor = 0.15;
		
		logoStartingSizeMultiplier = 0.1;
		logoEndingSizeMultiplier = 0.8;
		
        [self setAnimationTimeInterval:1/60.0];
		
		// Load WordPress image from bundle
		// First find "WordPressLogo.png" in screensaver's bundle
		NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:@"WordPressLogo" ofType:@"png"];
		if (path) {
			// File exists and found -> load it's contents to NSData
			NSData *imageData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
			if (imageData) {
				logoImage = [[NSImage alloc] initWithData:imageData];
			}
		}
    }
    return self;
}

- (void) viewDidMoveToWindow
{
	// Create main CALayer displaying additional layers (floating logos)
	CALayer *mainLayer = [CALayer layer];
	self.layer = mainLayer;
	
	// As initially ScreenSaverView didn't have any backing CALayer, it have wantsLayer turned off
	// We just added backing layer and want to be used by our view, so we need to turn on wantsLayer property
	self.wantsLayer = YES;
	
	// Set background to black
	mainLayer.backgroundColor = [NSColor blackColor].CGColor;
	
	// Set layer size (fullscreen)
	mainLayer.frame = self.frame;
	
	// Set starting and ending scale factors for logos
	if (logoImage) {
		CGFloat neededStartWidth = self.frame.size.width / 100.0;
		CGFloat neededEndWidth = self.frame.size.width / 8.0;
		
		logoStartingSizeMultiplier = neededStartWidth / logoImage.size.width;
		logoEndingSizeMultiplier = neededEndWidth / logoImage.size.width;
	}

	[self startRandomizedLogoGenerating];
}

- (void) startAnimation
{
    [super startAnimation];
}

- (void) stopAnimation
{
	for (LogoLayer *logo in logoArray) {
		[logo removeAllAnimations];
	}
    [super stopAnimation];
}

- (void) drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void) animateOneFrame
{
    return;
}

- (BOOL) hasConfigureSheet
{
    return NO;
}

- (NSWindow*) configureSheet
{
    return nil;
}

- (NSTimeInterval) randomTimeInterval
{
	NSTimeInterval interval = (arc4random_uniform(45) + 5);
	return interval / 1000;
}

#pragma mark - Logo management

- (void) startRandomizedLogoGenerating
{
	[NSTimer scheduledTimerWithTimeInterval:[self randomTimeInterval]
									 target:self
								   selector:@selector(randomizeNewLogo)
								   userInfo:nil
									repeats:NO];
}

- (void) randomizeNewLogo
{
	if (logoArray.count < maximumNumberOfLogos) {
		CGSize startFrameSize = CGSizeMake(self.frame.size.width * 0.5,
										   self.frame.size.height * 0.5);
		CGRect startFrame = CGRectMake((self.frame.size.width - startFrameSize.width) / 2,
									   (self.frame.size.height - startFrameSize.height) / 2,
									   startFrameSize.width,
									   startFrameSize.height);
		
		// Generate random position for logo
		CGFloat xPos = arc4random() % (UInt32)startFrame.size.width;
		CGFloat yPos = arc4random() % (UInt32)startFrame.size.height;
		
		// Create new logo
		LogoLayer *logo = [self generateNewLogoAtPosition:CGPointMake(startFrame.origin.x + xPos, startFrame.origin.y + yPos)];
		if (!logo) {
			NSLog(@"ERROR: Couldn't generate flying logos");
			return;
		}
		
		[logoArray addObject:logo];
#if DEBUG
		NSLog(@"DEBUG: %lu logos", (unsigned long)logoArray.count);
#endif
	}
	// Tick timer
	[NSTimer scheduledTimerWithTimeInterval:[self randomTimeInterval]
									 target:self
								   selector:@selector(randomizeNewLogo)
								   userInfo:nil
									repeats:NO];
}

- (LogoLayer*) generateNewLogoAtPosition:(CGPoint)startPosition
{
	if (!logoImage) { return nil; }
	
	// Generate random flat colour
	CGFloat hue = (CGFloat)(arc4random() % 256) / 256.0;				//  0.0 to 1.0
	CGFloat saturation = ((CGFloat)(arc4random() % 128) / 256.0) + 0.5;	//  0.5 to 1.0, away from white
	CGFloat brightness = ((CGFloat)(arc4random() % 128) / 256.0) + 0.5;	//  0.5 to 1.0, away from black
	NSColor *randomColor = [NSColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0];
	
	// Count end position
	CGPoint centerPosition = CGPointMake(self.frame.origin.x + self.frame.size.width/2,
										 self.frame.origin.y + self.frame.size.height/2);
	CGPoint diffPosition = CGPointMake(startPosition.x - centerPosition.x,
									   startPosition.y - centerPosition.y);
	CGPoint endPosition = CGPointMake(centerPosition.x + diffPosition.x/spreadFactor,
									  centerPosition.y + diffPosition.y/spreadFactor);
	
	// Create new logo with this colour
	LogoLayer *newLogo = [[LogoLayer alloc] initWithImage:logoImage tintedToColor:randomColor];
	newLogo.position = startPosition;
	
	[newLogo setScaleAnimationFromScale:logoStartingSizeMultiplier toScale:logoEndingSizeMultiplier];
	[newLogo setMovementAnimationFromPosition:startPosition toPosition:endPosition];
	
	// Add to layer and start animating
	[self.layer addSublayer:newLogo];
	
	newLogo.logoDelegate = self;
	[newLogo animate];
	
	return newLogo;
}

#pragma mark - LogoLayer delegate method

- (void) logoShouldBeRemoved:(LogoLayer *)logo
{
	[logoArray removeObject:logo];
	[logo removeFromSuperlayer];
}

@end
