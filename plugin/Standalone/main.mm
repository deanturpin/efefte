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

    // Draw spectrum bars with logarithmic frequency scaling
    NSRect bounds = self.bounds;

    [[NSColor greenColor] setFill];

    // Logarithmic frequency mapping
    float minFreq = 20.0f;    // 20 Hz minimum
    float maxFreq = 20000.0f; // 20 kHz maximum
    float logMin = log10f(minFreq);
    float logMax = log10f(maxFreq);

    // Draw bars with logarithmic spacing
    int numBars = 128; // Number of visible bars
    for (int bar = 0; bar < numBars; ++bar) {
        // Map bar position to frequency logarithmically
        float barPos = (float)bar / numBars;
        float nextBarPos = (float)(bar + 1) / numBars;

        float logFreq = logMin + barPos * (logMax - logMin);
        float logFreqNext = logMin + nextBarPos * (logMax - logMin);

        float freq = powf(10.0f, logFreq);
        float freqNext = powf(10.0f, logFreqNext);

        // Convert frequency to FFT bin index
        float sampleRate = 44100.0f;
        int binIndex = (int)(freq / (sampleRate / 512.0f));
        int binIndexNext = (int)(freqNext / (sampleRate / 512.0f));

        if (binIndex >= _magnitudes.size()) break;

        // Average magnitude across bins for this bar
        float avgMagnitude = 0.0f;
        int binCount = 0;
        for (int bin = binIndex; bin < std::min(binIndexNext, (int)_magnitudes.size()); ++bin) {
            avgMagnitude += _magnitudes[bin];
            binCount++;
        }
        if (binCount > 0) avgMagnitude /= binCount;

        // Scale height with better dynamic range
        float height = (avgMagnitude + 80.0f) / 100.0f * bounds.size.height;
        height = fmaxf(0.0f, fminf(height, bounds.size.height)); // Clamp to prevent clipping

        float xPos = barPos * bounds.size.width;
        float barWidth = (nextBarPos - barPos) * bounds.size.width - 1;

        NSRect barRect = NSMakeRect(xPos, 0, barWidth, height);
        NSRectFill(barRect);
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

    // Calculate magnitudes with better smoothing
    for (size_t i = 0; i < _magnitudes.size(); ++i) {
        float real = _fftOutput[i][0];
        float imag = _fftOutput[i][1];
        float magnitude = sqrtf(real * real + imag * imag);
        float db = 20.0f * log10f(magnitude + 1e-10f);

        // Improved smoothing: faster rise, slower fall
        float smoothing = db > _magnitudes[i] ? 0.3f : 0.85f;
        _magnitudes[i] = _magnitudes[i] * smoothing + db * (1.0f - smoothing);
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
    NSTextField* infoLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 10, 400, 20)];
    [infoLabel setStringValue:@"KEYQ FFT - Logarithmic Spectrum (20Hz-20kHz)"];
    [infoLabel setBezeled:NO];
    [infoLabel setDrawsBackground:NO];
    [infoLabel setEditable:NO];
    [infoLabel setTextColor:[NSColor whiteColor]];
    [_spectrumView addSubview:infoLabel];

    // Add frequency markers
    NSArray* freqMarkers = @[@20, @50, @100, @200, @500, @1000, @2000, @5000, @10000, @20000];
    for (NSNumber* freq in freqMarkers) {
        float f = [freq floatValue];
        float logPos = (log10f(f) - log10f(20.0f)) / (log10f(20000.0f) - log10f(20.0f));
        float xPos = logPos * frame.size.width;

        NSTextField* marker = [[NSTextField alloc] initWithFrame:NSMakeRect(xPos - 20, frame.size.height - 25, 40, 20)];
        NSString* label = f >= 1000 ? [NSString stringWithFormat:@"%.0fk", f/1000] : [NSString stringWithFormat:@"%.0f", f];
        [marker setStringValue:label];
        [marker setBezeled:NO];
        [marker setDrawsBackground:NO];
        [marker setEditable:NO];
        [marker setTextColor:[NSColor grayColor]];
        [marker setAlignment:NSTextAlignmentCenter];
        [marker setFont:[NSFont systemFontOfSize:9]];
        [_spectrumView addSubview:marker];
    }
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