//
//  MNDrawingView.h
//  EchoNestVisualizer
//
//  Created by James Adams on 12/22/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// This is how many pixels per second there are are a zoom level of 1
#define PIXEL_TO_ZOOM_RATIO 25
#define TRACK_ITEM_HEIGHT 20.0
#define TOP_BAR_HEIGHT 20.0
#define AUTO_SCROLL_REFRESH_RATE 0.03
#define BOX_CORNER_RADIUS 3.0

enum
{
    MNMouseDragNotInUse,
    MNTimeMarkerMouseDrag,
};

enum
{
    MNMouseDown,
    MNMouseDragged,
    MNMouseUp
};

@interface MNDrawingView : NSView
{
    NSSound *sound;
    NSDictionary *audioAnalysis;
    
    float currentTime;
    float timeAtLeftEdge;
    float zoomLevel; // 1.0 = no zoom, 10 = 10x zoom
    BOOL isPlaying;
    
    BOOL drawTime;
    BOOL drawSections;
    BOOL drawBars;
    BOOL drawBeats;
    BOOL drawTatums;
    BOOL drawSegments;
    BOOL drawTimbre;
    BOOL drawPitch;
    int trackItemsCount;
    
    NSPoint scrollViewOrigin;
    NSSize scrollViewVisibleSize;
    
    NSImage *topBarBackgroundImage;
    
    NSPoint mouseClickDownPoint;
    NSPoint currentMousePoint;
    int mouseAction;
    NSEvent *mouseEvent;
    NSTimer *autoScrollTimer;
    int mouseDraggingEvent;
    BOOL autoscrollTimerIsRunning;
    BOOL currentTimeMarkerIsSelected;
    
    NSTimer *playTimer;
    NSDate *playButtonStartDate;
    float playButtonStartTime;
    float newTimeForPlayTimer;
}

@property(strong) NSSound *sound;
@property(strong) NSDictionary *audioAnalysis;

@property(assign) float currentTime;
@property(assign) float timeAtLeftEdge;
@property(assign) float zoomLevel;
@property(assign) BOOL isPlaying;

@property(assign) BOOL drawTime;
@property(assign) BOOL drawSections;
@property(assign) BOOL drawBars;
@property(assign) BOOL drawBeats;
@property(assign) BOOL drawTatums;
@property(assign) BOOL drawSegments;
@property(assign) BOOL drawTimbre;
@property(assign) BOOL drawPitch;

@end
