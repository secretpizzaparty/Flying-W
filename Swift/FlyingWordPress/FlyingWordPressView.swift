//
//  FlyingWordPressView.swift
//  FlyingWordPress
//
//  Created by Gergely on 19/04/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import ScreenSaver

class FlyingWordPressView: ScreenSaverView {
	
	var logoImage: NSImage?				// WordPress image
	
	var logoArray = [LogoLayer]()
	let maximumNumberOfLogos = 100
	
	let spreadFactor:CGFloat = 0.15		// at 1.0 logos won't move at all, decreasin this will move logos away from center (must be greater than 0.0)
	
	var logoStartingSizeMultiplier:CGFloat = 0.1
	var logoEndingSizeMultiplier:CGFloat = 0.8
	
	enum GeneratingError: Error {
		case imageNotLoaded
	}
	
	var randomTimeInterval:TimeInterval {
		get {
			return TimeInterval(arc4random_uniform(45) + 5) / 1000		// Between 0.005 and 0.05
		}
	}
	
	/////////////////////////////////////////////////////////////////////////
	// MARK: - Initialization
	
	override init?(frame: NSRect, isPreview: Bool) {
		super.init(frame: frame, isPreview: isPreview)
		
		self.animationTimeInterval = 1/60.0
		
		// Load WordPress image from bundle
		// First find "WordPressLogo.png" in screensaver's bundle
		if let path = Bundle(for: self.classForCoder).path(forResource: "WordPressLogo", ofType: "png") {
			
			// File exists and found -> load it's contents to NSData
			if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
				
				// Create image from data
				self.logoImage = NSImage(data: data)
			}
		}
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	/////////////////////////////////////////////////////////////////////////
	// MARK: - ScreenSaverView overrided methods
	
	override func viewDidMoveToWindow() {
		// Create main CALayer displaying additional layers (floating logos)
		let mainLayer = CALayer()
		self.layer = mainLayer
		
		// As initially ScreenSaverView didn't have any backing CALayer, it have wantsLayer turned off
		// We just added backing layer and want to be used by our view, so we need to turn on wantsLayer property
		self.wantsLayer = true
		
		// Set background to black
		mainLayer.backgroundColor = NSColor.black.cgColor
		
		// Set layer size (fullscreen)
		mainLayer.frame = self.frame
		
		// Set starting and ending scale factors for logos
		if let logo = logoImage {
			let neededStartWidth = self.frame.size.width / 100.0
			let neededEndWidth = self.frame.size.width / 8.0
			
			logoStartingSizeMultiplier = neededStartWidth / logo.size.width
			logoEndingSizeMultiplier = neededEndWidth / logo.size.width
		}
		
		startRandomizedLogoGenerating()
	}
	
	override func startAnimation() {
		super.startAnimation()
	}
	
	override func stopAnimation() {
		// ScreenSaver stopped, all animations must be removed (SystemPreferences.app will crash otherwise)
		for logo in logoArray {
			logo.removeAllAnimations()
		}
		super.stopAnimation()
	}
	
	override func animateOneFrame() {
		// This function is called before each frame displayed
	}
	
	override var hasConfigureSheet: Bool {
		get {
			return false
		}
	}
	
	override var configureSheet: NSWindow? {
		get {
			return nil
		}
	}
	
	/////////////////////////////////////////////////////////////////////////
	// MARK: - Logo management
	
	func startRandomizedLogoGenerating() {
		Timer.scheduledTimer(timeInterval: randomTimeInterval, target: self, selector: #selector(randomizeNewLogo), userInfo: nil, repeats: false)
	}
	
	@objc func randomizeNewLogo() {
		do {
			if logoArray.count < maximumNumberOfLogos {
				let startFrameSize = CGSize(width: self.frame.size.width * 0.5,
											height: self.frame.size.height * 0.5)
				let startFrame = CGRect(x: (self.frame.size.width - startFrameSize.width) / 2,
										y: (self.frame.size.height - startFrameSize.height) / 2,
										width: startFrameSize.width,
										height: startFrameSize.height)
				
				// Generate random position for logo
				let xPos = CGFloat(arc4random() % UInt32(startFrame.size.width))
				let yPos = CGFloat(arc4random() % UInt32(startFrame.size.height))
				
				// Create new logo
				let logo = try generateNewLogo(atPosition: CGPoint(x: startFrame.origin.x + xPos,
																   y: startFrame.origin.y + yPos))
				logoArray.append(logo)
#if DEBUG
				print("DEBUG: \(logoArray.count) logos")
#endif
			}
			// Tick timer
			Timer.scheduledTimer(timeInterval: randomTimeInterval, target: self, selector: #selector(randomizeNewLogo), userInfo: nil, repeats: false)
		} catch {
			print("ERROR: Couldn't generate flying logos: \(error)")
		}
	}
	
	func generateNewLogo(atPosition startPosition: CGPoint) throws -> LogoLayer {
		guard let image = logoImage else { throw GeneratingError.imageNotLoaded }
		
		// Generate random flat colour
		let hue = CGFloat(arc4random() % 256) / 256.0					//  0.0 to 1.0
		let saturation = (CGFloat(arc4random() % 128) / 256.0) + 0.5	//  0.5 to 1.0, away from white
		let brightness = (CGFloat(arc4random() % 128) / 256.0) + 0.5	//  0.5 to 1.0, away from black
		let randomColor = NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
		
		// Count end position
		let centerPosition = CGPoint(x: self.frame.origin.x + self.frame.size.width/2,
									 y: self.frame.origin.y + self.frame.size.height/2)
		let diffPosition = CGPoint(x: startPosition.x - centerPosition.x,
								   y: startPosition.y - centerPosition.y)
		let endPosition = CGPoint(x: centerPosition.x + diffPosition.x/spreadFactor,
								  y: centerPosition.y + diffPosition.y/spreadFactor)
		
		// Create new logo with this colour
		let newLogo = LogoLayer(withImage: image, tintedTo: randomColor)
		newLogo.position = startPosition
		
		newLogo.setScaleAnimation(fromScale: logoStartingSizeMultiplier, toScale: logoEndingSizeMultiplier)
		newLogo.setMovementAnimation(fromPosition: startPosition, toPosition: endPosition)
		
		// Add to layer and start animating
		self.layer?.addSublayer(newLogo)
		
		newLogo.logoDelegate = self
		newLogo.animate()
		
		return newLogo
	}
	
}

extension FlyingWordPressView: LogoLayerDelegate {
	
	func logoShouldBeRemoved(_ logo: LogoLayer) {
		if let logoIndex = logoArray.index(of: logo) {
			logoArray.remove(at: logoIndex)
		}
		logo.removeFromSuperlayer()
	}
	
}
