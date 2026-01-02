CC = gcc
CFLAGES = -std=c11 -Wall -Wextra

TARGET = burning_ship_fractal

OBJS = main.o bmp.o burning_ship.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $@

main.o: main.c bmp.h burning_ship.h
	$(CC) $(CFLAGES) -c main.c

bmp.o: bmp.c bmp.h
	$(CC) $(CFLAGES) -c bmp.c

burning_ship.o: burning_ship.s
	$(CC) -c burning_ship.s
 
clean:
	rm -f $(OBJS) $(TARGET)
