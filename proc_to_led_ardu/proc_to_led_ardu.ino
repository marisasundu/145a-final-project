#include "SPI.h";
#include "Adafruit_WS2801.h";

#define frameTime 100  //1000/10

uint8_t dataPin = 32;
uint8_t clockPin = 27;

Adafruit_WS2801 strip = Adafruit_WS2801((uint16_t)27, (uint16_t)24, dataPin, clockPin);

char val;         // Data received from the Serial port
int ledPin = 13;  // Set the pin to digital I/O 13


void setup() {
  pinMode(ledPin, OUTPUT);  // Set pin as OUTPUT
  Serial.begin(9600);       // Start Serial communication at 9600 bps
                            //  strip.setPixelColor(10, 7, 0,255,200);

  strip.begin();
  strip.show();
}



unsigned int lastFrame = 0;

void loop() {
  while (Serial.available()) {  // If data is available to read,
    char startChar = Serial.read();

    if (startChar == char(60)) {
      int red = Serial.read();
      int green = Serial.read();
      int blue = Serial.read();

      strip.setPixelColor(10, 10, red, green, blue);
    }


    //og test (this works):
    // val = Serial.read(); // read it and store it in val
    // if (val == '1')
    // { // If 1 was received
    //  digitalWrite(ledPin, HIGH); // turn the LED on
    //  strip.setPixelColor(10, 7, 0,255,200);


    //    Serial.println("on");
    // }
    // if (val == '0')  {
    //  digitalWrite(ledPin, LOW); // otherwise turn it off
    //  strip.setPixelColor(10, 7, 0,0,0);

    //    Serial.println('off');
    // }

    //no:
    // Serial.flush();
  }


  if ((millis() - lastFrame) >= frameTime) {
    lastFrame = millis();
    strip.show();
  }




  //  delay(10); // Wait 10 milliseconds for next reading
}

// for tic tac toe (dif file)
// void drawGrid() {
//   uint16_t y, x;
//   for (y=0; y<23; y++) {
//     strip.setPixelColor(9,y,255,255,255);
//     strip.setPixelColor(17,y,255,255,255);

//     strip.show();
//   }
//   for (x=2; x<25; x++) {
//     strip.setPixelColor(x, 7, 255,255,255);
//     strip.setPixelColor(x,15,255,255,255);

//     strip.show();
//   }
// }