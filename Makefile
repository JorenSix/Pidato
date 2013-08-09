# Makefile to build Test_Yin program
# --- macros
CC=gcc
CFLAGS=  -g -Wall
OBJECTS= Test_Yin.o Yin.o

# --- targets
all:    Test_Yin
Test_Yin:   $(OBJECTS) 
	$(CC) -o Test_Yin  $(OBJECTS) $(LIBS)
        
Test_Yin.o: Test_Yin.c Yin.h
	$(CC) $(CFLAGS) -c Test_Yin.c
       
Yin.o: Yin.c Yin.h
	$(CC) $(CFLAGS) -c Yin.c 


# --- remove binary and executable files
clean:
	rm -f Test_Yin $(OBJECTS)