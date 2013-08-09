/* Use ./TestAudio/audioExtract.py to create audioData.h - this converts a wave file to an array of doubles in C.
 * Copy audioData.h into same folder as this test then build and run - the program should give F0 of the signal in
 * audioData.h */

#include "Yin.h"
#include <stdio.h>

#define BUFFER_SIZE 5000

/* Audio array with samples from .wav file
 * contains 
 *     #define NUM_SAMPLES 176400 
 *     int audio[176400] = {...} 
 */
#include "audioData.h"


int main(int argc, char** argv) {
	int buffer_length = 100;
	Yin yin;
	float pitch;

	while (pitch < 10 ) {
		Yin_init(&yin, buffer_length, YIN_DEFAULT_THRESHOLD);
		pitch = Yin_getPitch(&yin, audio);	
		buffer_length++;
	}
	
	
	printf("Pitch is found to be %f with buffer length %i \n",pitch, buffer_length );
	return 0;
}