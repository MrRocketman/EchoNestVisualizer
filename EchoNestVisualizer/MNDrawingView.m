//
//  MNDrawingView.m
//  EchoNestVisualizer
//
//  Created by James Adams on 12/22/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNDrawingView.h"

@interface MNDrawingView()

// Notifications
- (void)scrollViewBoundsDidChangeNotification:(NSNotification *)notification;
- (void)setAudioFilePath:(NSNotification *)aNotification;
- (void)setAudioAnalysisFilePath:(NSNotification *)aNotification;
- (void)play:(NSNotification *)aNotification;
- (void)pause:(NSNotification *)aNotification;
- (void)timeCheckbox:(NSNotification *)aNotification;
- (void)sectionsCheckbox:(NSNotification *)aNotification;
- (void)barsCheckbox:(NSNotification *)aNotification;
- (void)beatsCheckbox:(NSNotification *)aNotification;
- (void)tatumsCheckbox:(NSNotification *)aNotification;
- (void)segmentsCheckbox:(NSNotification *)aNotification;

// Math Methods
- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer *)theTimer;
- (float)roundUpNumber:(float)numberToRound toNearestMultipleOfNumber:(float)multiple;
- (int)timeToX:(float)time;
- (float)xToTime:(int)x;
- (int)widthForTimeInterval:(float)timeInterval;

// Helper Drawing Methods
- (void)drawTimelineBar;
- (void)drawInvertedTriangleAndLineWithTipPoint:(NSPoint)point width:(int)width andHeight:(int)height;

// Audio analysis drawing methods
- (void)drawSectionsAtTrackIndex:(int)trackIndex;
- (void)drawBarsAtTrackIndex:(int)trackIndex;
- (void)drawBeatsAtTrackIndex:(int)trackIndex;
- (void)drawTatumsAtTrackIndex:(int)trackIndex;
- (void)drawSegmentsAtTrackIndex:(int)trackIndex;

@end


@implementation MNDrawingView

@synthesize audioAnalysis, sound, currentTime, timeAtLeftEdge, zoomLevel, isPlaying, drawTime, drawSections, drawBars, drawBeats, drawTatums, drawSegments;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        topBarBackgroundImage = [NSImage imageNamed:@"Toolbar.tiff"];
        [(NSScrollView *)[self superview] setPostsBoundsChangedNotifications:YES];
        self.zoomLevel = 1.0;
        
        // Register for the notifications on the scrollView
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChangeNotification:) name:@"NSViewBoundsDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAudioFilePath:) name:@"SetAudioFilePath" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAudioAnalysisFilePath:) name:@"SetAudioAnalysisFilePath" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(play:) name:@"Play" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pause:) name:@"Pause" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeCheckbox:) name:@"TimeCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sectionsCheckbox:) name:@"SectionsCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(barsCheckbox:) name:@"BarsCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beatsCheckbox:) name:@"BeatsCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tatumsCheckbox:) name:@"TatumsCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(segmentsCheckbox:) name:@"SegmentsCheckbox" object:nil];
        
        [self scrollViewBoundsDidChangeNotification:nil];
    }
    
    return self;
}

#pragma mark - Notifications

- (void)scrollViewBoundsDidChangeNotification:(NSNotification *)notification
{
    NSClipView *changedScrollView = [notification object];
    
    scrollViewOrigin = [changedScrollView documentVisibleRect].origin;
    scrollViewVisibleSize = [changedScrollView documentVisibleRect].size;
    self.timeAtLeftEdge = scrollViewOrigin.x / self.zoomLevel / PIXEL_TO_ZOOM_RATIO;
    [self setNeedsDisplay:YES];
}

- (void)setAudioFilePath:(NSNotification *)aNotification
{
    // Load in the sound
    self.sound = [[NSSound alloc] initWithContentsOfFile:[aNotification object] byReference:NO];
    [sound play];
    [sound stop];
    
    // Set the Frame
    int trackItemsCount = 19;
    int frameHeight = 0;
    int frameWidth = [self timeToX:[self.sound duration]];
    if(trackItemsCount * TRACK_ITEM_HEIGHT + TOP_BAR_HEIGHT > [[self superview] frame].size.height)
    {
        frameHeight = trackItemsCount * TRACK_ITEM_HEIGHT + TOP_BAR_HEIGHT;
    }
    else
    {
        frameHeight = [[self superview] frame].size.height;
    }
    if(frameWidth <= [[self superview] frame].size.width)
    {
        frameWidth = [[self superview] frame].size.width;
    }
    [self setFrame:NSMakeRect(0.0, 0.0, frameWidth, frameHeight)];
}

