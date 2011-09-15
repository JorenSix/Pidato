/*****************************************************************************************************************
*
* Pidato:     Vibrato on a Digital Piano Using an Arduino
* Date:       15/04/2011
* More info:  http://0110.be/artikels/lees/The_Pidato_Experiment%253A_Vibrato_on_a_Digital_Piano_Using_an_Arduino
*
*
*******************************************************************************************************************/

//include the YIN library for periodicity detection
#include <Yin.h>

//define some constants
#define piny 1   // analogue pin 1 = y axis
#define INIT_TIMER_COUNT 6
#define RESET_TIMER2 TCNT2 = INIT_TIMER_COUNT
#define LED 13
 
//accelerometer data
long valy;
long yOffset = 0;

//read buffer
float* buffer;
int bufferSize;//defines the lag and minimum detectable frequency
Yin yin;
int sampleRate; //How many samples of accelerometer data per second

float periodicity; // a value in [0-1] defining how periodic the movement is
float pitch;// the pitch, frequency of the movement in Hz
float previousPitch = -1;// the previously detected pitch, frequency of the movement in Hz

//counter used in interrupt
int readCounter = 0;
int pitchBendCounter = 0;


//MIDI channel to send messages on:
int midiChannel = 0;

//pitch bend vars
int decay;
long index = 0;//sample index to calculate sine
int maxBend = 16383;
int bendOffset = 8192;
int amplitude = maxBend   / 4.0;
float pi = 3.14159265;
float twoPiF = 0;
float phase = 0;//in radians
int currentPitchBend = 8192;



//interrupt call 
ISR(TIMER2_OVF_vect) {
  RESET_TIMER2;
  fillAndShiftBuffer();
  sendPitchBend();
};

void setupTimerInterrupt(){
  //Timer2 Settings: Timer Prescaler /256, WGM mode 0
  //((16 000 000 Hz) / 1024) / 256 = 61.0351562 hertz
  TCCR2A = 0;
  TCCR2B = 1<<CS22 | 1<<CS21;
  //Timer2 Overflow Interrupt Enable  
  TIMSK2 = 1<<TOIE2;
  //reset timer
  TCNT2 = 0;
}

void setupMidi(){
  pinMode(12, INPUT);     // switch for midi 31250 or 38400
  digitalWrite(12, HIGH); // Set inputs Pull-up resistors High
  
  pinMode(0,INPUT);
  pinMode(1, OUTPUT);   
  pinMode(2, OUTPUT); 
  pinMode(3, OUTPUT); 
  digitalWrite(3, LOW); // GND 0 Volt supply to opto-coupler
  digitalWrite(2, HIGH); // +5 Volt supply to opto-coupler
  
  //Serial.begin(38400);  //start serial with midi baudrate 38400 Roland MIDI
  Serial.begin(31250);  //start serial with midi baudrate 31250
}

void setup(){
  //setup accelerometer
  //change ref v from 5 to 3.3V: divides 0-3.3V to 0-1023 instead of 0-5V  
  //analogReference(EXTERNAL);
  pinMode(LED, OUTPUT);
  calibrate();
  
  //setup YIN
  bufferSize = 48;
  sampleRate = 125;
  //initialize buffer
  buffer = (float *) malloc(sizeof(float)* bufferSize);
  yin.initialize(sampleRate,bufferSize);
  
  //setup serial midi communication
  setupMidi();
  
  //setup interrupt
  setupTimerInterrupt();
  
  for(int i = 0 ; i < 4 ; i++){
    digitalWrite(LED,HIGH);
    delay(300);
    digitalWrite(LED,LOW);
    delay(300);
  }
}



//read a sample and store it in the buffer
//is called at a fixed samplerate from the interrupt
void fillAndShiftBuffer(){
 readCounter += 1;
 if(readCounter  == 2){
   readAccelerometerDataWithFilter();
   for(int i = 0 ; i < bufferSize - 1 ; i++){
     buffer[i] = buffer[i+1];
   }
   buffer[bufferSize - 1] = valy;
   readCounter = 0;
 }
}

