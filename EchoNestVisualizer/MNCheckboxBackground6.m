//
//  MNCheckboxBackground6.m
//  EchoNestVisualizer
//
//  Created by James Adams on 12/23/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNCheckboxBackground6.h"

@implementation MNCheckboxBackground6

- (void)drawRect:(NSRect)rect
{
    rect = [self bounds];
    [[NSColor colorWithCalibratedRed:1.0 green:0.5 blue:0.5 alpha:0.5] set];
    [NSBezierPath fillRect: rect];
}

@end
