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
- (void)skipBack:(NSNotification *)aNotification;
- (void)play:(NSNotification *)aNotification;
- (void)pause:(NSNotification *)aNotification;
- (void)zoomChange:(NSNotification *)aNotification;
- (void)timeCheckbox:(NSNotification *)aNotification;
- (void)sectionsCheckbox:(NSNotification *)aNotification;
- (void)barsCheckbox:(NSNotification *)aNotification;
- (void)beatsCheckbox:(NSNotification *)aNotification;
- (void)tatumsCheckbox:(NSNotification *)aNotification;
- (void)segmentsCheckbox:(NSNotification *)aNotification;
- (void)timbreCheckbox:(NSNotification *)aNotification;
- (void)pitchCheckbox:(NSNotification *)aNotification;
- (void)loudnessCheckbox:(NSNotification *)aNotification;

// Math Methods
- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer *)theTimer;
- (float)roundUpNumber:(float)numberToRound toNearestMultipleOfNumber:(float)multiple;
- (int)timeToX:(float)time;
- (float)xToTime:(int)x;
- (int)widthForTimeInterval:(float)timeInterval;
- (void)playTimerFire:(NSTimer *)theTimer;

// Helper Drawing Methods
- (void)drawTimelineBar;
- (void)drawInvertedTriangleAndLineWithTipPoint:(NSPoint)point width:(int)width andHeight:(int)height;
- (void)drawRect:(NSRect)aRect withCornerRadius:(float)radius fillColor:(NSColor *)color andStroke:(BOOL)yesOrNo;

// Audio analysis drawing methods
- (void)drawAudioAnalysisData:(NSString *)dataType withColorRed:(float)red colorGreen:(float)green colorBlue:(float)blue atTrackIndex:(int)trackIndex;
- (void)drawTimbreAverageAtTrackIndex:(int)trackIndex;
- (void)drawTimbresAtTrackIndex:(int)trackIndex;
- (void)drawPitchAverageAtTrackIndex:(int)trackIndex;
- (void)drawPitchesAtTrackIndex:(int)trackIndex;
- (void)drawLoudnessAtTrackIndex:(int)trackIndex;

@end


@implementation MNDrawingView

@synthesize audioAnalysis, sound, timeAtLeftEdge, zoomLevel, isPlaying, drawTime, drawSections, drawBars, drawBeats, drawTatums, drawSegments, drawTimbre, drawPitch, drawLoudness;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        topBarBackgroundImage = [NSImage imageNamed:@"Toolbar.tiff"];
        [(NSScrollView *)[self superview] setPostsBoundsChangedNotifications:YES];
        self.zoomLevel = 3.0;
        self.drawTime = YES;
        self.drawSections = YES;
        self.drawBars = YES;
        self.drawBeats = YES;
        self.drawTatums = YES;
        self.drawSegments = YES;
        self.drawTimbre = YES;
        self.drawPitch = YES;
        self.drawLoudness = YES;
        
        // Register for the notifications on the scrollView
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChangeNotification:) name:@"NSViewBoundsDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAudioFilePath:) name:@"SetAudioFilePath" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAudioAnalysisFilePath:) name:@"SetAudioAnalysisFilePath" object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(skipBack:) name:@"SkipBack" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(play:) name:@"Play" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pause:) name:@"Pause" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomChange:) name:@"ZoomChange" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeCheckbox:) name:@"TimeCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sectionsCheckbox:) name:@"SectionsCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(barsCheckbox:) name:@"BarsCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beatsCheckbox:) name:@"BeatsCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tatumsCheckbox:) name:@"TatumsCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(segmentsCheckbox:) name:@"SegmentsCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timbreCheckbox:) name:@"TimbreCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pitchCheckbox:) name:@"PitchCheckbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loudnessCheckbox:) name:@"LoudnessCheckbox" object:nil];
        
        [self scrollViewBoundsDidChangeNotification:nil];
    }
    
    return self;
}

- (float)currentTime
{
    return currentTime;
}

