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

// #define SERIAL_SIZE_RX 512

void setup() {
  pinMode(ledPin, OUTPUT);  // Set pin as OUTPUT
  Serial.begin(112500);       // Start Serial communication at 9600 bps
  // Serial.setRxBufferSize(SERIAL_SIZE_RX);
                            //  strip.setPixelColor(10, 7, 0,255,200);

  strip.begin();
  strip.show();
}

unsigned int lastFrame = 0;

void loop() {
  while (Serial.available()) {  // If data is available to read,
    gridBuffer(Serial.read());

    //MOLLY:
    // char start = Serial.read();
    // if (start == 0b11111111) {
    //   Serial.println("STARTEDDDD");
      
    //   Serial.println("");
    //   Serial.println("IMGDATA:");
    //   for (int i = 0; i < ledWidth; i++) {
    //     for (int j = 0; j < ledHeight; j++) {
    //       // char alpha = Serial.read();
    //       while (!Serial.available()){
    //         //do nothing until we recieve the entire screen buffer
    //       }
    //       char red = Serial.read();
    //       Serial.print(red);
    //       // char green = Serial.read();
    //       // char blue = Serial.read();
    //       // pixels[i + j*ledWidth] = col; // is this array even necessary? could just read data directly into 2D
    //       strip.setPixelColor(i,j,red,0,0);
    //     }
    //   }
    // }

    // Serial.print("BAD:");
    // Serial.println(start);
 
    // basicButton(); // for button test!
    // content += Serial.read();
  }
  // Serial.println(content);

  if ((millis() - lastFrame) >= frameTime) {
    lastFrame = millis();
    strip.show();
  }

  //  delay(10); // Wait 10 milliseconds for next reading
}

void updateGrid(const char* data) {
  Serial.println("UPDATING GRID!");
  for (int i = 0; i < ledWidth*3; i+=3) {
    for (int j = 0; j < ledHeight; j++) { // only 3 times more data not 9 ?
      
      // check the *3 weirdness... idk man i'm no computer
      red = data[i + j*ledWidth*3];
      green = data[(i + j*ledWidth*3)+1];
      blue = data[(i + j*ledWidth*3)+2];
      
      // pixels[i + j * ledWidth] = col;  // is this array even necessary? could just read data directly into 2D
      
      // col = data[i + j*ledWidth];
      // 1st test sending color data
      // if (col == char(150)){
      //   strip.setPixelColor(i, j, col, 0, 0);

      // }
      // else if (col == char(100)){
      //   strip.setPixelColor(i, j, 0, 0, col);

      // }
      // else{
      //   strip.setPixelColor(i,j,0,0,0);
      // }
    }
  }
  Serial.println (data);
}

void gridBuffer(const byte inByte) {
  static char input_line[PIXEL_LENGTH*3];
  static unsigned int input_pos = 0;

  switch (inByte) {
    case 0b11111111:  //end
      input_line[input_pos] = 0;
      updateGrid(input_line);
      input_pos = 0;
      break;

    default:
      if (input_pos < (PIXEL_LENGTH*3 - 1)) {
        input_line[input_pos++] = (char) inByte; // cast to char since Processing sends char
      }
      break;
  }
}

void basicButton() {
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
}