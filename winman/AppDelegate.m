//
//  AppDelegate.m
//  winman
//
//  Created by James M. Pridgen on 12/12/17.
//  Copyright © 2017 jmpridgen. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [self requestAccessibilityPermissions];
    
    // Create status bar
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"AppIcon" ofType:@"icns"];
    
    NSImage *myImage = [[NSImage alloc] initByReferencingFile:imagePath];
    // Use template rendering to allow for proper dark mode icon
    // myImage.template = YES;
    // [statusItem setImage:myImage];
    NSStatusBarButton *myButton = [statusItem button];
    [myButton setImage:myImage];
    [myButton setImageScaling:NSImageScaleProportionallyUpOrDown];
    //Create menu
    [statusItem setMenu:[self createStatusBarMenu]];
    
    myWindowObserver = [[WindowObserver alloc] init];
    
}


- (NSMenu *)createStatusBarMenu{
    NSMenu * menu = [[NSMenu alloc] init];
    
//    NSMenuItem *settingsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Settings" action:@selector(handleSettingsClick) keyEquivalent:@""];
//    [settingsMenuItem setTarget:self];
//    [menu addItem:settingsMenuItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(handleQuitPress) keyEquivalent:@""];
    [quitMenuItem setTarget:self];
    [menu addItem:quitMenuItem];
    
    return menu;
}

-(void)requestAccessibilityPermissions {
    if (!AXIsProcessTrusted()){
        NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
        AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
    }
}

-(void)handleSettingsClick {
//    NSLog(@"You pressed the settings");
}

-(void)handleQuitPress{
    [NSApp terminate:self];
}

@end
