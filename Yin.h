#ifndef Yin_h
#define Yin_h

#define SAMPLING_RATE

typedef struct _Yin {
	double threshold;
	int bufferSize;
	int halfBufferSize;
	float sampleRate;
	float* yinBuffer;
	float probability;
} Yin;

void Yin_init(Yin *yin, int bufferSize);

float Yin_getPitch(Yin *yin, float* buffer);

float Yin_getProbability(Yin *yin);
	


#endif