- (void)setAudioAnalysisFilePath:(NSNotification *)aNotification
{
    self.audioAnalysis = [[NSDictionary alloc] initWithContentsOfFile:[aNotification object]];
    
    [self setNeedsDisplay:YES];
}

- (void)play:(NSNotification *)aNotification
{
    self.isPlaying = YES;
    [sound setCurrentTime:self.currentTime];
    [sound play];
    
    [self setNeedsDisplay:YES];
}

- (void)pause:(NSNotification *)aNotification
{
    self.isPlaying = NO;
    [sound pause];
    
    [self setNeedsDisplay:YES];
}

- (void)timeCheckbox:(NSNotification *)aNotification
{
    self.drawTime = [[aNotification object] boolValue];
    [self setNeedsDisplay:YES];
}

- (void)sectionsCheckbox:(NSNotification *)aNotification
{
    self.drawSections = [[aNotification object] boolValue];
    [self setNeedsDisplay:YES];
}

- (void)barsCheckbox:(NSNotification *)aNotification
{
    self.drawBars = [[aNotification object] boolValue];
    [self setNeedsDisplay:YES];
}

- (void)beatsCheckbox:(NSNotification *)aNotification
{
    self.drawBeats = [[aNotification object] boolValue];
    [self setNeedsDisplay:YES];
}

- (void)tatumsCheckbox:(NSNotification *)aNotification
{
    self.drawTatums = [[aNotification object] boolValue];
    [self setNeedsDisplay:YES];
}

- (void)segmentsCheckbox:(NSNotification *)aNotification
{
    self.drawSegments = [[aNotification object] boolValue];
    [self setNeedsDisplay:YES];
}

#pragma mark Mouse Methods

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseClickDownPoint = currentMousePoint;
    mouseAction = MNMouseDown;
    mouseEvent = theEvent;
    
    [autoScrollTimer invalidate];
    autoScrollTimer = nil;
    autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_SCROLL_REFRESH_RATE target:self selector:@selector(updateTimeAtLeftEdgeOfTimelineView:) userInfo:nil repeats:YES];
    autoscrollTimerIsRunning = YES;
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseDragged;
    mouseEvent = theEvent;
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseUp;
    mouseEvent = theEvent;
    mouseDraggingEvent = MNMouseDragNotInUse;
    
    [autoScrollTimer invalidate];
    autoScrollTimer = nil;
    autoscrollTimerIsRunning = NO;
    
    [self setNeedsDisplay:YES];
}

#pragma mark - Mouse Checking Methods

- (void)timelineBarMouseChecking
{
    // Draw the Top Bar
    NSRect superViewFrame = [[self superview] frame];
    NSRect topBarFrame = NSMakeRect(0, scrollViewOrigin.y + superViewFrame.size.height - TOP_BAR_HEIGHT, self.frame.size.width, TOP_BAR_HEIGHT);
    
    NSPoint trianglePoint = NSMakePoint((float)[self timeToX:[self currentTime]], topBarFrame.origin.y);
    float width = 20;
    float height = 20;
    
    NSBezierPath *triangle = [NSBezierPath bezierPath];
	
    [triangle moveToPoint:trianglePoint];
    [triangle lineToPoint:NSMakePoint(trianglePoint.x - width / 2,  trianglePoint.y + height)];
    [triangle lineToPoint:NSMakePoint(trianglePoint.x + width / 2, trianglePoint.y + height)];
    [triangle closePath];
    
    // CurrentTime Marker Mouse checking
    if([triangle containsPoint:currentMousePoint] && mouseAction == MNMouseDown && mouseEvent != nil)
    {
        currentTimeMarkerIsSelected = YES;
        mouseEvent = nil;
    }
    else if(currentTimeMarkerIsSelected && mouseAction == MNMouseUp && mouseEvent != nil)
    {
        currentTimeMarkerIsSelected = NO;
        mouseEvent = nil;
    }
    
    // Mouse Checking
    if(mouseAction == MNMouseDragged && (mouseDraggingEvent == MNMouseDragNotInUse || mouseDraggingEvent == MNTimeMarkerMouseDrag) && currentTimeMarkerIsSelected && mouseEvent != nil)
    {
        mouseDraggingEvent = MNTimeMarkerMouseDrag;
        float newCurrentTime = [self xToTime:currentMousePoint.x];
        
        // Bind the minimum time to 0
        if(newCurrentTime < 0.0)
        {
            newCurrentTime = 0.0;
        }
        
        // Move the cursor to the new position
        [self setCurrentTime:newCurrentTime];
    }
    
    // TopBar Mouse Checking
    if([[NSBezierPath bezierPathWithRect:topBarFrame] containsPoint:currentMousePoint] && mouseAction == MNMouseDown && mouseEvent != nil && !currentTimeMarkerIsSelected)
    {
        [self setCurrentTime:[self xToTime:currentMousePoint.x]];
        mouseEvent = nil;
    }
}