// Calibrate the accelerometer readings: mean should be zero
void calibrate(){
  long runningSumY=0;
  int samples = 512;
  for(int i = 0; i < samples ; i++){
    valy = analogRead(piny);
    runningSumY+=valy;
  }
  yOffset = runningSumY / samples;
}

//read four samples and take the mean
void readAccelerometerDataWithFilter(){
  int runningSumY=0;
  int samples = 4;
  for(int i = 0 ; i < samples ; i++ ){
    valy = analogRead(piny);
    runningSumY+=valy;
  }
  valy = runningSumY >> 2;
  valy -= yOffset;
}


void loop(){
  //call YIN to determine periodicity and probability
  pitch = yin.getPitch(buffer);
  periodicity = yin.getProbability();
  digitalWrite(LED,LOW); 
  //if a pitch is detected and the signal is very periodic
  //start sending out pitch bend messages (decay set to 800)
  if(pitch > 0 && periodicity > 0.91){
    digitalWrite(LED,HIGH); 
    //if a big change in pitch (0.25Hz) calculate a new phase (offset) and 2 pi f;
    if(abs(previousPitch-pitch) > 0.25){
      //calculate the pase offset with
      //previous freauency
      phase = index / (float) sampleRate * twoPiF;
      //new two pi f
      twoPiF = 2 * pi * pitch;
      //reset index to get smooth frequency changes
      index = 0;
    }
    decay = 800;
    previousPitch = pitch;
  }
}


//MIDI MESSAGING======================================

void sendPitchBend(){
  pitchBendCounter += 1;
  if(pitchBendCounter  == 3){
    decay = decay * 0.88;
    if(decay>100){
      //calculate
      calculatePitchBend();
      //send
      pitchBend(midiChannel,currentPitchBend);
    } else if(currentPitchBend != bendOffset){
        int diff = abs(currentPitchBend - bendOffset) / 2 + 1;
        currentPitchBend = currentPitchBend > bendOffset ? currentPitchBend - diff : currentPitchBend + diff;
        pitchBend(midiChannel,currentPitchBend);
    }
    pitchBendCounter = 0;
  }
}

//calculate a pitch bend message
void calculatePitchBend(){
  float time = index / (float) sampleRate;
  //use the offset (phase)
  float angle = time * twoPiF + phase;
  float value = amplitude * sin(angle);
  int bendValue = value + bendOffset;
  currentPitchBend = bendValue;
  index++;
}

//send a pitch bend message on a channel
void pitchBend(int channel,int bend){
  //see http://tomscarff.110mb.com/midi_analyser/pitch_bend.htm:
  //   The two bytes of the pitch bend message form a 14 bit number,
  //   0 to 16383. The value 8192 (sent, LSB first, as 0x00 0x40), 
  //   is centered, or "no pitch bend." The value 0 (0x00 0x00) 
  //   means, "bend as low as possible," and, similarly, 16383
  //   (0x7F 0x7F) is to "bend as high as possible." The exact
  //   range of the pitch bend is specific to the synthesizer. 
  midiMsg((0xE0|channel),(bend & 0x7F),(bend >> 7));
}

// Send a MIDI note-on message.  Like pressing a piano key
void noteOn(byte channel, byte note, byte velocity) {
  midiMsg( (0x90 | channel), note, velocity);
}

// Send a MIDI note-off message.  Like releasing a piano key
void noteOff(byte channel, byte note, byte velocity) {
  midiMsg( (0x80 | channel), note, velocity);
}

// Send a general MIDI message
void midiMsg(byte cmd, byte data1, byte data2) {
  Serial.print(cmd, BYTE);
  Serial.print(data1, BYTE);
  Serial.print(data2, BYTE);
}


