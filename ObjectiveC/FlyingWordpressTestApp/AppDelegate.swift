//
//  AppDelegate.swift
//  FlyingWordPressTestApp
//
//  Created by Gergely on 19/04/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet weak var window: NSWindow!
	
	lazy var screenSaverView = FlyingWordPressView(frame: NSZeroRect, isPreview: false)

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		if let screenSaverView = screenSaverView {
			// Add screensaver view to window contents
			screenSaverView.frame = window.contentView!.bounds;
			window.contentView!.addSubview(screenSaverView);
			
			// Start animating (first frame)
			screenSaverView.startAnimation()
			
			// Schedule callbacks for animation flow (following frames)
			Timer.scheduledTimer(timeInterval: screenSaverView.animationTimeInterval, target: self, selector: #selector(updateScreenSaver(_:)), userInfo: nil, repeats: true)
		}
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		if let screenSaverView = screenSaverView {
			// Stop animating
			screenSaverView.stopAnimation()
		}
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	@objc func updateScreenSaver(_ timer: Timer) {
		
		if let screenSaverView = screenSaverView {
			screenSaverView.animateOneFrame()
		}
	}
	
}

