/*
by Risa Sundu & David Shin
 References:
 - sparkfun tutorial for serial communication between Processing and Arduino: https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing/all#from-processing
 - cotterjk on stack overflow for pixel magnification: https://stackoverflow.com/questions/73562932/how-to-magnify-display-working-with-pixels-in-processing-java
 - creativecoding on p5.js for grid drawing: https://editor.p5js.org/creativecoding/sketches/duUe1NqJz
 - Nick Gammon on Gammon Forum for buffering serial input: https://www.gammon.com.au/forum/bbshowpost.php?bbsubject_id=11425&page=1
 Thanks also to Molly, Leo, Adin, & Colin @ UCSD's EnVision Maker Studio for lots of support & guidance
 */

/*to add:
 - slow down chaos mode
 - some type of abstract animation, or spiral, or raindrops??
 */

import processing.serial.*;
import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;
import org.opencv.core.Core;

Serial myPort;  // Create object from Serial class
Capture video;
OpenCV opencv;
//Rain drop;

PImage img = createImage(27, 24, RGB); // LED is 27 pixels wide x 24 pixels tall

int scaleFactor = 10;
boolean isSpacebarPressed = false; // Track the state of the spacebar
boolean isUpArrowPressed = false;
boolean isDownArrowPressed = false;
//boolean writtenSerial = false;
int BLUE = 50;
int RED = 110;
int TEAL = 10;

// vars for bounce animation
float xpos, ypos, xpos2, ypos2;
float speed = 8;

// vars for falling animation
int fallingSpeed = 2; // Speed of falling pixels
int fallCounter = 0;

int xdir = 1;
int ydir = 1;
int xdir2 = 1;
int ydir2 = -1;

// for rain
int x, y;

void setup()
{
  size(480 + 270, 480); // Adjusted to display video and LED matrix side by side
  video = new Capture(this, 480, 480);
  opencv = new OpenCV(this, 480, 480);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  video.start();

  frameRate(8);
  clearMatrix();
  noSmooth(); //for crisp resizing

  background(255);

  // for bounce animation
  xpos = (img.width*scaleFactor)/2;
  ypos = (img.height*scaleFactor)/2;
  xpos2 = (img.width*scaleFactor)/2 -5;
  ypos2 = (img.height*scaleFactor)/2 -5;

  // initialize serial communication
  String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 112500);
}

void draw() {
  if (video.available()) {
    video.read();
  }
  opencv.loadImage(video);
  // Display the video feed on the right side of the window
  image(video, img.width*scaleFactor, 0);

  // mirror image so moving left causes lights to move left
  //pushMatrix();
  //scale(-1,1);
  //image(video, -video.width-img.width*scaleFactor, 0);
  //popMatrix();

  // Clear the LED matrix at the start of each frame to remove previous detections
if (!isDownArrowPressed) {
  clearMatrix();
}
    



  if (isSpacebarPressed) {
    detectFace();
  } else if (isUpArrowPressed) {
    bounceAnimation();
  } else if (isDownArrowPressed) {
    animateFallingPixels();
    //fallingPixels();
  } else {
    activateRandomButtons();
  }
  //updatePixels();

  drawGrid();   //draw 27x24 grid for LED reference

  writeSerial(); //serial communication of color & position data w/ arduino
}

void keyPressed() {
  if (key == ' ') { // Check if the pressed key is the spacebar
    isSpacebarPressed = true;
  }
  if (key == CODED) {
    if (keyCode == UP) {
      isUpArrowPressed = true;
    }
    if (keyCode == DOWN) { // Check if the pressed key is the down arrow key
      isDownArrowPressed = true;
    }
  }
}

void keyReleased() {
  if (key == ' ') { // Check if the released key is the spacebar
    isSpacebarPressed = false;   
  }
  if (key == CODED) {
    if (keyCode == UP) {
      isUpArrowPressed = false;
    }
    if (keyCode == DOWN) { // Check if the released key is the down arrow key
      isDownArrowPressed = false;
    }
  }
}

