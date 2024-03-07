/*
by Risa Sundu & David Shin
 References:
 - sparkfun tutorial for serial communication between Processing and Arduino: https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing/all#from-processing
 - cotterjk on stack overflow for pixel magnification: https://stackoverflow.com/questions/73562932/how-to-magnify-display-working-with-pixels-in-processing-java
 - creativecoding on p5.js for grid drawing: https://editor.p5js.org/creativecoding/sketches/duUe1NqJz
 - Nick Gammon on Gammon Forum for buffering serial input: https://www.gammon.com.au/forum/bbshowpost.php?bbsubject_id=11425&page=1
 Thanks also to Molly, Leo, Adin, & Colin @ UCSD's EnVision Maker Studio for lots of support & guidance
 */

import processing.serial.*;
import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;
import org.opencv.core.Core;

Serial myPort;  // Create object from Serial class
Capture video;
OpenCV opencv;

PImage img = createImage(27, 24, RGB); // LED is 27 pixels wide x 24 pixels tall

int scaleFactor = 10;

void setup()
{
  size(480 + 270, 480); // Adjusted to display video and LED matrix side by side
  video = new Capture(this, 480, 480);
  opencv = new OpenCV(this, 480, 480);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  video.start();

  frameRate(10);
  clearMatrix();
  noSmooth(); //for crisp resizing

  background(255);

  // initialize serial communication
  String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 922190);
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
  clearMatrix();

  detectFace();

  updatePixels();

  drawGrid();   //draw 27x24 grid for LED reference

  writeSerial(); //serial communication of color & position data w/ arduino
}

void writeSerial() {
  while (myPort.available() > 0) {
    print((char) myPort.read());
  }


  char red = (char)0;
  //print(red);

  for (int i = img.width-1; i >= 0; i--) {
    for (int j = img.height-1; j >= 0; j--) {

      //initial testing of sending different color data
      if (img.pixels[i*img.height +j] == color(100)) {
        red = (char) 100;//(( img.pixels[i + j*img.width] >> 16 & 0xFF) >> 1);
        //print("x");
      } else if (img.pixels[i*img.height +j] == color(150)) {
        red = (char) 150;
      } else {
        red = (char) 0;
        //print("o");
      }
      myPort.write(red);
    }
  }
  char startChar = 0b11111111; // send end of matrix
  myPort.write(startChar);
  println("writing end bit");
}

void updatePixels() {
  img.loadPixels();

  noStroke();
  // fill pixels w/ color
  for (int i = 0; i < img.width; i++) {
    for (int j = 0; j < img.height; j++) {
      if (mousePressed) {
        if (mouseX >= i*scaleFactor && mouseX < i*scaleFactor+scaleFactor && mouseY >= j*scaleFactor && mouseY < j*scaleFactor+scaleFactor) {

          // testing single color value
          if (img.pixels[i + j*img.width] == color(255)) {
            img.pixels[i + j*img.width] = color(100);
          } else if (img.pixels[i + j*img.width] == color(100)) {
            img.pixels[i + j*img.width] = color(150);
          } else {
            img.pixels[i + j*img.width] = color(255);
          }
          print(i, j);
        }
      }
    }
  }

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
        img.pixels[i + j * img.width] = color(100); // Set color for simulated 'click'
      }
    }
  }
  // make face a little less rectangular
  img.pixels[x+y*img.width] = color(255);
  img.pixels[(x+w-1)+y*img.width] = color(255);
  img.pixels[x+(y+h-1)*img.width] = color(255);
  img.pixels[(x+w-1)+(y+h-1)*img.width] = color(255);

  img.updatePixels();
}
