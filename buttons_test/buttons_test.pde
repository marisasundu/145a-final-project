/*
by Risa Sundu & David Shin
References:
 - sparkfun tutorial for serial communication between Processing and Arduino: https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing/all#from-processing
 - cotterjk on stack overflow for pixel magnification: https://stackoverflow.com/questions/73562932/how-to-magnify-display-working-with-pixels-in-processing-java
 - creativecoding on p5.js for grid drawing: https://editor.p5js.org/creativecoding/sketches/duUe1NqJz
 Thanks to Molly Tenino & Colin Zyskowski @ UCSD's EnVision Maker Studio for lots of support & guidance
 */

import processing.serial.*;

Serial myPort;  // Create object from Serial class

PImage img = createImage(27, 24, RGB);

int scaleFactor = 10;


void setup()
{
  frameRate(10);

  //setup canvas: white = off
  img.loadPixels();
  for (int i = 0; i < img.width; i++) {
    for (int j = 0; j < img.height; j++) {
      img.pixels[i + j*img.width] = color(255);
    }
  }
  noSmooth(); //for crisp resizing
  size(270, 240); //make our canvas 10x size of LEDs in pixels
  background(255);
  //pixelDensity(2);
  String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 115200);
}

void draw() {
  updatePixels();
  //draw 27x24 grid for LED reference
  for (int i = 0; i < width; i+=scaleFactor) {
    stroke(.25);
    line(i, 0, i, height);
  }
  for (int j = 0; j < height; j+=scaleFactor) {
    line(0, j, width, j);
  }

  //serial communication of color & position data w/ arduino
  //if (myPort.available() > 0) {
  //  myPort.clear();
  //}
  while (myPort.available() > 0) {
    print((char) myPort.read());
  }

  if (mousePressed) //if we clicked in the window
  {
    print("sent!");
    //char red = 0;
    
    for (int i = 0; i < img.width; i++) {
      for (int j = 0; j < img.height; j++) {
        //if (img.pixels[i+j*img.width] == 100) {
        //  red = (char) 100;//(( img.pixels[i + j*img.width] >> 16 & 0xFF) >> 1);
        //}
        //else {
        //  red = (char) 10;
        //}
        char red = (char) 100;//(( img.pixels[i + j*img.width] >> 16 & 0xFF) >> 1);
        myPort.write(red);
        //print(red);

      }
    }
    char startChar = 0b11111111;
    myPort.write(startChar);
    // og button functionality
    //  if (mouseX < width/2) {
    //    myPort.write(255);
    //    println("255");
    //  } else {
    //    myPort.write('1');         //send a 1
    //    println("1");
    //  }
    //}
    //else if (!mousePressed)
    //{                           //otherwise
    //  myPort.write('0');
    //  println("0");//send a 0
    //}
  }
  }

  void updatePixels() {
    img.loadPixels();

    noStroke();
    // fill pixels w/ color
    for (int i = 0; i < img.width; i++) {
      for (int j = 0; j < img.height; j++) {
        if (mousePressed) {
          if (mouseX >= i*scaleFactor && mouseX < i*scaleFactor+scaleFactor && mouseY >= j*scaleFactor && mouseY < j*scaleFactor+scaleFactor) {
            img.pixels[i + j*img.width] = color(100);

           
          }
        }
      }
    }
    img.updatePixels();
    image(img, 0, 0, width, height);
  }