void activateRandomButtons() {
  clearMatrix(); // Clear the matrix to start fresh
  int numPixelsToActivate = (img.width * img.height) / 10; // Activate 10% of the grid
  for (int i = 0; i < numPixelsToActivate; i++) {
    int randomX = int(random(img.width));
    int randomY = int(random(img.height));
    img.pixels[randomX + randomY * img.width] = color(100); // Randomly activate pixels
  }
  //img.updatePixels();
  updatePixels();
}

void writeSerial() {
  while (myPort.available() > 0) {
    print((char) myPort.read());
  }

  char data = (char)0;
  //print(red);
  //char startChar = char(10);
  //if (writtenSerial == false) {
  //  myPort.write(startChar);
  //    writtenSerial = true;
  //}
  for (int i = img.width-1; i >= 0; i--) {
    for (int j = img.height-1; j >= 0; j--) {
      if (img.pixels[i*img.height+j] == color(255)) {
        data = (char) 0;
      } else {
        data = (char)(img.pixels[i*img.height+j]);
      }
      myPort.write(data);
    }
  }
  char endChar = 0b11111111; // send end of matrix
  myPort.write(endChar);
  //writtenSerial = false;
  //println("writing end bit");
}

void updatePixels() {
  //img.loadPixels();

  img.updatePixels();
  image(img, 0, 0, img.width*scaleFactor, img.height*scaleFactor);
}

void drawGrid() {
  //draw 27x24 grid for LED reference
  for (int i = 0; i <= img.width*scaleFactor; i+=scaleFactor) {
    stroke(.25);
    line(i, 0, i, img.height*scaleFactor);
  }
  for (int j = 0; j <= img.height*scaleFactor; j+=scaleFactor) {
    line(0, j, img.width*scaleFactor, j);
  }
}

void clearMatrix() {
  //setup canvas: white = off
  img.loadPixels();
  for (int i = 0; i < img.width; i++) {
    for (int j = 0; j < img.height; j++) {
      img.pixels[i + j*img.width] = color(255);
    }
  }
}

void detectFace() {
  Rectangle[] faces = opencv.detect(); // Detect faces
  //trying to mirror camera
  //pushMatrix();
  //  scale(-1,1);

  for (Rectangle face : faces) {
    // Map face dimensions from video resolution to LED matrix resolution
    int ledX = int(map(face.x, 0, video.width, 0, img.width));
    int ledY = int(map(face.y, 0, video.height, 0, img.height));
    int ledW = int(map(face.width, 0, video.width, 0, img.width));
    int ledH = int(map(face.height, 0, video.height, 0, img.height));

    // Highlight the area within the face detection
    highlightFace(ledX, ledY, ledW, ledH);
  }
  //popMatrix();
}

void highlightFace(int x, int y, int w, int h) {

  for (int i = x; i < x + w; i++) {
    for (int j = y; j < y + h; j++) {
      if (i >= 0 && i < img.width && j >= 0 && j < img.height) {
        img.pixels[i + j * img.width] = color(BLUE); // Set color for simulated 'click'
      }
    }
  }
  // make face a little less rectangular
  img.pixels[x+y*img.width] = color(255);
  img.pixels[(x+w-1)+y*img.width] = color(255);
  img.pixels[x+(y+h-1)*img.width] = color(255);
  img.pixels[(x+w-1)+(y+h-1)*img.width] = color(255);

  //img.updatePixels();
    updatePixels();

}

