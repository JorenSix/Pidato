#include <Yin.h>

#define piny 1   // y

#define led 13 //indicator led

#define INIT_TIMER_COUNT 6
#define RESET_TIMER2 TCNT2 = INIT_TIMER_COUNT
 
long valy;
long yOffset;

//read buffer
float* buffer;
int bufferSize;//defines the lag and minimum detectable frequency
Yin yin;
int sampleRate; //How many samples of accelerometer data per second

float periodicity; // a value in [0-1] defining how periodic the movement is
float pitch;// the pitch, frequency of the movement in Hz
float previousPitch = -1;// the previously detected pitch, frequency of the movement in Hz

//counter used in interrupt
int int_counter;

//pitch bend vars
int decay;
long index = 0;//sample index to calculate sine
int maxBend = 16383;
int amplitude = maxBend / 1.5;
float pi = 3.14159265;
float twoPiF = 0;
float phase = 0;//in radians
int currentPitchBend = 8192;
int currentPower=0;
int maxPower=0;


//blink a led used for indicating things
void blink(){
  digitalWrite(led, HIGH );
  delay(100);
  digitalWrite(led, LOW);
}

ISR(TIMER2_OVF_vect) {
  RESET_TIMER2;
  int_counter += 1;
  if(int_counter  == 2){
    readAccelerometerDataWithFilter();
    currentPower -= abs(buffer[0]);
    for(int i = 0 ; i < bufferSize - 1 ; i++){
      buffer[i] = buffer[i+1];
    }
    buffer[bufferSize - 1] = valy;
    currentPower += abs(valy);
    int_counter = 0;
    
    //send pitch bend
    decay = decay * 0.90;
    if(decay>100){
      sendPitchBend();
    } else {
      if(currentPitchBend != 8192){
        int diff = abs(currentPitchBend - 8192) / 2 + 1;
        currentPitchBend = currentPitchBend > 8192 ? currentPitchBend - diff : currentPitchBend + diff;
        pitchBend(0,currentPitchBend);
      }
    }
  }
};

void setupTimerInterrupt(){
  int_counter = 0;
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
  //Serial.begin(115200);
  delay(100);
  Serial.flush();
}

void setup(){
  //use the led as output port
  pinMode(led, OUTPUT);
  
  //setup accelerometer
  //change ref v from 5 to 3.3V: divides 0-3.3V to 0-1023 instead of 0-5V  
  analogReference(EXTERNAL);
  calibrate();
  
  //setup yin
  bufferSize = 48;
  sampleRate = 125;
  //initialize buffer
  buffer = (float *) malloc(sizeof(float)* bufferSize);
  yin.initialize(sampleRate,bufferSize);
  
  //setup serial midi communication
  setupMidi();
  
  //setup interrupt
  setupTimerInterrupt();
}



void calibrate(){
  long runningSumY=0;
  int samples = 1024;
  for(int i = 0; i < samples ; i++){
    readAccelerometerData();
    runningSumY+=valy;
  }
  yOffset = runningSumY / samples;
}

void readAccelerometerDataWithFilter(){
  int runningSumY=0;
  int samples = 4;
  for(int i = 0 ; i < samples ; i++ ){
    readAccelerometerData();
    runningSumY+=valy;
  }
  valy = runningSumY >> 2;
  valy -= yOffset;
}

void readAccelerometerData(){
  valy = analogRead(piny);
}

void calculatePeriodicity(){
  pitch = yin.getPitch(buffer);
  periodicity = yin.getProbability();
}


void loop(){
  calculatePeriodicity();
  if(pitch > 0 && periodicity > 0.91){
    if(abs(previousPitch-pitch) > 0.5){
      //calculate the pase offset with
      //previous freauency
      phase = index / (float) sampleRate * twoPiF;
      //new two pi f
      twoPiF = 2 * pi * pitch;
      //reset index to get smooth frequency changes
      index = 0;
      //Serial.println(currentPower);
      
    }
    decay = 800;
    previousPitch = pitch;
    //Serial.println("reset");
  }
}


//MIDI MESSAGING======================================

void sendPitchBend(){
  float time = index / (float) sampleRate;
  //use the offset 
  float angle = time * twoPiF + phase;
  if(currentPower > maxPower)
    maxPower = currentPower;
  //Serial.print("Power: ");
  float scaler = currentPower/(float) maxPower;
  scaler = scaler * scaler;
  scaler = 0.5;
  float value = amplitude * scaler * sin(angle);
  int bendValue = value + 8192;
  currentPitchBend = bendValue;
  pitchBend(0,bendValue);
  //Serial.println(bendValue);
  index++;
}

void pitchBend(int channel,int bend){
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
  digitalWrite(led,HIGH);  // indicate we're sending MIDI data
  Serial.print(cmd, BYTE);
  Serial.print(data1, BYTE);
  Serial.print(data2, BYTE);
  digitalWrite(led,LOW);
}