- (void)setCurrentTime:(float)newTime
{
    currentTime = newTime;
    
    if(playTimer && (int)([self currentTime] * 1000) != (int)(newTimeForPlayTimer * 1000))
    {
        playButtonStartDate = [NSDate date];
        playButtonStartTime = [self currentTime];
        // Restart the sounds
        [self pause:nil];
        [self play:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateCurrentTime" object:[NSNumber numberWithFloat:self.currentTime]];
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
    
    [self setNeedsDisplay:YES];
}

- (void)setAudioAnalysisFilePath:(NSNotification *)aNotification
{
    self.audioAnalysis = [[NSDictionary alloc] initWithContentsOfFile:[aNotification object]];
    
    [self setNeedsDisplay:YES];
}

- (void)skipBack:(NSNotification *)aNotification
{
    self.currentTime = 0.0;
    [self scrollPoint:NSMakePoint([self timeToX:0.0], [(NSClipView *)[self superview] documentVisibleRect].origin.y)];
    [self setNeedsDisplay:YES];
}

- (void)play:(NSNotification *)aNotification
{
    // Start the timer
    playTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(playTimerFire:) userInfo:nil repeats:YES];
    playButtonStartDate = [NSDate date];
    playButtonStartTime = self.currentTime;
    self.isPlaying = YES;
    
    // Play the sound
    [sound setCurrentTime:self.currentTime];
    [sound play];
    
    [self setNeedsDisplay:YES];
}

- (void)pause:(NSNotification *)aNotification
{
    // Stop the timer
    [playTimer invalidate];
    playTimer = nil;
    self.isPlaying = NO;
    
    // Pause the sound
    [sound stop];
    
    [self setNeedsDisplay:YES];
}

- (void)zoomChange:(NSNotification *)aNotification
{
    // This gives a much more linear feel to the zoom
    self.zoomLevel = pow([[aNotification object] floatValue], 2) / 2;
    
    // Scroll to the new left edge point by x (the left edge time has not change, the x has because of zoon)
    [self scrollPoint:NSMakePoint([self timeToX:self.timeAtLeftEdge], [(NSClipView *)[self superview] documentVisibleRect].origin.y)];
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

- (void)timbreCheckbox:(NSNotification *)aNotification
{
    self.drawTimbre = [[aNotification object] boolValue];
    [self setNeedsDisplay:YES];
}

- (void)pitchCheckbox:(NSNotification *)aNotification
{
    self.drawPitch = [[aNotification object] boolValue];
    [self setNeedsDisplay:YES];
}

- (void)loudnessCheckbox:(NSNotification *)aNotification
{
    self.drawLoudness = [[aNotification object] boolValue];
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

- (void)playTimerFire:(NSTimer *)theTimer
{
    float timeDifference = [[NSDate date] timeIntervalSinceDate:playButtonStartDate];
    newTimeForPlayTimer = playButtonStartTime + timeDifference;
    self.currentTime = newTimeForPlayTimer;
    [self scrollPoint:NSMakePoint([self timeToX:newTimeForPlayTimer] - self.superview.frame.size.width / 2, [(NSClipView *)[self superview] documentVisibleRect].origin.y)];
    
    [self setNeedsDisplay:YES];
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

- (void)drawRect:(NSRect)aRect withCornerRadius:(float)radius fillColor:(NSColor *)color andStroke:(BOOL)yesOrNo
{
    NSBezierPath *thePath = [NSBezierPath bezierPathWithRoundedRect:aRect xRadius:radius yRadius:radius];
    
	[color setFill];
    [[NSColor whiteColor] setStroke];
	
	if(yesOrNo)
    {
        [thePath stroke];
    }
	[thePath fill];
}

#pragma mark - Audio analysis drawing methods

- (void)drawAudioAnalysisData:(NSString *)dataType withColorRed:(float)red colorGreen:(float)green colorBlue:(float)blue atTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *dataItems = [audioAnalysis objectForKey:dataType];
    NSDictionary *data;
    float x, y, width, height, confidence, endTime, startTime, duration;
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 >= startTime + duration || timeAtRightEdge + 1 <= startTime)
        {
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
    
    // Set the font attributes
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 < startTime + duration && timeAtRightEdge + 1 > startTime)
        {
            // Draw grid lines
            endTime = startTime + duration;
            x  = [self timeToX:startTime];
            y = self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - 1 * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
            width = [self widthForTimeInterval:endTime - startTime] - 3;
            height = TRACK_ITEM_HEIGHT - 2;
            confidence = [[data objectForKey:@"confidence"] floatValue];
            
            //NSRect markerLineFrame = NSMakeRect([self timeToX:[[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 3, superViewFrame.size.height - TOP_BAR_HEIGHT);
            //[[NSColor yellowColor] set];
            //NSRectFill(markerLineFrame);
            [self drawRect:NSMakeRect(x, y, width, height) withCornerRadius:BOX_CORNER_RADIUS fillColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:confidence] andStroke:YES];
            
            // Draw the confidence
            NSString *time = [NSString stringWithFormat:@"%.02f", confidence];
            [time drawInRect:NSMakeRect(x + 2, y, width, height) withAttributes:attributes];
            
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
}

- (void)drawTimbreAverageAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *dataItems = [audioAnalysis objectForKey:@"segments"];
    NSDictionary *data;
    float x, y, width, height, confidence, endTime, startTime, duration, red, green, blue;
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 >= startTime + duration || timeAtRightEdge + 1 <= startTime)
        {
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
    
    // Set the font attributes
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 < startTime + duration && timeAtRightEdge + 1 > startTime)
        {
            // Draw grid lines
            endTime = startTime + duration;
            x  = [self timeToX:startTime];
            y = self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - 1 * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
            width = [self widthForTimeInterval:endTime - startTime] - 3;
            height = TRACK_ITEM_HEIGHT - 2;
            confidence = [[data objectForKey:@"confidence"] floatValue];
            NSArray *timbres = [data objectForKey:@"timbre"];
            red = ([[timbres objectAtIndex:0] floatValue] + 120) / 240;
            green = ([[timbres objectAtIndex:1] floatValue] + 120) / 240;
            blue = ([[timbres objectAtIndex:2] floatValue] + 120) / 240;
            
            [self drawRect:NSMakeRect(x, y, width, height) withCornerRadius:BOX_CORNER_RADIUS fillColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:confidence] andStroke:YES];
            
            // Draw the confidence
            NSString *time = [NSString stringWithFormat:@"%.02f", confidence];
            [time drawInRect:NSMakeRect(x + 2, y, width, height) withAttributes:attributes];
            
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
}

