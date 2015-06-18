//
//  main.m
//  CAToneFileGenerator
//
//  Created by Jeff Vautin on 6/17/15.
//  Copyright © 2015 Jeff Vautin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define SAMPLE_RATE 44100
#define DURATION 5.0
#define FILENAME_FORMAT @"%0.3f - %@.aif"

typedef NS_ENUM(NSUInteger, Timbre) {
    kSquare,
    kSaw,
    kSine
};

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 3) {
            printf("Usage: CAToneFileGenerator n timbre\n(where n is tone in Hz, timbre = 0 (square), 1 (saw), 2 (sine))");
            return 1;
        }
        
        double hz = atof(argv[1]);
        assert(hz > 0);
        NSLog(@"generating %f hz tone", hz);
        
        Timbre timbre = atoi(argv[2]);
        NSString *timbreDescription;
        switch (timbre) {
            case kSquare:
                timbreDescription = @"square";
                break;
            case kSaw:
                timbreDescription = @"saw";
                break;
            case kSine:
                timbreDescription = @"sine";
                break;
                
            default:
                timbreDescription = @"";
                break;
        }
        NSLog(@"generating %@ wave",timbreDescription);
        
        NSString *fileName = [NSString stringWithFormat:FILENAME_FORMAT, hz, timbreDescription];
        NSString *filePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        
        // Prepare the format
        AudioStreamBasicDescription asbd;
        memset(&asbd, 0, sizeof(asbd)); // to set fields to 0
        asbd.mSampleRate = SAMPLE_RATE;
        asbd.mFormatID = kAudioFormatLinearPCM;
        asbd.mFormatFlags = kAudioFormatFlagIsBigEndian|kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
        asbd.mBitsPerChannel = 16;
        asbd.mChannelsPerFrame = 1;
        asbd.mFramesPerPacket = 1;
        asbd.mBytesPerFrame = 2;
        asbd.mBytesPerPacket = 2;
        
        // Set up the file
        AudioFileID audioFile;
        OSStatus audioErr = noErr;
        audioErr = AudioFileCreateWithURL((__bridge CFURLRef)fileURL,
                                          kAudioFileAIFFType,
                                          &asbd,
                                          kAudioFileFlags_EraseFile,
                                          &audioFile);
        assert(audioErr == noErr);
        
        // Start writing samples
        long maxSampleCount = SAMPLE_RATE * DURATION;
        long sampleCount = 0;
        UInt32 bytesToWrite = 2;
        double waveLengthInSamples = SAMPLE_RATE / hz;
        
        while (sampleCount < maxSampleCount) {
            for (int i=0; i<waveLengthInSamples; i++) {
                SInt16 sample;
                if (timbre == kSquare) {
                    // Square wave
                    if (i < waveLengthInSamples/2) {
                        sample = CFSwapInt16HostToBig(SHRT_MAX);
                    } else {
                        sample = CFSwapInt16HostToBig(SHRT_MIN);
                    }
                } else if (timbre == kSaw) {
                    // Saw wave
                    sample = CFSwapInt16HostToBig(((i / waveLengthInSamples) * SHRT_MAX * 2) - SHRT_MAX);
                } else if (timbre == kSine) {
                    // Sine wave
                    sample = CFSwapInt16HostToBig((SInt16)SHRT_MAX * sin(2 * M_PI * (i / waveLengthInSamples)));
                }
                audioErr = AudioFileWriteBytes(audioFile,
                                               false,
                                               sampleCount * 2,
                                               &bytesToWrite,
                                               &sample);
                assert(audioErr == noErr);
                sampleCount++;
            }
        }
        audioErr = AudioFileClose(audioFile);
        assert(audioErr == noErr);
        NSLog(@"wrote %ld samples", sampleCount);
    }
    return 0;
}
