CC = gcc
CFLAGS = -std=c17 
CFLAGS_OPT = -O3 -ffast-math -march=native

TARGET = burning_ship

OBJS = main.o bmp.o burning_ship.o burning_ship_V1.o burning_ship_V2.o burning_ship_V3.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $@

main.o: main.c bmp.h burning_ship.h
	$(CC) $(CFLAGS) -D_POSIX_C_SOURCE=199309L -c main.c

bmp.o: bmp.c bmp.h
	$(CC) $(CFLAGS) -c bmp.c

burning_ship.o: burning_ship.s
	$(CC) -c burning_ship.s

burning_ship_V1.o: burning_ship_V1.s
	$(CC) -c burning_ship_V1.s

burning_ship_V2.o: burning_ship_V2.c
	$(CC) $(CFLAGS) -c burning_ship_V2.c

burning_ship_V3.o: burning_ship_V3.c
	$(CC) $(CFLAGS) $(CFLAGS_OPT) -c burning_ship_V3.c
clean:
	rm -f $(OBJS) $(TARGET)