#pragma mark - Math Methods

- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer *)theTimer;
{
    if(mouseEvent)
    {
        BOOL didAutoscroll = [[self superview] autoscroll:mouseEvent];
        if(didAutoscroll)
        {
            [self setCurrentTime:[self xToTime:[self currentTime] + mouseEvent.deltaX]];
            [self setNeedsDisplay:YES];
        }
    }
}

- (float)roundUpNumber:(float)numberToRound toNearestMultipleOfNumber:(float)multiple
{
    // Only works to the nearest thousandth
    int intNumberToRound = (int)(numberToRound * 1000000);
    int intMultiple = (int)(multiple * 1000000);
    
    if(multiple == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    int remainder = intNumberToRound % intMultiple;
    if(remainder == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    return (intNumberToRound + intMultiple - remainder) / 1000000.0;
}

- (int)timeToX:(float)time
{
    int x = [self widthForTimeInterval:time];
    
	return x;
}

- (float)xToTime:(int)x
{
    return  x / zoomLevel / PIXEL_TO_ZOOM_RATIO;
}

- (int)widthForTimeInterval:(float)timeInterval
{
	return (timeInterval * zoomLevel * PIXEL_TO_ZOOM_RATIO);
}

#pragma mark - Helper Drawing Methods

- (void)drawTimelineBar
{
    // Draw the Top Bar
    NSRect superViewFrame = [[self superview] frame];
    NSRect topBarFrame = NSMakeRect(0, scrollViewOrigin.y + superViewFrame.size.height - TOP_BAR_HEIGHT, self.frame.size.width, TOP_BAR_HEIGHT);
    NSSize imageSize = [topBarBackgroundImage size];
    [topBarBackgroundImage drawInRect:topBarFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    
    // Determine the grid spacing
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeMarkerDifference = 0.0;
    if(timeSpan >= 60.0)
    {
        timeMarkerDifference = 6.0;
    }
    else if(timeSpan >= 50.0)
    {
        timeMarkerDifference = 5.0;
    }
    else if(timeSpan >= 40.0)
    {
        timeMarkerDifference = 4.0;
    }
    else if(timeSpan >= 30.0)
    {
        timeMarkerDifference = 3.0;
    }
    else if(timeSpan >= 20.0)
    {
        timeMarkerDifference = 2.0;
    }
    else if(timeSpan >= 15.0)
    {
        timeMarkerDifference = 1.5;
    }
    else if(timeSpan >= 10.0)
    {
        timeMarkerDifference = 1.0;
    }
    else if(timeSpan >= 5.0)
    {
        timeMarkerDifference = 0.5;
    }
    else if(timeSpan >= 2.5)
    {
        timeMarkerDifference = 0.25;
    }
    else if(timeSpan >= 1.25)
    {
        timeMarkerDifference = 0.125;
    }
    else
    {
        timeMarkerDifference = 0.0625;
    }
    
    // Draw the grid (+ 5 extras so the user doesn't see blank areas)
    float leftEdgeNearestTimeMaker = [self roundUpNumber:self.timeAtLeftEdge toNearestMultipleOfNumber:timeMarkerDifference];
	for(int i = 0; i < timeSpan / timeMarkerDifference + 6; i ++)
	{
        float timeMarker = (leftEdgeNearestTimeMaker - (timeMarkerDifference * 3) + i * timeMarkerDifference);
        // Draw the times
        NSString *time = [NSString stringWithFormat:@"%.02f", timeMarker];
        NSRect textFrame = NSMakeRect([self timeToX:timeMarker], topBarFrame.origin.y, 40, topBarFrame.size.height);
        [time drawInRect:textFrame withAttributes:attributes];
        
        // Draw grid lines
        if(self.drawTime)
        {
            NSRect markerLineFrame = NSMakeRect(textFrame.origin.x, scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
            [[NSColor blackColor] set];
            NSRectFill(markerLineFrame);
        }
	}
    
    // Draw the currentTime marker
    NSPoint trianglePoint = NSMakePoint((float)[self timeToX:self.currentTime], topBarFrame.origin.y);
    [self drawInvertedTriangleAndLineWithTipPoint:trianglePoint width:20 andHeight:20];
}

- (void)drawInvertedTriangleAndLineWithTipPoint:(NSPoint)point width:(int)width andHeight:(int)height
{
    NSBezierPath *triangle = [NSBezierPath bezierPath];
	
    [triangle moveToPoint:point];
    [triangle lineToPoint:NSMakePoint(point.x - width / 2,  point.y + height)];
    [triangle lineToPoint:NSMakePoint(point.x + width / 2, point.y + height)];
    [triangle closePath];
	
    // Set the color according to whether it is clicked or not
	if(!currentTimeMarkerIsSelected)
    {
        [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] setFill];
    }
	else
    {
        [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.5] setFill];
    }
	[triangle fill];
	[[NSColor whiteColor] setStroke];
    [triangle stroke];
    
    NSRect markerLineFrame = NSMakeRect(point.x, scrollViewOrigin.y, 1, [[self superview] frame].size.height - TOP_BAR_HEIGHT);
    [[NSColor redColor] set];
    NSRectFill(markerLineFrame);
}

#pragma mark - Audio analysis drawing methods

- (void)drawSectionsAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *sections = [audioAnalysis objectForKey:@"sections"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [sections count] && (timeAtLeftEdge - 1 >= [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [sections count] && (timeAtLeftEdge - 1 < [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([self timeToX:[[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 3, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor yellowColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

- (void)drawBarsAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *bars = [audioAnalysis objectForKey:@"bars"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [bars count] && (timeAtLeftEdge - 1 >= [[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [bars count] && (timeAtLeftEdge - 1 < [[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([self timeToX:[[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 2, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor orangeColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

- (void)drawBeatsAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *beats = [audioAnalysis objectForKey:@"beats"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [beats count] && (timeAtLeftEdge - 1 >= [[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [beats count] && (timeAtLeftEdge - 1 < [[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([self timeToX:[[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor whiteColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

- (void)drawTatumsAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *tatums = [audioAnalysis objectForKey:@"tatums"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [tatums count] && (timeAtLeftEdge - 1 >= [[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [tatums count] && (timeAtLeftEdge - 1 < [[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([self timeToX:[[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor cyanColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

- (void)drawSegmentsAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *segments = [audioAnalysis objectForKey:@"segments"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [segments count] && (timeAtLeftEdge - 1 >= [[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [segments count] && (timeAtLeftEdge - 1 < [[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([self timeToX:[[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor magentaColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // Draw the timeline on top of everything
    [self drawTimelineBar];
    
    // Draw the audio analysis data
    if(![[NSNull null] isEqual:self.audioAnalysis])
    {
        if(self.drawSegments)
        {
            [self drawSegmentsAtTrackIndex:4];
        }
        if(self.drawTatums)
        {
            [self drawTatumsAtTrackIndex:3];
        }
        if(self.drawBeats)
        {
            [self drawBeatsAtTrackIndex:2];
        }
        if(self.drawBars)
        {
            [self drawBarsAtTrackIndex:1];
        }
        if(self.drawSections)
        {
            [self drawSectionsAtTrackIndex:0];
        }
    }
}

@end
