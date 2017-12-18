//
//  WindowObserver.h
//  winman
//
//  Created by James M. Pridgen on 12/18/17.
//  Copyright © 2017 jmpridgen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WindowResizer.h"

@interface WindowObserver : NSObject {

    NSPanel *overlayPanel;
    AXObserverRef focusedWindowChangedObserver;
    AXObserverRef applicationChangedObserver;
    AXObserverRef windowMovedObserver;
    AXObserverRef windowDidMoveObserver;
    BOOL windowMoving;
    BOOL mouseDown;

}

@end
