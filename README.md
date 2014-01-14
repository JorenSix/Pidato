# Yin Pitch Tracking
### Implementation of the Yin pitch detection algorithm in pure C

## Author
[Ashok Fernandez](https://github.com/ashokfernandez/)

## Acknowledgements

Thanks to [JorenSix](https://github.com/JorenSix/) for the original C++ implementation


## Description

The [YIN algorithm](http://audition.ens.fr/adc/pdf/2002_JASA_YIN.pdf) is a popular algorithm for tracking pitch (or the fundamental frequecy) of a monophonic audio signal. This project is an implementation of the Yin algorithm in C, suitable for embedded systems.

The code was ported to C from C++ from the [The Pidato Experiment](https://github.com/JorenSix/). The Pidato project was originally written for the Arduino platform, hence the C++. This is an attempt to port the algorithm implemented in the Pidato project to a more generic module in pure C, and has been used sucessfully in both embedded systems and high level applications.