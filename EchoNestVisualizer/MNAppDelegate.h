//
//  MNAppDelegate.h
//  EchoNestVisualizer
//
//  Created by James Adams on 12/22/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MNAppDelegate : NSObject <NSApplicationDelegate>
{
    NSOpenPanel *openPanel;
    NSString *previousOpenPanelDirectory;
    
    IBOutlet NSTextField *audioFileLabel;
    IBOutlet NSTextField *audioAnalysisLabel;
    
    IBOutlet NSButton *playPauseButton;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)chooseAudioFileButtonPress:(id)sender;
- (IBAction)chooseAudioAnalysisButtonPress:(id)sender;

- (IBAction)playPauseButtonPress:(id)sender;

- (IBAction)timeCheckboxPress:(id)sender;
- (IBAction)sectionsCheckboxPress:(id)sender;
- (IBAction)barsCheckboxPress:(id)sender;
- (IBAction)beatsCheckboxPress:(id)sender;
- (IBAction)tatumsCheckboxPress:(id)sender;
- (IBAction)segmentsCheckboxPress:(id)sender;

@end
