#include "SPI.h";
#include "Adafruit_WS2801.h";

#define frameTime 100  //1000/10

uint8_t dataPin = 32;
uint8_t clockPin = 27;

int ledWidth = 27;
int ledHeight = 24;
const unsigned int PIXEL_LENGTH = 27 * 24;

String content = "";

Adafruit_WS2801 strip = Adafruit_WS2801((uint16_t)ledWidth, (uint16_t)ledHeight, dataPin, clockPin);

char val;         // Data received from the Serial port
int ledPin = 13;  // Set the pin to digital I/O 13


int col;  // recieving color data now

int red, green, blue;

int pixels[27 * 24];  //change to vars for readability; error

// #define SERIAL_SIZE_RX 4000

void setup() {
  pinMode(ledPin, OUTPUT);  // Set pin as OUTPUT
  Serial.begin(112500);     // Start Serial communication at 9600 bps
  // Serial.setRxBufferSize(SERIAL_SIZE_RX);

  strip.begin();
  strip.show();
}

unsigned int lastFrame = 0;

void loop() {
  while (Serial.available()) {  // If data is available to read,

    gridBuffer(Serial.read());
  }

  if ((millis() - lastFrame) >= frameTime) {
    lastFrame = millis();
    strip.show();
  }
}

// passed 1 "frame" worth of data, update 
void updateGrid(const char* data) {
  Serial.println("UPDATING GRID!");
  for (int i = 0; i < ledHeight; i++) {
    for (int j = 0; j < ledWidth; j++) {

      // 1st test sending color data
      col = data[i + j * ledWidth];
      if (col == char(150)) {
        strip.setPixelColor(i, j, col, 0, 0);

      } else if (col == char(100)) {
        strip.setPixelColor(i, j, 0, 0, col);

      } else {
        strip.setPixelColor(i, j, 0, 0, 0);
      }
    }
  }
}

// fill up 1 "frame" worth of data before changing pixel colors
void gridBuffer(const byte inByte) {
  static char input_line[PIXEL_LENGTH];
  static unsigned int input_pos = 0;

  switch (inByte) {
    case 0b11111111:  //end
      input_line[input_pos] = 0;
      updateGrid(input_line);
      input_pos = 0;
      break;

    default:
      if (input_pos < (PIXEL_LENGTH - 1)) {
        input_line[input_pos++] = (char)inByte;  // cast to char since Processing sends char
      }
      break;
  }
}