#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include "KEYQAudioUnit.h"
#include <cmath>
#include <algorithm>

// Constructor
KEYQAudioUnit::KEYQAudioUnit()
    : fftPlan(nullptr),
      fftInput(nullptr),
      fftOutput(nullptr),
      writeIndex(0),
      sampleRate(44100.0),
      maxFramesPerSlice(512) {

    // Allocate FFT buffers
    fftInput = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * kFFTSize);
    fftOutput = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * kFFTSize);

    // Create FFT plan
    fftPlan = fftw_plan_dft_1d(kFFTSize, fftInput, fftOutput, FFTW_FORWARD, FFTW_ESTIMATE);

    // Initialize ring buffer
    ringBuffer.resize(kFFTSize * 2, 0.0f);

    // Initialize spectrum
    spectrumMagnitudes.resize(kFFTSize / 2, 0.0f);

    // Create window function
    CreateHannWindow();
}

// Destructor
KEYQAudioUnit::~KEYQAudioUnit() {
    if (fftPlan) {
        fftw_destroy_plan(fftPlan);
    }
    if (fftInput) {
        fftw_free(fftInput);
    }
    if (fftOutput) {
        fftw_free(fftOutput);
    }
}

// Initialize
OSStatus KEYQAudioUnit::Initialize() {
    NSLog(@"KEYQ Audio Unit: Initialize");
    Reset();
    return noErr;
}

// Uninitialize
OSStatus KEYQAudioUnit::Uninitialize() {
    NSLog(@"KEYQ Audio Unit: Uninitialize");
    return noErr;
}

// Reset
OSStatus KEYQAudioUnit::Reset() {
    NSLog(@"KEYQ Audio Unit: Reset");

    // Clear ring buffer
    std::fill(ringBuffer.begin(), ringBuffer.end(), 0.0f);
    writeIndex = 0;

    // Clear spectrum
    std::lock_guard<std::mutex> lock(spectrumMutex);
    std::fill(spectrumMagnitudes.begin(), spectrumMagnitudes.end(), 0.0f);

    return noErr;
}

// Create Hann window
void KEYQAudioUnit::CreateHannWindow() {
    windowFunction.resize(kFFTSize);
    for (int i = 0; i < kFFTSize; ++i) {
        windowFunction[i] = 0.5f * (1.0f - cosf(2.0f * M_PI * i / (kFFTSize - 1)));
    }
}

// Process audio
OSStatus KEYQAudioUnit::ProcessBufferLists(AudioUnitRenderActionFlags* ioActionFlags,
                                             const AudioTimeStamp* inTimeStamp,
                                             UInt32 inNumberFrames,
                                             AudioBufferList* ioData) {

    // Process each channel
    for (UInt32 channel = 0; channel < ioData->mNumberBuffers; ++channel) {
        Float32* samples = (Float32*)ioData->mBuffers[channel].mData;

        // Copy samples to ring buffer
        for (UInt32 frame = 0; frame < inNumberFrames; ++frame) {
            ringBuffer[writeIndex] = samples[frame];
            writeIndex = (writeIndex + 1) % ringBuffer.size();

            // When we have enough samples, perform FFT
            if (writeIndex % (kFFTSize / 4) == 0) {  // 75% overlap
                ProcessFFT();
            }
        }

        // Pass through audio unchanged (analyser only, no processing)
        // If you want to process audio, modify samples here
    }

    return noErr;
}

// Perform FFT analysis
void KEYQAudioUnit::ProcessFFT() {
    // Copy windowed samples to FFT input
    int readIndex = (writeIndex - kFFTSize + ringBuffer.size()) % ringBuffer.size();

    for (int i = 0; i < kFFTSize; ++i) {
        float sample = ringBuffer[(readIndex + i) % ringBuffer.size()];
        fftInput[i][0] = sample * windowFunction[i];  // Real part with window
        fftInput[i][1] = 0.0;                         // Imaginary part
    }

    // Execute FFT
    fftw_execute(fftPlan);

    // Update spectrum
    UpdateSpectrum();
}

// Update spectrum magnitudes
void KEYQAudioUnit::UpdateSpectrum() {
    std::lock_guard<std::mutex> lock(spectrumMutex);

    // Calculate magnitudes for positive frequencies only
    for (int i = 0; i < kFFTSize / 2; ++i) {
        float real = fftOutput[i][0];
        float imag = fftOutput[i][1];
        float magnitude = sqrtf(real * real + imag * imag) / kFFTSize;

        // Convert to dB with smoothing
        float db = 20.0f * log10f(magnitude + 1e-10f);

        // Smooth with previous value
        spectrumMagnitudes[i] = spectrumMagnitudes[i] * 0.7f + db * 0.3f;
    }
}

// Get spectrum data for UI
void KEYQAudioUnit::GetSpectrumData(float* magnitudes, int binCount) {
    std::lock_guard<std::mutex> lock(spectrumMutex);

    int copyCount = std::min(binCount, (int)spectrumMagnitudes.size());
    std::copy(spectrumMagnitudes.begin(), spectrumMagnitudes.begin() + copyCount, magnitudes);
}

// Get property info
OSStatus KEYQAudioUnit::GetPropertyInfo(AudioUnitPropertyID inID,
                                          AudioUnitScope inScope,
                                          AudioUnitElement inElement,
                                          UInt32* outDataSize,
                                          Boolean* outWritable) {
    // Handle standard Audio Unit properties
    switch (inID) {
        case kAudioUnitProperty_ClassInfo:
            if (outDataSize) *outDataSize = sizeof(CFPropertyListRef);
            if (outWritable) *outWritable = false;
            return noErr;

        default:
            return kAudioUnitErr_InvalidProperty;
    }
}

// Get property
OSStatus KEYQAudioUnit::GetProperty(AudioUnitPropertyID inID,
                                      AudioUnitScope inScope,
                                      AudioUnitElement inElement,
                                      void* outData) {
    return kAudioUnitErr_InvalidProperty;
}

// Set property
OSStatus KEYQAudioUnit::SetProperty(AudioUnitPropertyID inID,
                                      AudioUnitScope inScope,
                                      AudioUnitElement inElement,
                                      const void* inData,
                                      UInt32 inDataSize) {
    return kAudioUnitErr_InvalidProperty;
}