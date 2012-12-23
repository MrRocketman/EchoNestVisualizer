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
    
    IBOutlet NSTextField *audioClipFileLabel;
    IBOutlet NSTextField *audioFileLabel;
    IBOutlet NSTextField *audioAnalysisLabel;
    
    IBOutlet NSTextField *currentTimeLabel;
    
    IBOutlet NSButton *playPauseButton;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)chooseAudioClipFileButtonPress:(id)sender;
- (IBAction)chooseAudioFileButtonPress:(id)sender;
- (IBAction)chooseAudioAnalysisButtonPress:(id)sender;

- (IBAction)skipBackButtonPress:(id)sender;
- (IBAction)playPauseButtonPress:(id)sender;
- (IBAction)zoomChange:(id)sender;

- (IBAction)timeCheckboxPress:(id)sender;
- (IBAction)sectionsCheckboxPress:(id)sender;
- (IBAction)barsCheckboxPress:(id)sender;
- (IBAction)beatsCheckboxPress:(id)sender;
- (IBAction)tatumsCheckboxPress:(id)sender;
- (IBAction)segmentsCheckboxPress:(id)sender;
- (IBAction)timbreCheckboxPress:(id)sender;
- (IBAction)pitchCheckboxPress:(id)sender;
- (IBAction)loudnessCheckboxPress:(id)sender;

@end