- (void)drawTimbresAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *dataItems = [audioAnalysis objectForKey:@"segments"];
    NSDictionary *data;
    float x, y, width, height, endTime, startTime, duration, timbre;
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 >= startTime + duration || timeAtRightEdge + 1 <= startTime)
        {
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
    
    // Set the font attributes
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 < startTime + duration && timeAtRightEdge + 1 > startTime)
        {
            NSArray *timbres = [data objectForKey:@"timbre"];
            for(int timbreIndex = 0; timbreIndex < 12; timbreIndex ++)
            {
                endTime = startTime + duration;
                x  = [self timeToX:startTime];
                y = self.frame.size.height - (trackIndex + timbreIndex) * TRACK_ITEM_HEIGHT - 1 * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
                width = [self widthForTimeInterval:endTime - startTime] - 3;
                height = TRACK_ITEM_HEIGHT - 2;
                timbre = ([[timbres objectAtIndex:timbreIndex] floatValue] + 120) / 240;
                
                [self drawRect:NSMakeRect(x, y, width, height) withCornerRadius:BOX_CORNER_RADIUS fillColor:[NSColor colorWithCalibratedRed:1.0 green:0.5 blue:0.5 alpha:timbre] andStroke:YES];
                
                // Draw the confidence
                NSString *time = [NSString stringWithFormat:@"%.02f", timbre];
                [time drawInRect:NSMakeRect(x + 2, y, width, height) withAttributes:attributes];
            }
            
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
}

