//
//  WindowResizer.m
//  winman
//
//  Created by James M. Pridgen on 12/18/17.
//  Copyright © 2017 jmpridgen. All rights reserved.
//

#import "WindowResizer.h"

@implementation WindowResizer

+(void) fullScreen {
    NSScreen *myScreen = [NSScreen mainScreen];
    CGRect myScreenSize = [myScreen frame];
    myScreenSize = [self convertRect:myScreenSize];
    [self positionWindow:myScreenSize];
}

+(void)leftSide{
    NSScreen *myScreen = [NSScreen mainScreen];
    CGRect myScreenSize = [myScreen frame];
    CGRect desiredSize = myScreenSize;
    desiredSize.size.width = desiredSize.size.width/2;
    desiredSize = [self convertRect:desiredSize];
    [self positionWindow:desiredSize];
}

+(void)rightSide{
    NSScreen *myScreen = [NSScreen mainScreen];
    CGRect myScreenSize = [myScreen frame];
    CGRect desiredSize = myScreenSize;
    desiredSize.size.width = desiredSize.size.width/2;
    desiredSize.origin.x=myScreenSize.origin.x+desiredSize.size.width;
    desiredSize = [self convertRect:desiredSize];
    [self positionWindow:desiredSize];
}

+(void)positionWindow:(CGRect) myRect{
    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *myApp in runningApps)
    {
        if ([myApp isActive])
        {
            AXUIElementRef myAppRef = AXUIElementCreateApplication([myApp processIdentifier]);
            //NSLog(@"something to print");
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
                    AXValueRef newSizeRef = AXValueCreate(kAXValueCGSizeType, &myRect.size);
                    AXValueRef newPosRef = AXValueCreate(kAXValueCGPointType,&myRect.origin);
                    AXUIElementSetAttributeValue(windowRef, kAXPositionAttribute,newPosRef);
                    AXUIElementSetAttributeValue(windowRef, kAXSizeAttribute, newSizeRef);
                }
            }
        }
    }
}

+(CGRect)convertRect:(CGRect) oldRect{
    NSArray *myScreens = [NSScreen screens];
    NSScreen *primaryScreen;
    for (NSScreen *screen in myScreens) {
        CGFloat screenX = screen.frame.origin.x;
        CGFloat screenY = screen.frame.origin.y;
        if (screenX == 0 && screenY == 0){
            primaryScreen = screen;
            oldRect.origin.y = -oldRect.origin.y + primaryScreen.frame.size.height - oldRect.size.height;
            break;
        }
    }
    return oldRect;
}
@end