void bounceAnimation() {
  //background(150);
  //println("bouncing!");

  // standard bounce (i.e. pong)
  xpos = xpos + (speed* xdir);
  ypos = ypos + (speed*ydir);
  xpos2 = xpos2 + (speed* xdir2);
  ypos2 = ypos2 + (speed*ydir2);

  // perlin noise movement
  //xpos = 300 * noise(0.005*frameCount) +50;
  //ypos = 300 * noise(0.005 * frameCount + 10000) + 50;

  if (xpos > img.width*scaleFactor - 10 || xpos < 10) {
    xdir *= -1;
  }
  if (ypos > img.height*scaleFactor - 10 || ypos < 10) {
    ydir *= -1;
  }
  if (xpos2 > img.width*scaleFactor - 10 || xpos2 < 10) {
    xdir2 *= -1;
  }
  if (ypos2 > img.height*scaleFactor - 10 || ypos2 < 10) {
    ydir2 *= -1;
  }

  for (int i = 0; i < img.width; i++) {
    for (int j = 0; j < img.height; j++) {
      if (xpos >= i*scaleFactor && xpos < i*scaleFactor+scaleFactor && ypos >= j*scaleFactor && ypos < j*scaleFactor+scaleFactor) {
        img.pixels[i + j*img.width] = color(RED);
      }
      if (xpos2 >= i*scaleFactor && xpos2 < i*scaleFactor+scaleFactor && ypos2 >= j*scaleFactor && ypos2 < j*scaleFactor+scaleFactor) {
        img.pixels[i + j*img.width] = color(TEAL);
      }
    }
  }
    updatePixels();
    //img.updatePixels();

}

//Rain drop(){
//  this.x = int(random(width));
//  this.y = int(random(height));
  
  
//}


//void fallingPixels() {
//  if (fallCounter % fallingSpeed == 0) {
//    for (int i =0; i < img.width; i++) {
//      if(random(1)<0.5){
//        img.pixels[i] = color(100);
//      }
//    }
//    for (int i=0;i<img.width;i++){
//      for(int j = 1;j<img.height;j++){
//        img.pixels[i + j *img.width] = img.pixels[i+(j-1)*img.width];
//      }
//    }
//  }
//  fallCounter++;
//  //updatePixels();
//  img.updatePixels();
//}

// FIX THIS!
//void animateFallingPixels() {
  
//  // Generate new pixels at the top row
//    for (int x = 0; x < img.width/2; x++) {
//      if (random(1) > 0.5) { // Randomly activate pixels
//        img.pixels[x] = color(255, 0, 0); // Set color to red
//      } else {
//        img.pixels[x] = color(255); // Set color to white (off)
//      }
//    }
    
//  if (fallCounter % fallingSpeed == 0) {
//    // Move all pixels down by one row
//    println(img.height);
//    for (int y = 0; y < img.height -1; y++) {
//      for (int x = 0; x < img.width; x++) {
//        int currentPixel = int(img.pixels[x + y * img.width]);
//        //println(color(currentPixel),color(255));
//        //if (currentPixel != color(255)) { // Check if the pixel is not white (active)
//          // Move the pixel down by one row
//          println("new row");
//          img.pixels[x + (y + 1) * img.width] = img.pixels[x + y * img.width];//color(255,0,0);//currentPixel;
//          img.pixels[x + y * img.width] = color(255); // Turn off the current pixel
//          delay(100);
//        //}
//      }
//    }
    
    //img.updatePixels();
//    updatePixels();
//  }
//  fallCounter++;
//}

void animateFallingPixels() {
  if (fallCounter % fallingSpeed == 0) {
    // Move all pixels down by one row
    println(img.height);
    for (int y = img.height - 2; y >= 0; y--) {
      for (int x = 0; x < img.width; x++) {
        int currentPixel = img.pixels[x + y * img.width];
        if (currentPixel != color(255)) { // Check if the pixel is not white (active)
          // Move the pixel down by one row
          img.pixels[x + (y + 1) * img.width] = currentPixel;
          img.pixels[x + y * img.width] = color(255); // Turn off the current pixel
        }
      }
    }
    // Generate new pixels at the top row
    for (int x = 0; x < img.width; x++) {
      if (random(1) > 0.5) { // Randomly activate pixels
        img.pixels[x] = color(RED); // Set color to red
      } else {
        img.pixels[x] = color(255); // Set color to white (off)
      }
    }
    //img.updatePixels();
    updatePixels();
  }
  fallCounter++;
}
