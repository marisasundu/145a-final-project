import processing.serial.*;

Serial myPort;  // Create object from Serial class

void setup() 
{
  frameRate(40);
  size(200,200); //make our canvas 200 x 200 pixels big
  String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 9600);
}

void draw() {
  if (myPort.available() > 0){
    myPort.clear();
  }
  
  if (mousePressed == true) 
  {                           //if we clicked in the window
   myPort.write('1');         //send a 1
   println("1");   
  } else 
  {                           //otherwise
  myPort.write('0');
  println("0");//send a 0
  }   
}