- (void)drawPitchAverageAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *dataItems = [audioAnalysis objectForKey:@"segments"];
    NSDictionary *data;
    float x, y, width, height, confidence, endTime, startTime, duration, red, green, blue;
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 >= startTime + duration || timeAtRightEdge + 1 <= startTime)
        {
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
    
    // Set the font attributes
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 < startTime + duration && timeAtRightEdge + 1 > startTime)
        {
            // Draw grid lines
            endTime = startTime + duration;
            x  = [self timeToX:startTime];
            y = self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - 1 * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
            width = [self widthForTimeInterval:endTime - startTime] - 3;
            height = TRACK_ITEM_HEIGHT - 2;
            confidence = [[data objectForKey:@"confidence"] floatValue];
            NSArray *pitches = [data objectForKey:@"pitches"];
            red = ([[pitches objectAtIndex:0] floatValue] + [[pitches objectAtIndex:1] floatValue] + [[pitches objectAtIndex:2] floatValue] + [[pitches objectAtIndex:3] floatValue]) / 4;
            green = ([[pitches objectAtIndex:4] floatValue] + [[pitches objectAtIndex:4] floatValue] + [[pitches objectAtIndex:6] floatValue] + [[pitches objectAtIndex:7] floatValue]) / 4;
            blue = ([[pitches objectAtIndex:8] floatValue] + [[pitches objectAtIndex:9] floatValue] + [[pitches objectAtIndex:10] floatValue] + [[pitches objectAtIndex:11] floatValue]) / 4;
            
            [self drawRect:NSMakeRect(x, y, width, height) withCornerRadius:BOX_CORNER_RADIUS fillColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:confidence] andStroke:YES];
            
            // Draw the confidence
            NSString *time = [NSString stringWithFormat:@"%.02f", confidence];
            [time drawInRect:NSMakeRect(x + 2, y, width, height) withAttributes:attributes];
            
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
}

- (void)drawPitchesAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *dataItems = [audioAnalysis objectForKey:@"segments"];
    NSDictionary *data;
    float x, y, width, height, endTime, startTime, duration, pitch;
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 >= startTime + duration || timeAtRightEdge + 1 <= startTime)
        {
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
    
    // Set the font attributes
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 < startTime + duration && timeAtRightEdge + 1 > startTime)
        {
            NSArray *pitches = [data objectForKey:@"pitches"];
            for(int pitchIndex = 0; pitchIndex < 12; pitchIndex ++)
            {
                endTime = startTime + duration;
                x  = [self timeToX:startTime];
                y = self.frame.size.height - (trackIndex + pitchIndex) * TRACK_ITEM_HEIGHT - 1 * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
                width = [self widthForTimeInterval:endTime - startTime] - 3;
                height = TRACK_ITEM_HEIGHT - 2;
                pitch = [[pitches objectAtIndex:pitchIndex] floatValue];
                
                [self drawRect:NSMakeRect(x, y, width, height) withCornerRadius:BOX_CORNER_RADIUS fillColor:[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.5 alpha:pitch] andStroke:YES];
                
                // Draw the confidence
                NSString *time = [NSString stringWithFormat:@"%.02f", pitch];
                [time drawInRect:NSMakeRect(x + 2, y, width, height) withAttributes:attributes];
            }
            
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
}

