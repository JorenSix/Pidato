#ifndef Yin_h
#define Yin_h

#define SAMPLING_RATE 44100
#define YIN_DEFAULT_THRESHOLD 0.15

typedef struct _Yin {
	int bufferSize;
	int halfBufferSize;
	float sampleRate;
	float* yinBuffer;
	float probability;
	float threshold;
} Yin;

void Yin_init(Yin *yin, int bufferSize, float threshold);

float Yin_getPitch(Yin *yin, int* buffer);

float Yin_getProbability(Yin *yin);
	


#endif
