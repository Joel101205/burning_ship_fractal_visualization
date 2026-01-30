CC = gcc
CFLAGS = -std=c17 
CFLAGS_OPT = -O3 -ffast-math -march=native

SRC = src
BUILD = build

TARGET = burning_ship

OBJS = 	$(BUILD)/main.o \
		$(BUILD)/bmp.o \
		$(BUILD)/burning_ship.o \
		$(BUILD)/burning_ship_V1.o \
		$(BUILD)/burning_ship_V2.o \
		$(BUILD)/burning_ship_V3.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $@

$(BUILD)/main.o: $(SRC)/main.c $(SRC)/bmp.h $(SRC)/burning_ship.h
	mkdir -p $(BUILD) 
	$(CC) $(CFLAGS) -D_POSIX_C_SOURCE=199309L -c $< -o $@

$(BUILD)/bmp.o: $(SRC)/bmp.c $(SRC)/bmp.h
	mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/burning_ship.o: $(SRC)/burning_ship.s
	mkdir -p $(BUILD)
	$(CC) -c $< -o $@

$(BUILD)/burning_ship_V1.o: $(SRC)/burning_ship_V1.s
	mkdir -p $(BUILD)
	$(CC) -c $< -o $@

$(BUILD)/burning_ship_V2.o: $(SRC)/burning_ship_V2.c
	mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/burning_ship_V3.o: $(SRC)/burning_ship_V3.c
	mkdir -p $(BUILD)
	$(CC) $(CFLAGS) $(CFLAGS_OPT) -c $< -o $@

clean:
	rm -rf $(BUILD) $(TARGET)
