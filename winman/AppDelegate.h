//
//  AppDelegate.h
//  winman
//
//  Created by James M. Pridgen on 12/12/17.
//  Copyright © 2017 jmpridgen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WindowObserver.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    NSStatusItem *statusItem;
    WindowObserver *myWindowObserver;
}

@end

