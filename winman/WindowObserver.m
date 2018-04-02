//
//  WindowObserver.m
//  winman
//
//  Created by James M. Pridgen on 12/18/17.
//  Copyright © 2017 jmpridgen. All rights reserved.
//

#import "WindowObserver.h"

@implementation WindowObserver

-(WindowObserver*)init
{
    self = [super init];
    if (self) {
        [NSEvent addGlobalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseDown) handler:^void (NSEvent *incomingEvent){
            [self handleMouseDown:incomingEvent];
        }];
        [NSEvent addGlobalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseDragged) handler:^void (NSEvent *incomingEvent){
            [self handleMouseDragged:incomingEvent];
        }];
        
        [NSEvent addGlobalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseUp) handler:^void (NSEvent *incomingEvent){
            [self handleMouseUp:incomingEvent];
        }];
        
        [self addApplicationChangedObserver];
        [self addFocusedWindowChangedObserver];
        [self initializeOverlayPanel];
    }
    return self;
}

-(void) addApplicationChangedObserver {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    [[workspace notificationCenter] addObserver:self
                                       selector:@selector(handleWorkspaceNotification)
                                           name:nil
                                         object:workspace];
}

-(void) addFocusedWindowChangedObserver {
    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *myApp in runningApps)
    {
        if ([myApp isActive])
        {
//            NSLog(@"%@",myApp);
            AXUIElementRef myAppRef = AXUIElementCreateApplication([myApp processIdentifier]);
            CFArrayRef windowList;
            AXUIElementCopyAttributeValues(myAppRef, kAXWindowsAttribute, 0, 99999, &windowList);
            if (!windowList || CFArrayGetCount(windowList)<0) continue;
            for (CFIndex i = 0; i < CFArrayGetCount(windowList); i++)
            {
                AXUIElementRef windowRef = CFArrayGetValueAtIndex(windowList, i);
                //Determine whether window is mainwindow
                CFTypeRef isMainRef;
                AXUIElementCopyAttributeValue(windowRef, kAXMainAttribute, &isMainRef);
                
                if(!isMainRef) continue;
                bool isMain = CFBooleanGetValue(isMainRef);
                if (isMain == TRUE)
                {
//                    NSLog(@"%@", [myApp bundleIdentifier]);
                    pid_t myPid = [myApp processIdentifier];
//                    NSLog(@"PID is %i", myPid);
                    
                    //                    AXObserverCreate(myPid, myObserverCallback, &focusedWindowChangedObserver);
                    //                    AXObserverAddNotification(focusedWindowChangedObserver, (AXUIElementRef)myAppRef, (CFStringRef)NSAccessibilityFocusedWindowChangedNotification, (__bridge void*)self);
                    //                    CFRunLoopAddSource( [[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(focusedWindowChangedObserver),kCFRunLoopCommonModes );
                    
                    AXObserverCreate(myPid, windowDidMoveCallback, &windowDidMoveObserver);
                    AXObserverAddNotification(windowDidMoveObserver, (AXUIElementRef)myAppRef, (CFStringRef)NSAccessibilityWindowMovedNotification, (__bridge void*)self);
                    CFRunLoopAddSource( [[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(windowDidMoveObserver),kCFRunLoopCommonModes );
                }
            }
        }
    }
}

-(void) initializeOverlayPanel {
    NSRect panelSize = NSMakeRect(0, 0, 0, 0);
    overlayPanel = [[NSPanel alloc] initWithContentRect:panelSize
                                              styleMask:NSWindowStyleMaskBorderless
                                                backing:NSBackingStoreBuffered
                                                  defer:YES];
    [overlayPanel setReleasedWhenClosed:NO];
    [overlayPanel setHidesOnDeactivate:NO];
    [overlayPanel setFloatingPanel:YES];
    [overlayPanel setBackgroundColor:[NSColor colorWithRed:(CGFloat)52/255 green:(CGFloat)152/255 blue:(CGFloat)219/255 alpha:(CGFloat)1.0]];
    [overlayPanel setAlphaValue:0.6];
    
    [overlayPanel setLevel:kCGMainMenuWindowLevel-1];
    [overlayPanel setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorFullScreenAuxiliary];
    [overlayPanel orderFront:nil];
}

-(void) handleMouseDown:(NSEvent *) event {
    mouseDown = true;
//    NSLog(@"Mouse is down");
}

-(void) handleMouseUp:(NSEvent *) event {
    if (windowMoving == true) {
        NSPoint mouseLocation = [event locationInWindow];
        NSScreen *myScreen = getScreenFromEventLocation(mouseLocation);
        CGRect myScreenFrame = [myScreen frame];
        
        if (mouseIsOnLeft(mouseLocation, myScreenFrame)) {
            [WindowResizer leftSide];
        } else if (mouseIsOnRight(mouseLocation, myScreenFrame)) {
            [WindowResizer rightSide];
        } else if (mouseIsOnFullScreen(mouseLocation, myScreenFrame)) {
            [WindowResizer fullScreen];
        }
    }
    [overlayPanel setIsVisible:false];
    mouseDown = false;
    windowMoving = false;
//    NSLog(@"Mouse is up");
}

-(void) handleMouseDragged:(NSEvent *) incomingEvent {
    
//    NSLog(@"%@",incomingEvent);
    NSPoint mouseLocation = [incomingEvent locationInWindow];
    if (windowMoving == true) {
        NSScreen *myScreen = getScreenFromEventLocation(mouseLocation);
        CGRect myScreenFrame = [myScreen frame];
        if (mouseIsOnLeft(mouseLocation, myScreenFrame)){
            if (overlayPanel == nil || ![overlayPanel isVisible] || [overlayPanel screen] != myScreen){
                NSRect panelSize = NSMakeRect(myScreenFrame.origin.x, myScreenFrame.origin.y, myScreenFrame.size.width/2, myScreenFrame.size.height);
                [overlayPanel setFrame:panelSize display:true];
                [overlayPanel setIsVisible: true];
            }
        } else if(mouseIsOnRight(mouseLocation, myScreenFrame)){
            if (overlayPanel == nil || ![overlayPanel isVisible] || [overlayPanel screen] != myScreen){
                NSRect panelSize = NSMakeRect(myScreenFrame.origin.x + myScreenFrame.size.width/2, myScreenFrame.origin.y, myScreenFrame.size.width/2, myScreenFrame.size.height);
                [overlayPanel setFrame:panelSize display:true];
                [overlayPanel setIsVisible: true];
            }
        } else if(mouseIsOnFullScreen(mouseLocation, myScreenFrame)){
            if (overlayPanel == nil || ![overlayPanel isVisible] || [overlayPanel screen] != myScreen){
                NSRect panelSize = NSMakeRect(myScreenFrame.origin.x, myScreenFrame.origin.y, myScreenFrame.size.width, myScreenFrame.size.height);
                [overlayPanel setFrame:panelSize display:true];
                [overlayPanel setIsVisible: true];
            }
        }
        else {
            [overlayPanel setIsVisible:false];
        }
    }
}

BOOL mouseIsOnLeft(NSPoint mouseLocation, CGRect myScreenFrame){
    CGRect rectangleToCheck = CGRectMake(myScreenFrame.origin.x, myScreenFrame.origin.y, 100, myScreenFrame.size.height);
    return CGRectContainsPoint(rectangleToCheck, mouseLocation);
}

BOOL mouseIsOnRight(NSPoint mouseLocation, CGRect myScreenFrame) {
    CGRect rectangleToCheck = CGRectMake(myScreenFrame.origin.x + myScreenFrame.size.width - 100, myScreenFrame.origin.y, 100, myScreenFrame.size.height);
    return CGRectContainsPoint(rectangleToCheck, mouseLocation);
}

BOOL mouseIsOnFullScreen(NSPoint mouseLocation, CGRect myScreenFrame) {
    CGRect rectangleToCheck = CGRectMake(myScreenFrame.origin.x + myScreenFrame.size.width/2 - 100, myScreenFrame.origin.y + myScreenFrame.size.height - 100, 200, 100);
    return CGRectContainsPoint(rectangleToCheck, mouseLocation);
}

-(void) handleWorkspaceNotification {
    [self addFocusedWindowChangedObserver];
//    NSLog(@"Received a workspace notification");
}

void windowDidMoveCallback(AXObserverRef observer, AXUIElementRef elementRef, CFStringRef notification, void *self) {
//    NSLog(@"Window did move");
    [(__bridge id)self handleWindowMoved:notification];
}

-(void) handleWindowMoved:(CFStringRef) notification {
    if (mouseDown == true) {
        windowMoving = true;
    }
    else {
        windowMoving = false;
    }
}

// find out which screen the event occurred in
NSScreen* getScreenFromEventLocation(NSPoint mouseLocation) {
    NSArray *myScreens = [NSScreen screens];
    for (NSScreen *screen in myScreens) {
        bool isPointInsideScreen = CGRectContainsPoint(screen.frame, mouseLocation);
        if (isPointInsideScreen) {
            return screen;
        }
    }
    // if we can't find the screen, just return the main screen
    return [NSScreen mainScreen];
}



@end
