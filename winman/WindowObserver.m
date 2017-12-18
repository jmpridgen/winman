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
        if (mouseIsOnLeft(mouseLocation)) {
            [WindowResizer leftSide];
        } else if (mouseIsOnRight(mouseLocation)) {
            [WindowResizer rightSide];
        } else if (mouseIsOnFullScreen(mouseLocation)) {
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
//    NSLog(@"%@",NSStringFromPoint(mouseLocation));
    //    NSLog(@"%s",incomingEvent.userData);
    if (windowMoving == true) {
        NSScreen *myScreen = [NSScreen mainScreen];
        CGRect myScreenSize = [myScreen frame];
        if (mouseIsOnLeft(mouseLocation)){
            if (overlayPanel == nil || ![overlayPanel isVisible]){
                NSRect panelSize = NSMakeRect(0, 0, myScreenSize.size.width/2, myScreenSize.size.height);
                [overlayPanel setFrame:panelSize display:true];
                [overlayPanel setIsVisible: true];
            }
        } else if(mouseIsOnRight(mouseLocation)){
            if (overlayPanel == nil || ![overlayPanel isVisible]){
                NSRect panelSize = NSMakeRect(myScreenSize.size.width/2, 0, myScreenSize.size.width/2, myScreenSize.size.height);
                [overlayPanel setFrame:panelSize display:true];
                [overlayPanel setIsVisible: true];
            }
        } else if(mouseIsOnFullScreen(mouseLocation)){
            if (overlayPanel == nil || ![overlayPanel isVisible]){
                NSRect panelSize = NSMakeRect(0, 0, myScreenSize.size.width, myScreenSize.size.height);
                [overlayPanel setFrame:panelSize display:true];
                [overlayPanel setIsVisible: true];
            }
        }
        else {
            [overlayPanel setIsVisible:false];
        }
    }
}

BOOL mouseIsOnLeft(NSPoint mouseLocation){
    return  mouseLocation.x < 100;
}

BOOL mouseIsOnRight(NSPoint mouseLocation) {
    CGRect myScreenSize = [[NSScreen mainScreen] frame];
    return mouseLocation.x > myScreenSize.size.width - 100;
}

BOOL mouseIsOnFullScreen(NSPoint mouseLocation) {
    CGRect myScreenSize = [[NSScreen mainScreen] frame];
    BOOL returnValue = mouseLocation.y > myScreenSize.size.height - 100 && mouseLocation.x > myScreenSize.size.width/2 - 100 && mouseLocation.x < myScreenSize.size.width/2 + 100;
    return returnValue;
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
    windowMoving = true;
}



@end
