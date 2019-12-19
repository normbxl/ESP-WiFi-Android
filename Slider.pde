import android.graphics.Point;

class Slider  {
  Point center;
  int sliderPos;
  int zeroPoint;
  boolean dragging;
  boolean resetOnRelease;
  
  public int touchId=-1;
  
  int sliderLength = 300;
  int sliderWidth = 50;
  int KNOB_SIZE = 100;
 
  private boolean horizontal;
  private PApplet parent;
  
  public Slider(PApplet parent, Point center, boolean horizontal, boolean resetOnRelease) {
    this.parent = parent;
    this.center = center;
    this.zeroPoint = horizontal ? center.x : center.y;
    this.horizontal = horizontal;
    this.resetOnRelease = resetOnRelease;
  }
  
  public Slider setZeroPoint(int zp) {
    zeroPoint = zp;
    return this;
  }
  
  public Slider setOrientation(boolean horizontal) {
    this.horizontal=horizontal;
    return this;
  }
  
  public boolean getOrientation() {
    return horizontal;
  }
  
  public Slider setLength(int l) {
    sliderLength = l;
    return this;
  }
  
  public int getLength() {
    return sliderLength;
  }
  
  public Slider setWidth(int w) {
    sliderWidth = w;
    return this;
  }
  public int getWidth() {
    return sliderWidth;
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
 
  public boolean hitTest(Point testPoint) {
    boolean hit=false;
    if (horizontal) {
      if (testPoint.x < center.x + sliderPos + KNOB_SIZE/2 
          && testPoint.x > center.x + sliderPos - KNOB_SIZE/2
          && testPoint.y > center.y - KNOB_SIZE/2
          && testPoint.y < center.y + KNOB_SIZE/2)
          {
            dragging=true;
            hit=true;
          }
    }
    else {
      if (testPoint.y < center.y + sliderPos + KNOB_SIZE/2 
          && testPoint.y > center.y + sliderPos - KNOB_SIZE/2
          && testPoint.x > center.x - KNOB_SIZE/2
          && testPoint.x < center.x + KNOB_SIZE/2)
          {
            dragging=true;
            hit=true;
          }
    }
    return hit;
  }
  
  private void setTouch(Point touch) {
    if (horizontal) {
      sliderPos = constrain(touch.x - center.x, -sliderLength/2 + KNOB_SIZE/2, sliderLength/2 - KNOB_SIZE/2);
    }
    else {
      sliderPos = constrain(touch.y - center.y, -sliderLength/2 + KNOB_SIZE/2, sliderLength/2 - KNOB_SIZE/2);
    }
  }
  
  public int getValue() {
    if (horizontal) {
      return (sliderPos*(sliderLength-KNOB_SIZE*2)) / (sliderLength - KNOB_SIZE);
    }
    else {
      return (-sliderPos*(sliderLength-KNOB_SIZE*2)) / (sliderLength - KNOB_SIZE);
    }
  }
  
  private void releaseTouch() {
    if (resetOnRelease) {
      sliderPos = 0;
    }
    dragging=false;
    touchId=-1;
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
    if (horizontal) {
      rect(center.x-sliderLength/2-2, center.y - sliderWidth/2 - 2, sliderLength+2, sliderWidth+2);
      noStroke();
      fill(200);
      rect(center.x+sliderPos-KNOB_SIZE/2, center.y-sliderWidth/2, KNOB_SIZE, sliderWidth);
    }
    else {
      rect(center.x-sliderWidth/2-2, center.y - sliderLength/2 - 2, sliderWidth+2, sliderLength+2);
      noStroke();
      fill(200);
      rect(center.x-sliderWidth/2, center.y+sliderPos-KNOB_SIZE/2, sliderWidth, KNOB_SIZE);
    }
  }
  
}
