#pragma once

#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>
#include <vector>
#include <mutex>
#include "../../include/efefte.h"

// Audio Unit component description
#define KEYQ_COMP_TYPE 'aufx'  // Effect type
#define KEYQ_COMP_SUBTYPE 'efft'
#define KEYQ_COMP_MANUF 'Efft'

class KEYQAudioUnit {
public:
    KEYQAudioUnit();
    ~KEYQAudioUnit();

    // Core Audio Unit functions
    OSStatus Initialize();
    OSStatus Uninitialize();
    OSStatus Reset();

    // Audio processing
    OSStatus ProcessBufferLists(AudioUnitRenderActionFlags* ioActionFlags,
                                const AudioTimeStamp* inTimeStamp,
                                UInt32 inNumberFrames,
                                AudioBufferList* ioData);

    // Properties
    OSStatus GetPropertyInfo(AudioUnitPropertyID inID,
                            AudioUnitScope inScope,
                            AudioUnitElement inElement,
                            UInt32* outDataSize,
                            Boolean* outWritable);

    OSStatus GetProperty(AudioUnitPropertyID inID,
                        AudioUnitScope inScope,
                        AudioUnitElement inElement,
                        void* outData);

    OSStatus SetProperty(AudioUnitPropertyID inID,
                        AudioUnitScope inScope,
                        AudioUnitElement inElement,
                        const void* inData,
                        UInt32 inDataSize);

    // Get spectrum data for UI
    void GetSpectrumData(float* magnitudes, int binCount);

private:
    // FFT setup
    static constexpr int kFFTSize = 2048;
    fftw_plan fftPlan;
    fftw_complex* fftInput;
    fftw_complex* fftOutput;

    // Ring buffer for overlapping windows
    std::vector<float> ringBuffer;
    int writeIndex;

    // Spectrum data for visualisation
    std::vector<float> spectrumMagnitudes;
    std::mutex spectrumMutex;

    // Audio format
    Float64 sampleRate;
    UInt32 maxFramesPerSlice;

    // Window function
    std::vector<float> windowFunction;
    void CreateHannWindow();

    // Processing
    void ProcessFFT();
    void UpdateSpectrum();
};