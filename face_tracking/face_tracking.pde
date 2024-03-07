import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;
import processing.serial.*;
import org.opencv.core.Core;

Capture video;
OpenCV opencv;
Serial myPort;  // Create object from Serial class
PImage img = createImage(27, 24, RGB);
int scaleFactor = 10; // Factor to scale up LED matrix for display

void setup() {
  size(640 + 270, 480); // Adjusted to display video and LED matrix side by side
  video = new Capture(this, 640, 480);
  opencv = new OpenCV(this, 640, 480);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  video.start();

  frameRate(10);
  clearLEDMatrix(); // Initialize LED matrix with all pixels turned off
  noSmooth(); // For crisp resizing of pixels

  println(Serial.list()); // Print available serial ports
  String portName = Serial.list()[0]; // Select the correct port for your setup
  myPort = new Serial(this, portName, 115200); // Adjust baud rate to match Arduino
}

void draw() {
  if (video.available()) {
    video.read();
  }
  opencv.loadImage(video);

  // Display the video feed on the left side of the window
  image(video, 0, 0);

  // Clear the LED matrix at the start of each frame to remove previous detections
  clearLEDMatrix();

  Rectangle[] faces = opencv.detect(); // Detect faces
  for (Rectangle face : faces) {
    // Map face dimensions from video resolution to LED matrix resolution
    int ledX = int(map(face.x, 0, video.width, 0, img.width));
    int ledY = int(map(face.y, 0, video.height, 0, img.height));
    int ledW = int(map(face.width, 0, video.width, 0, img.width));
    int ledH = int(map(face.height, 0, video.height, 0, img.height));

    // Highlight the area within the face detection
    highlightFaceArea(ledX, ledY, ledW, ledH);
  }

  // Draw the scaled-up LED matrix on the right side of the window
  image(img, 640, 0, 270, 240); // Adjusted position to be beside the video feed
  drawGrid();
}

void clearLEDMatrix() {
  img.loadPixels();
  for (int i = 0; i < img.pixels.length; i++) {
    img.pixels[i] = color(255); // Set all pixels to white (off)
  }
  img.updatePixels();
}

void highlightFaceArea(int x, int y, int w, int h) {
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

// Draws the grid lines for the LED matrix
void drawGrid() {
  for (int i = 640; i <= 640 + 270; i += scaleFactor) { // Adjust starting x position
    stroke(0);
    line(i, 0, i, 240); // Adjust grid height to match LED matrix display height
  }
  for (int j = 0; j <= 240; j += scaleFactor) { // Adjust grid height
    line(640, j, 640 + 270, j); // Adjust starting and ending x positions
  }
}
