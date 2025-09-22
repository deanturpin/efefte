#import <AudioUnit/AUAudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#include "EFEFTEAudioUnit.h"

@interface EFEFTEAudioUnitWrapper : AUAudioUnit
@property (nonatomic) EFEFTEAudioUnit* cppAudioUnit;
@property (nonatomic, strong) AUAudioUnitBus* outputBus;
@property (nonatomic, strong) AUAudioUnitBusArray* inputBusArray;
@property (nonatomic, strong) AUAudioUnitBusArray* outputBusArray;
@end

@implementation EFEFTEAudioUnitWrapper {
    AVAudioPCMBuffer* _inputBuffer;
}

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription
                                      options:(AudioComponentInstantiationOptions)options
                                        error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];

    if (self) {
        // Create C++ Audio Unit
        _cppAudioUnit = new EFEFTEAudioUnit();

        // Create default format
        AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100
                                                                            channels:2];

        // Create bus
        _outputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:nil];

        // Create bus arrays
        _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
                                                                 busType:AUAudioUnitBusTypeOutput
                                                                  busses:@[_outputBus]];

        // Initialize
        _cppAudioUnit->Initialize();
    }

    return self;
}

- (void)dealloc {
    if (_cppAudioUnit) {
        _cppAudioUnit->Uninitialize();
        delete _cppAudioUnit;
    }
}

- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (![super allocateRenderResourcesAndReturnError:outError]) {
        return NO;
    }

    _inputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_outputBus.format
                                                  frameCapacity:self.maximumFramesToRender];

    return YES;
}

- (void)deallocateRenderResources {
    [super deallocateRenderResources];
    _inputBuffer = nil;
}

- (AUInternalRenderBlock)internalRenderBlock {
    __block EFEFTEAudioUnit* cppUnit = _cppAudioUnit;

    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags* actionFlags,
                             const AudioTimeStamp* timestamp,
                             AVAudioFrameCount frameCount,
                             NSInteger outputBusNumber,
                             AudioBufferList* outputData,
                             const AURenderEvent* realtimeEventListHead,
                             AURenderPullInputBlock pullInputBlock) {

        // Pull input
        AudioUnitRenderActionFlags pullFlags = 0;
        AUAudioUnitStatus err = pullInputBlock(&pullFlags, timestamp, frameCount, 0, outputData);

        if (err != noErr) {
            return err;
        }

        // Process with EFEFTE
        cppUnit->ProcessBufferLists(&pullFlags, timestamp, frameCount, outputData);

        return noErr;
    };
}

@end

// Factory function
extern "C" void* EFEFTEAudioUnitFactory(const AudioComponentDescription* inDesc) {
    EFEFTEAudioUnitWrapper* audioUnit = [[EFEFTEAudioUnitWrapper alloc]
                                         initWithComponentDescription:*inDesc
                                         options:0
                                         error:nil];
    return (__bridge_retained void*)audioUnit;
}