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
      maxFramesPerSlice(512),
      testTonePhase(0.0),
      silenceDetected(false) {

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

    // Debug: Log processing calls (limit spam)
    static int processCount = 0;
    if (++processCount % 1000 == 1) {
        NSLog(@"KEYQ ProcessBufferLists: frames=%u, buffers=%u, call #%d",
              inNumberFrames, ioData->mNumberBuffers, processCount);
    }

    // Detect silence in input
    bool hasSignal = false;
    for (UInt32 channel = 0; channel < ioData->mNumberBuffers && !hasSignal; ++channel) {
        Float32* samples = (Float32*)ioData->mBuffers[channel].mData;
        for (UInt32 frame = 0; frame < inNumberFrames; ++frame) {
            if (fabsf(samples[frame]) > 0.001f) {  // Threshold for silence
                hasSignal = true;
                break;
            }
        }
    }

    silenceDetected = !hasSignal;

    // Process each channel
    for (UInt32 channel = 0; channel < ioData->mNumberBuffers; ++channel) {
        Float32* samples = (Float32*)ioData->mBuffers[channel].mData;

        // Generate test tone when silent (440Hz + 880Hz)
        if (silenceDetected) {
            static int toneCount = 0;
            if (++toneCount % 1000 == 1) {
                NSLog(@"KEYQ: Generating test tone (call #%d)", toneCount);
            }
            for (UInt32 frame = 0; frame < inNumberFrames; ++frame) {
                double time = testTonePhase / sampleRate;
                float testTone = 0.1f * (sinf(2.0f * M_PI * 440.0f * time) +
                                        0.5f * sinf(2.0f * M_PI * 880.0f * time));
                samples[frame] = testTone;
                testTonePhase += 1.0;
                if (testTonePhase >= sampleRate) testTonePhase -= sampleRate;
            }
        }

        // Copy samples to ring buffer for analysis
        for (UInt32 frame = 0; frame < inNumberFrames; ++frame) {
            ringBuffer[writeIndex] = samples[frame];
            writeIndex = (writeIndex + 1) % ringBuffer.size();

            // When we have enough samples, perform FFT (less frequent for stability)
            if (writeIndex % kFFTSize == 0) {  // No overlap for now
                static int fftTriggerCount = 0;
                NSLog(@"KEYQ: Triggering FFT processing (call #%d)", ++fftTriggerCount);
                ProcessFFT();
            }
        }
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
    float maxMagnitude = -100.0f;
    int peakBin = 0;

    for (int i = 0; i < kFFTSize / 2; ++i) {
        float real = fftOutput[i][0];
        float imag = fftOutput[i][1];
        float magnitude = sqrtf(real * real + imag * imag) / kFFTSize;

        // Convert to dB with smoothing
        float db = 20.0f * log10f(magnitude + 1e-10f);

        // Smooth with previous value
        spectrumMagnitudes[i] = spectrumMagnitudes[i] * 0.7f + db * 0.3f;

        // Track peak for debugging
        if (spectrumMagnitudes[i] > maxMagnitude) {
            maxMagnitude = spectrumMagnitudes[i];
            peakBin = i;
        }
    }

    // Log peak frequency (every 100 FFTs to avoid spam)
    static int fftCount = 0;
    if (++fftCount % 100 == 0) {
        float peakFreq = (float)peakBin * sampleRate / kFFTSize;
        NSLog(@"KEYQ FFT: Peak at %.1f Hz (%.1f dB) %s",
              peakFreq, maxMagnitude, silenceDetected ? "[TEST TONE]" : "[LIVE AUDIO]");
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