#include "SPI.h";
#include "Adafruit_WS2801.h";

#define frameTime 100  //1000/10

uint8_t dataPin = 32;
uint8_t clockPin = 27;

int ledWidth = 27;
int ledHeight = 24;

Adafruit_WS2801 strip = Adafruit_WS2801((uint16_t)ledWidth, (uint16_t)ledHeight, dataPin, clockPin);

char val;         // Data received from the Serial port
int ledPin = 13;  // Set the pin to digital I/O 13

int start;
int col; // recieving color data now

int pixels[27 * 24];  //change to vars for readability; error

void setup() {
  pinMode(ledPin, OUTPUT);  // Set pin as OUTPUT
  Serial.begin(9600);       // Start Serial communication at 9600 bps
                            //  strip.setPixelColor(10, 7, 0,255,200);

  strip.begin();
  strip.show();
}

unsigned int lastFrame = 0;

void loop() {
  while (Serial.available()) {     // If data is available to read,
    
    start = Serial.read();
    if (start == 300) {
      for (int i = 0; i < ledWidth; i++) {
        for (int j = 0; j < ledHeight; j++) {
          col = Serial.read();
          pixels[i + j*ledWidth] = col; // is this array even necessary? could just read data directly into 2D
          strip.setPixelColor(i,j,col,col,col);
        }
      }
    }
    
    val = Serial.read();           // read it and store it in val
    if (val == '1') {              // If 1 was received
      digitalWrite(ledPin, HIGH);  // turn the LED on
      strip.setPixelColor(10, 7, 0, 255, 200);


      Serial.println("on");
    }
    if (val == 255) {
      digitalWrite(ledPin, HIGH);  // turn the LED on
      strip.setPixelColor(10, 7, 255, 0, 0);
    }
    if (val == '0') {
      digitalWrite(ledPin, LOW);  // otherwise turn it off
      strip.setPixelColor(10, 7, 0, 0, 0);

      Serial.println('off');
    }
    // Serial.flush();
  }

  if ((millis() - lastFrame) >= frameTime) {
    lastFrame = millis();
    strip.show();
  }

  //  delay(10); // Wait 10 milliseconds for next reading
}