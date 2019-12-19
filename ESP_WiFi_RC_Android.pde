import hypermedia.net.*;

import android.graphics.Point;

Joystick joystick;
Slider slider1;
//Slider slider2;
DeviceLink link;

PFont font;
static final int JOYSTICK_RADIUS = 300;
void setup() {
  orientation(LANDSCAPE);
  font = createFont("ProcessingSansPro-Regular-24", 24 * displayDensity);
  textFont(font);
  fullScreen();
  joystick = new Joystick(this, new Point(width - JOYSTICK_RADIUS - width/12, height/2));
  joystick.setRadius(JOYSTICK_RADIUS);
  joystick.setRectangularMode(true);
  
  slider1 = new Slider(this, new Point( width/4, height/2), false, false);
  slider1
    .setLength((int)(height*0.8))
    .setWidth(120);
    
  //slider2 = new Slider(this, new Point((int)(width*0.7) , height/2), true, false);
  //slider2
  //  .setLength((int)(width*0.4))
  //  .setWidth(120);
  
  
  link = new DeviceLink(getContext());
  //link.connect("192.168.2.1");
  
}


void draw() {
  Point joyCtrl;
  background(0);
  
  
  joystick.draw();
  slider1.draw();
  //slider2.draw();
  
  //text(joystick.getCtrl().x, Joystick.JOY_RADIUS*2+20, height/2);
  //text(joystick.getCtrl().y, Joystick.JOY_RADIUS, height-70);
  
  
  if (link.isConnected()) {
    joyCtrl = joystick.getValue();
    link.setOutput(DevicePort.M1, (max(0, slider1.getValue()*127)/100));
    link.setOutput(DevicePort.M2, (joyCtrl.y *127)/100);
    link.setOutput(DevicePort.S1, joyCtrl.x );
    link.sendControlUpdate();
    text(link.getRemoteIp(), 20, height-25);
  }
  
}

void backPressed() {
  link.close();
  exit();
}
