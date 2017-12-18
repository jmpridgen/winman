//
//  main.m
//  winman
//
//  Created by James M. Pridgen on 12/12/17.
//  Copyright © 2017 jmpridgen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    NSLog(@"Loading main.m");
    
    NSApplication *application = [NSApplication sharedApplication];
    
    AppDelegate *appDelegate = [[AppDelegate alloc] init];
    
    [application setDelegate: appDelegate];
    [application run];
    return EXIT_SUCCESS;
    

//    return NSApplicationMain(argc, argv, nil, @"AppDelegate.m");
}
