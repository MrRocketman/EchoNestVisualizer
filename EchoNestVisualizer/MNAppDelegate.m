//
//  MNAppDelegate.m
//  EchoNestVisualizer
//
//  Created by James Adams on 12/22/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNAppDelegate.h"

@interface MNAppDelegate()

- (void)loadOpenPanel;
- (void)updateCurrentTime:(NSNotification *)aNotification;

@end


@implementation MNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentTime:) name:@"UpdateCurrentTime" object:nil];
}

- (void)loadOpenPanel
{
    // Load the open panel if neccessary
    if(openPanel == nil)
    {
        openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanChooseFiles:YES];
        [openPanel setResolvesAliases:YES];
        [openPanel setAllowsMultipleSelection:NO];
    }
}

- (void)updateCurrentTime:(NSNotification *)aNotification
{
    [currentTimeLabel setStringValue:[NSString stringWithFormat:@"%.03f", [[aNotification object] floatValue]]];
}

- (IBAction)chooseAudioClipFileButtonPress:(id)sender
{
    [self loadOpenPanel];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"lmsd", nil]];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPathComponents:@[@"~", @"Library", @"Application Support", @"Light Master", @"audioClipLibrary"]]];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSString *filePath = [[openPanel URL] path];
             [audioClipFileLabel setStringValue:[filePath lastPathComponent]];
             
             NSDictionary *audioClip = [[NSDictionary alloc] initWithContentsOfFile:filePath];
             NSString *audioAnalysisFilePath = [NSString stringWithFormat:@"%@.lmaa", [filePath stringByDeletingPathExtension]];
             NSString *audioFileFilePath = [NSString stringWithFormat:@"%@/%@", [filePath stringByDeletingLastPathComponent], [[audioClip objectForKey:@"filePathToAudioFile"] lastPathComponent]];
             
             [audioFileLabel setStringValue:[audioFileFilePath lastPathComponent]];
             [audioAnalysisLabel setStringValue:[audioAnalysisFilePath lastPathComponent]];
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"SetAudioAnalysisFilePath" object:audioAnalysisFilePath];
             [[NSNotificationCenter defaultCenter] postNotificationName:@"SetAudioFilePath" object:audioFileFilePath];
         }
     }
     ];
}

- (IBAction)chooseAudioFileButtonPress:(id)sender
{
    [self loadOpenPanel];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"aac", @"aif", @"aiff", @"alac", @"mp3", @"m4a", @"wav", nil]];
    
    if(previousOpenPanelDirectory == nil)
    {
        [openPanel setDirectoryURL:[NSURL fileURLWithPathComponents:@[@"~", @"Library", @"Application Support", @"Light Master", @"audioClipLibrary"]]];
    }
    else
    {
        [openPanel setDirectoryURL:[NSURL fileURLWithPath:previousOpenPanelDirectory]];
    }
    
    [openPanel beginWithCompletionHandler:^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSString *filePath = [[openPanel URL] path];
             [audioFileLabel setStringValue:[filePath lastPathComponent]];
             [[NSNotificationCenter defaultCenter] postNotificationName:@"SetAudioFilePath" object:filePath];
         }
     }
     ];
}

- (IBAction)chooseAudioAnalysisButtonPress:(id)sender
{
    [self loadOpenPanel];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"lmaa", nil]];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPathComponents:@[@"~", @"Library", @"Application Support", @"Light Master", @"audioClipLibrary"]]];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSString *filePath = [[openPanel URL] path];
             [audioAnalysisLabel setStringValue:[filePath lastPathComponent]];
             [[NSNotificationCenter defaultCenter] postNotificationName:@"SetAudioAnalysisFilePath" object:filePath];
         }
     }
     ];
}

- (IBAction)skipBackButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SkipBack" object:nil];
}

- (IBAction)playPauseButtonPress:(id)sender
{
    if([[playPauseButton title] isEqualToString:@"Play"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Play" object:nil];
        [playPauseButton setTitle:@"Pause"];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Pause" object:nil];
        [playPauseButton setTitle:@"Play"];
    }
}

- (IBAction)zoomChange:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoomChange" object:[NSNumber numberWithFloat:[sender floatValue]]];
}

- (IBAction)timeCheckboxPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TimeCheckbox" object:[NSNumber numberWithInt:([sender state] == NSOnState ? 1 : 0)]];
}

- (IBAction)sectionsCheckboxPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SectionsCheckbox" object:[NSNumber numberWithInt:([sender state] == NSOnState ? 1 : 0)]];
}

- (IBAction)barsCheckboxPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BarsCheckbox" object:[NSNumber numberWithInt:([sender state] == NSOnState ? 1 : 0)]];
}

- (IBAction)beatsCheckboxPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BeatsCheckbox" object:[NSNumber numberWithInt:([sender state] == NSOnState ? 1 : 0)]];
}

- (IBAction)tatumsCheckboxPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TatumsCheckbox" object:[NSNumber numberWithInt:([sender state] == NSOnState ? 1 : 0)]];
}

- (IBAction)segmentsCheckboxPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SegmentsCheckbox" object:[NSNumber numberWithInt:([sender state] == NSOnState ? 1 : 0)]];
}

@end
