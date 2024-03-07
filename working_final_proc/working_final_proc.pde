/*
by Risa Sundu & David Shin
 References:
 - sparkfun tutorial for serial communication between Processing and Arduino: https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing/all#from-processing
 - cotterjk on stack overflow for pixel magnification: https://stackoverflow.com/questions/73562932/how-to-magnify-display-working-with-pixels-in-processing-java
 - creativecoding on p5.js for grid drawing: https://editor.p5js.org/creativecoding/sketches/duUe1NqJz
 - Nick Gammon on Gammon Forum for buffering serial input: https://www.gammon.com.au/forum/bbshowpost.php?bbsubject_id=11425&page=1
 Thanks also to Molly Tenino & Colin Zyskowski @ UCSD's EnVision Maker Studio for lots of support & guidance
 */

import processing.serial.*;
import controlP5.*;

Serial myPort;  // Create object from Serial class
ControlP5 cp5;

PImage img = createImage(27, 24, RGB); // LED is 27 pixels wide x 24 pixels tall

Slider redValue;
Slider greenValue;
Slider blueValue;

int scaleFactor = 10;

void setup()
{
  frameRate(10);

  // create color control sliders
  cp5 = new ControlP5(this);
  redValue = cp5.addSlider("Red Value").setSize(80, 10).setRange(0, 254).setPosition(10, 250).setColorLabel(0).setColorBackground(255).setValue(100);
  greenValue = cp5.addSlider("Green Value").setSize(80, 10).setRange(0, 254).setPosition(10, 265).setColorLabel(0).setColorBackground(255).setValue(100);
  blueValue = cp5.addSlider("Blue Value").setSize(80, 10).setRange(0, 254).setPosition(10, 280).setColorLabel(0).setColorBackground(255).setValue(100);

  //setup canvas: white = off
  img.loadPixels();
  for (int i = 0; i < img.width; i++) {
    for (int j = 0; j < img.height; j++) {
      img.pixels[i + j*img.width] = color(0);
    }
  }

  noSmooth(); //for crisp resizing
  size(270, 350); //make our canvas 10x [scaleFactor] size of LEDs in pixels
  background(255);
  //pixelDensity(2);

  // initialize serial communication
  String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 921600);
}

void draw() {
  updatePixels();
  //draw 27x24 grid for LED reference
  for (int i = 0; i <= img.width*scaleFactor; i+=scaleFactor) {
    stroke(.25);
    line(i, 0, i, img.height*scaleFactor);
  }
  for (int j = 0; j <= img.height*scaleFactor; j+=scaleFactor) {
    line(0, j, img.width*scaleFactor, j);
  }

  // color palette & slider previews
  color currColor = color(int(redValue.getValue()), int(greenValue.getValue()), int(blueValue.getValue()));
  redValue.setColorForeground(color(red(currColor), 0, 0)).setColorActive(color(red(currColor)+20, 0, 0));
  greenValue.setColorForeground(color(0, green(currColor), 0)).setColorActive(color(0, green(currColor)+20, 0));
  ;
  blueValue.setColorForeground(color(0, 0, blue(currColor))).setColorActive(color(0, 0, blue(currColor)+20));
  fill(currColor);
  rect(10, 295, 80, 30);
  fill(0);
  text("PREVIEW", 95, 310);

  //serial communication of color & position data w/ arduino
  //if (myPort.available() > 0) {
  //  myPort.clear();
  //}
  while (myPort.available() > 0) {
    print((char) myPort.read());
  }

  if (mousePressed) //if we clicked in the window
  {
    //sendColor(color(0,0,0));

    println("sent!");
    //char red = (char)0;
    //print(red);

    for (int i = img.height-1; i >= 0; i--) {
      for (int j = img.width-1; j >= 0; j--) {

        sendColor(img.pixels[i*img.width+j]);

        //if (img.pixels[i+j*img.width] == color(100)) {
        //print(char(int(red(img.pixels[i+j*img.width]))));

        // first try to send multiple colors
        //char red = char(int(red(img.pixels[i+j*img.width])));
        //char green = char(int(green(img.pixels[i+j*img.width])));
        //char blue = char(int(blue(img.pixels[i+j*img.width])));
        //myPort.write(red);
        //myPort.write(green);
        //myPort.write(blue);
        //TEST THIS!

        //initial testing of sending different color data
        //if (img.pixels[i*img.height +j] == color(100)) {
        //  red = (char) 100;//(( img.pixels[i + j*img.width] >> 16 & 0xFF) >> 1);
        //  //print("x");
        //} else if (img.pixels[i*img.height +j] == color(150)) {
        //  red = (char) 150;
        //} else {
        //  red = (char) 0;
        //  //print("o");
        //}

        //char red = (char) 100;//(( img.pixels[i + j*img.width] >> 16 & 0xFF) >> 1);
        //print(red);
      }
    }
    char startChar = 0b11111111; // send end of matrix
    myPort.write(startChar);
    println("writing end bit");
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

void sendColor(color input) {
  myPort.write(char(int(red(input))));
  print(char(int(red(input))));
  myPort.write(char(int(green(input))));
  print(char(int(green(input))));
  myPort.write(char(int(blue(input))));
  print(char(int(blue(input))));
}

void updatePixels() {
  img.loadPixels();

  noStroke();
  // fill pixels w/ color
  for (int i = 0; i < img.width; i++) {
    for (int j = 0; j < img.height; j++) {
      if (mousePressed) {
        if (mouseX >= i*scaleFactor && mouseX < i*scaleFactor+scaleFactor && mouseY >= j*scaleFactor && mouseY < j*scaleFactor+scaleFactor) {

          // testing multiple color values
          int red = int(redValue.getValue());
          int green = int(greenValue.getValue());
          int blue = int(blueValue.getValue());
          img.pixels[i + j*img.width] = color(red, green, blue);


          //print(img.pixels[i + j*img.width]);

          // testing single color value
          //if(img.pixels[i + j*img.width] == color(255)){
          //  img.pixels[i + j*img.width] = color(100);
          //}
          //else if(img.pixels[i + j*img.width] == color(100)){
          //  img.pixels[i + j*img.width] = color(150);
          //}
          //else{
          //  img.pixels[i + j*img.width] = color(255);
          //}
          print(i, j);
        }
      }
    }
  }

  img.updatePixels();
  image(img, 0, 0, img.width*scaleFactor, img.height*scaleFactor);
}
