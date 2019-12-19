  import android.graphics.Point;

class Joystick {
  Point center;
  Point joyPos;
  boolean dragging;
  
  public int touchId=-1;
  private PApplet parent;
  private int joyRadius = 200;
  private int knobRadius = 40;
  private boolean circular = true;
  
  private int ctrlScale = (100*joyRadius) / (joyRadius-knobRadius);
  
  public Joystick(PApplet app, Point center) {
    parent=app;
    this.center=new Point(center);
    joyPos = new Point(center);
  }
  
  public Joystick setRectangularMode(boolean rectMode) {
    circular = !rectMode;
    return this;
  }
  
  public Joystick setRadius(int radius) {
    joyRadius = radius;
    ctrlScale = (100*joyRadius) / (joyRadius-knobRadius);
    return this;
  }
  public int getRadius() {
    return joyRadius;
  }
  
  public Joystick setKnobRadius(int radius) {
    knobRadius = radius;
    ctrlScale = (100*joyRadius) / (joyRadius-knobRadius);
    return this;
  }
  public int getKnobRadius() {
    return knobRadius;
  }
  
  private boolean hitTest(Point testPoint) {
    if (!circular) {
      if (testPoint.x > (joyPos.x - joyRadius) && testPoint.x < (joyPos.x + joyRadius)
        && testPoint.y > (joyPos.y - joyRadius) && testPoint.y < (joyPos.y + joyRadius)) {
          joyPos.x=testPoint.x;
          joyPos.y=testPoint.y;
          dragging=true;
          return true;
        }
        return false;
    }
    else {
      if (sqrt(pow(testPoint.x-joyPos.x, 2) + pow(testPoint.y-joyPos.y,2)) < knobRadius) {
        joyPos.x=testPoint.x;
        joyPos.y=testPoint.y;
        dragging=true;
        return true;
      }
      return false;
    }
  }
  
  private void setTouch(Point touch) {
    if (circular) {
      float angle = atan2(touch.y-center.y, touch.x-center.x);
      float length = sqrt(pow(touch.x-center.x, 2) + pow(touch.y-center.y,2))-knobRadius;
      length = min(length, joyRadius-knobRadius);
      joyPos.x = round(center.x + cos(angle)*length);
      joyPos.y = round(center.y + sin(angle)*length);
    }
    else {
      joyPos.x = constrain(touch.x, center.x-joyRadius, center.x+joyRadius);
      joyPos.y = constrain(touch.y, center.y-joyRadius, center.y+joyRadius);
    }
  }
  
  public Point getValue() {
    return new Point(
      (joyPos.x-center.x)*ctrlScale / joyRadius, 
      (center.y-joyPos.y)*ctrlScale / joyRadius
    ); 
  }
  
  private void releaseTouch() {
    joyPos.x = center.x;
    joyPos.y = center.y;
    dragging=false;
    touchId=-1;
  }
  
  private void run() {
     boolean touched=false;
    if (parent.touches.length > 0) {
      for (int i=0; i<touches.length; i++) {
         if (parent.touches[i].id == touchId) {
          setTouch(new Point((int)parent.touches[i].x, (int)parent.touches[i].y));
          touched=true;
          break;
         }
        else if (hitTest(new Point((int)parent.touches[i].x, (int)parent.touches[i].y))) {
          touchId=touches[i].id;
          setTouch(new Point((int)parent.touches[i].x, (int)parent.touches[i].y));
          touched=true;
          break;
        }
      }
    }
    if (!touched) {
      releaseTouch();
    }
  }
  
  void draw() {
    run();
    // background
    if (dragging) {
      stroke(200, 10, 10);
      fill(50, 30, 0);
    }
    else {
      stroke(200);
      fill(10);
    }
    if (circular) {
      ellipse(center.x, center.y, joyRadius*2, joyRadius*2);
    }
    else {
      rect(center.x-joyRadius, center.y-joyRadius, joyRadius*2, joyRadius*2);
    }
    noStroke();
    
    // knop
    fill(200);
    ellipse(joyPos.x, joyPos.y, knobRadius*2, knobRadius*2);
  }
}
