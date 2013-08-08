/* Use ./TestAudio/audioExtract.py to create audioData.h - this converts a wave file to an array of doubles in C.
 * Copy audioData.h into same folder as this test then build and run - the program should give F0 of the signal in
 * audioData.h */

#include "Yin.h"
#include <stdio.h>

/* Audio array with samples from .wav file */
#include "audioData.h"

#define SAMPLES_PER_ITERATION 4096
#define ITERATIONS 15

int main(int argc, char** argv) {

	
	
	float pitch;
	int counter = 0;
	for(counter = 0; counter < (SAMPLES_PER_ITERATION * ITERATIONS); counter += SAMPLES_PER_ITERATION)
	{
		pitch = dywapitch_computepitch(&tracker, audio, counter, SAMPLES_PER_ITERATION);	
	}
	
	printf("Pitch is found to be %f\n",pitch );
	return 0;
}