- (void)drawLoudnessAtTrackIndex:(int)trackIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdge] + superViewFrame.size.width] - self.timeAtLeftEdge;
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *dataItems = [audioAnalysis objectForKey:@"segments"];
    NSDictionary *data;
    float x, y, width, height, endTime, startTime, duration, loudnessStart, loudnessMax, loudnessMaxTime;
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 >= startTime + duration || timeAtRightEdge + 1 <= startTime)
        {
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
    
    // Set the font attributes
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [dataItems count])
    {
        data = [dataItems objectAtIndex:visibleSectionIndex];
        startTime = [[data objectForKey:@"start"] floatValue];
        duration = [[data objectForKey:@"duration"] floatValue];
        if(timeAtLeftEdge - 1 < startTime + duration && timeAtRightEdge + 1 > startTime)
        {
            loudnessStart = ([[data objectForKey:@"loudness_start"] floatValue] + 60) / 60;
            loudnessMax = ([[data objectForKey:@"loudness_max"] floatValue] + 60) / 60;
            loudnessMaxTime = [[data objectForKey:@"loudness_max_time"] floatValue];
            
            // Loudness Start
            endTime = startTime + duration;
            x  = [self timeToX:startTime];
            y = self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - 1 * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
            width = [self widthForTimeInterval:endTime - startTime] - 3;
            height = TRACK_ITEM_HEIGHT - 2;
            
            [self drawRect:NSMakeRect(x, y, width, height) withCornerRadius:BOX_CORNER_RADIUS fillColor:[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.0 alpha:loudnessStart] andStroke:YES];
            
            NSString *time = [NSString stringWithFormat:@"%.02f", loudnessStart];
            [time drawInRect:NSMakeRect(x + 2, y, width, height) withAttributes:attributes];
            
            // Loudness max
            endTime = startTime + duration;
            x  = [self timeToX:startTime + loudnessMaxTime];
            y = self.frame.size.height - (trackIndex + 1) * TRACK_ITEM_HEIGHT - 1 * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
            width = [self widthForTimeInterval:endTime - startTime] - 3;
            height = TRACK_ITEM_HEIGHT - 2;
            
            [self drawRect:NSMakeRect(x, y, width, height) withCornerRadius:BOX_CORNER_RADIUS fillColor:[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.0 alpha:loudnessMax] andStroke:YES];
            
            time = [NSString stringWithFormat:@"%.02f", loudnessMax];
            [time drawInRect:NSMakeRect(x + 2, y, width, height) withAttributes:attributes];
            
            visibleSectionIndex ++;
        }
        else
        {
            break;
        }
    }
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // Set the Frame
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
    [[NSColor darkGrayColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, frameWidth, frameHeight));
    
    // Check for timelineBar mouse clicks
    [self timelineBarMouseChecking];
    
    // Draw the audio analysis data
    if(![[NSNull null] isEqual:self.audioAnalysis])
    {
        trackItemsCount = 0;
        if(self.drawSections)
        {
            [self drawAudioAnalysisData:@"sections" withColorRed:1.0 colorGreen:1.0 colorBlue:0.0 atTrackIndex:trackItemsCount];
            trackItemsCount ++;
        }
        if(self.drawBars)
        {
            [self drawAudioAnalysisData:@"bars" withColorRed:1.0 colorGreen:0.5 colorBlue:0.0 atTrackIndex:trackItemsCount];
            trackItemsCount ++;
        }
        if(self.drawBeats)
        {
            [self drawAudioAnalysisData:@"beats" withColorRed:1.0 colorGreen:1.0 colorBlue:1.0 atTrackIndex:trackItemsCount];
            trackItemsCount ++;
        }
        if(self.drawTatums)
        {
            [self drawAudioAnalysisData:@"tatums" withColorRed:0.0 colorGreen:1.0 colorBlue:1.0 atTrackIndex:trackItemsCount];
            trackItemsCount ++;
        }
        if(self.drawSegments)
        {
            [self drawAudioAnalysisData:@"segments" withColorRed:1.0 colorGreen:0.0 colorBlue:1.0 atTrackIndex:trackItemsCount];
            trackItemsCount ++;
        }
        if(self.drawTimbre)
        {
            [self drawTimbreAverageAtTrackIndex:trackItemsCount];
            trackItemsCount ++;
            [self drawTimbresAtTrackIndex:trackItemsCount];
            trackItemsCount += 12;
        }
        if(self.drawPitch)
        {
            [self drawPitchAverageAtTrackIndex:trackItemsCount];
            trackItemsCount ++;
            [self drawPitchesAtTrackIndex:trackItemsCount];
            trackItemsCount += 12;
        }
        if(self.drawLoudness)
        {
            [self drawLoudnessAtTrackIndex:trackItemsCount];
            trackItemsCount += 2;
        }
    }
    
    // Draw the timeline on top of everything
    [self drawTimelineBar];
}

@end
