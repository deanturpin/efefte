#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#include "../../include/keyq.h"
#include <vector>
#include <cmath>

@interface SpectrumView : NSView
@property (nonatomic) std::vector<float> magnitudes;
@property (nonatomic) fftw_plan fftPlan;
@property (nonatomic) fftw_complex* fftInput;
@property (nonatomic) fftw_complex* fftOutput;
@end

@implementation SpectrumView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _magnitudes.resize(256, 0.0f);

        // Setup FFT
        _fftInput = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * 512);
        _fftOutput = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * 512);
        _fftPlan = fftw_plan_dft_1d(512, _fftInput, _fftOutput, FFTW_FORWARD, FFTW_ESTIMATE);
    }
    return self;
}

- (void)dealloc {
    if (_fftPlan) fftw_destroy_plan(_fftPlan);
    if (_fftInput) fftw_free(_fftInput);
    if (_fftOutput) fftw_free(_fftOutput);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Black background
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);

    // Draw spectrum bars with logarithmic frequency axis
    NSRect bounds = self.bounds;

    [[NSColor greenColor] setFill];

    // Draw with logarithmic spacing - more space for lower frequencies
    int totalBars = 100; // Number of bars to display
    float pixelWidth = bounds.size.width / totalBars;

    for (int barIndex = 0; barIndex < totalBars; ++barIndex) {
        // Map bar position to FFT bin logarithmically
        // Use a simple power curve to map bar index to bin index
        float normalized = (float)barIndex / totalBars;
        float curved = normalized * normalized * normalized; // Cubic curve for log-like behavior
        int binIndex = (int)(curved * (_magnitudes.size() - 1));

        if (binIndex >= _magnitudes.size()) continue;

        // Better dynamic range: map -80dB to 0dB
        float normalizedHeight = (_magnitudes[binIndex] + 80.0f) / 80.0f;
        normalizedHeight = fmaxf(0.0f, fminf(1.0f, normalizedHeight));
        float height = normalizedHeight * bounds.size.height;

        float xPos = barIndex * pixelWidth;
        NSRect bar = NSMakeRect(xPos, 0, pixelWidth - 1, height);
        NSRectFill(bar);
    }
}

- (void)updateWithAudioBuffer:(float*)buffer length:(int)length {
    // Copy to FFT input
    for (int i = 0; i < std::min(length, 512); ++i) {
        _fftInput[i][0] = buffer[i];
        _fftInput[i][1] = 0.0;
    }

    // Execute FFT
    fftw_execute(_fftPlan);

    // Calculate magnitudes
    for (size_t i = 0; i < _magnitudes.size(); ++i) {
        float real = _fftOutput[i][0];
        float imag = _fftOutput[i][1];
        float magnitude = sqrtf(real * real + imag * imag);
        float db = 20.0f * log10f(magnitude + 1e-10f);
        _magnitudes[i] = _magnitudes[i] * 0.8f + db * 0.2f; // Smooth
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay:YES];
    });
}

@end

@interface AudioEngine : NSObject
@property (strong) AVAudioEngine* engine;
@property (weak) SpectrumView* spectrumView;
@end

@implementation AudioEngine

- (instancetype)initWithSpectrumView:(SpectrumView*)view {
    self = [super init];
    if (self) {
        _spectrumView = view;
        _engine = [[AVAudioEngine alloc] init];
        [self setupAudio];
    }
    return self;
}

- (void)setupAudio {
    NSLog(@"Setting up audio engine...");

    AVAudioInputNode* input = [_engine inputNode];
    AVAudioFormat* format = [input inputFormatForBus:0];

    NSLog(@"Input format: %@", format);
    NSLog(@"Sample rate: %.0f Hz", format.sampleRate);
    NSLog(@"Channel count: %d", format.channelCount);

    __weak SpectrumView* weakSpectrum = _spectrumView;

    // Install tap on input
    [input installTapOnBus:0
                bufferSize:512
                    format:format
                     block:^(AVAudioPCMBuffer* buffer, AVAudioTime* when) {

        float* channelData = buffer.floatChannelData[0];
        int frameLength = buffer.frameLength;

        // Calculate peak level for debugging
        float peak = 0.0f;
        for (int i = 0; i < frameLength; i++) {
            float sample = fabsf(channelData[i]);
            if (sample > peak) peak = sample;
        }

        static int logCounter = 0;
        if (++logCounter % 100 == 0) { // Log every 100 buffers
            NSLog(@"Audio buffer: %d frames, peak level: %.6f", frameLength, peak);
        }

        [weakSpectrum updateWithAudioBuffer:channelData length:frameLength];
    }];

    NSError* error = nil;
    [_engine startAndReturnError:&error];

    if (error) {
        NSLog(@"Error starting audio engine: %@", error.localizedDescription);

        // Try to request microphone permission
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                 completionHandler:^(BOOL granted) {
            if (granted) {
                NSLog(@"Microphone access granted");
            } else {
                NSLog(@"Microphone access denied - check System Preferences");
            }
        }];
    } else {
        NSLog(@"KEYQ Standalone: Audio engine started successfully");
    }
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong) NSWindow* window;
@property (strong) SpectrumView* spectrumView;
@property (strong) AudioEngine* audioEngine;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
    // Create window
    NSRect frame = NSMakeRect(0, 0, 800, 400);
    NSWindowStyleMask style = NSWindowStyleMaskTitled |
                              NSWindowStyleMaskClosable |
                              NSWindowStyleMaskMiniaturizable |
                              NSWindowStyleMaskResizable;

    _window = [[NSWindow alloc] initWithContentRect:frame
                                          styleMask:style
                                            backing:NSBackingStoreBuffered
                                              defer:NO];

    [_window setTitle:@"KEYQ Spectrum Analyser"];
    [_window center];

    // Create spectrum view
    _spectrumView = [[SpectrumView alloc] initWithFrame:frame];
    [_window setContentView:_spectrumView];

    // Start audio engine
    _audioEngine = [[AudioEngine alloc] initWithSpectrumView:_spectrumView];

    // Show window
    [_window makeKeyAndOrderFront:nil];

    // Add info label
    NSTextField* infoLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 10, 300, 20)];
    [infoLabel setStringValue:@"KEYQ FFT Library - Real-time Spectrum"];
    [infoLabel setBezeled:NO];
    [infoLabel setDrawsBackground:NO];
    [infoLabel setEditable:NO];
    [infoLabel setTextColor:[NSColor whiteColor]];
    [_spectrumView addSubview:infoLabel];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
    return YES;
}

@end

int main(int argc, const char* argv[]) {
    @autoreleasepool {
        NSApplication* app = [NSApplication sharedApplication];
        AppDelegate* delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        [app run];
    }
    return 0;
}