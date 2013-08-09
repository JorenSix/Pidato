import wave, struct
import matplotlib.pyplot as plt

filename = "OpenE.wav"

# Open the .wav files and extract all the frames
waveFile = wave.open(filename, 'r')
length = waveFile.getnframes()


audioData = []

# Extract all the samples from the audio file into an array
for i in range(0,length):    
    waveData = waveFile.readframes(1)
    data = struct.unpack("<h", waveData)
    audioData.append(data[0])

# Truncate the samples we don't need
audioData = audioData[1000:2500]

# Plot the signal
plt.plot(audioData)
plt.title("Original Audio Signal")
plt.show()



# SCALE THE SAMPLES TO A NEW BIT RATE
max16Bit = (2 ** 16) / 2 # - Over two because it's +/-16bits (half positive, half negative)

# Figure out what the max value is for the desired bit level
desiredBits = 10
maxDesired = (2 ** desiredBits) / 2

# Now loop thorugh all vales, normalise them to 1 then scale to the new max value
for i in range(len(audioData)):
	normalisedSample = float(audioData[i]) / max16Bit
	scaledSample = int(normalisedSample * maxDesired)
	audioData[i] = scaledSample

# Plot the scaled signal
plt.plot(audioData)
plt.title("Scaled Audio Signal")
plt.show()


# Write the first line to the .h file with an integer array of the samples and a #define with the number of samples
f = open('audioData.h','w')
f.write('#define NUM_SAMPLES %i \n\n' % len(audioData))
f.write('int16_t audio[%i] = {\n' % len(audioData))

# Write all lines except the last one
for sample in audioData[:-1]:
	f.write('   %i,\n' % sample)

# Write the final line
f.write('   %i};' % audioData[-1])

# Close the file
f.close()
