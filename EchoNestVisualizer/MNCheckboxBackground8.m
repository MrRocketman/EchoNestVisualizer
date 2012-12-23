//
//  MNCheckboxBackground8.m
//  EchoNestVisualizer
//
//  Created by James Adams on 12/23/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNCheckboxBackground8.h"

@implementation MNCheckboxBackground8

- (void)drawRect:(NSRect)rect
{
    rect = [self bounds];
    [[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.0 alpha:0.5] set];
    [NSBezierPath fillRect: rect];
}

@end
