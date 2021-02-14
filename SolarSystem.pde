PVector sun;

ArrayList<Planet> planets;

final float FAC_GRAV = 100000;
final float FAC_NEWP = 0.1;

final float SUN_RADIUS = 64;
final float SUN_MASS = 500;

final int timeStepsPerFrame = 10;

float newPlanetRadius;
color newPlanetColour;

PGraphics system;
PGraphics gizmos;

float barPos;

float wd3;
float colSegWidth;
float wd3csw;

//Settings -->
int trailLength = 100;
boolean trailTracking = true;
boolean trailHQ = true;
boolean simRunning = true;
boolean showHeadingLine = false;
boolean showProperties = false;
boolean showColourBar = true;

float mouseSize = 32;
PVector[] mouse = {new PVector(0, 0), new PVector(0, 1), new PVector(0.225, 0.839711), new PVector(0.5, 0.866025)};

void settings() {
  fullScreen(P2D); //P2D is needed for the trails
  smooth(2);
  PJOGL.setIcon("icon.png");
}

void setup() {
  colorMode(HSB);
  hint(ENABLE_ASYNC_SAVEFRAME);
  noCursor();

  system = createGraphics(width, height, P2D); //P2D is needed for the trails
  gizmos = createGraphics(width, height);

  wd3 = width/3;
  colSegWidth = wd3/128;
  wd3csw = wd3 + colSegWidth;

  sun = new PVector(width/2, height/2);
  planets = new ArrayList<Planet>();
  float barHeight = 12;
  barPos = height - barHeight;

  newPlanetRadius = 16;
  newPlanetColour = color(random(255), 255, 255);

  for (PVector p : mouse)
    p.mult(mouseSize).add(new PVector(1, 3));
}

float nPx, nPy;
float nPvx, nPvy;
void mousePressed() {
  //Start Coordinates -->
  nPx = mouseX;
  nPy = mouseY;
  simRunning = false;
}

void mouseReleased() {
  simRunning = true;
  if (nPy < barPos) {
    if (mouseButton == LEFT) {
      //Relative End Coordinates -->
      nPvx = nPx - mouseX;
      nPvy = nPy - mouseY;
      //Add Planet -->
      if (dist(nPx, nPy, sun.x, sun.y) > SUN_RADIUS) { //Not in sun
        planets.add(new Planet(nPx, nPy, nPvx, nPvy, random(30, 100), newPlanetRadius, newPlanetColour));
      }

      if (!simRunning) {
        showHeadingLine = true; //Spawned a new planet while paused makes heading lines show
      }
    }
  }
}

void draw() {
  system.beginDraw();
  system.colorMode(HSB);
  system.background(170, 100, 5);

  //Planets -->
  for (int t = 0; t < timeStepsPerFrame; t++) {
    for (int i = planets.size() - 1; i >= 0; i--) {
      Planet p = planets.get(i);
      if (!mousePressed && simRunning) {
        if (dist(p.pos, sun) < p.radius + SUN_RADIUS)
          planets.remove(i);

        p.applyForce(attractMass(p));
        p.update(1/float(timeStepsPerFrame));
      }
    }
  }

  //Sun -->
  system.noStroke();
  system.fill(32, 255, 255);
  system.circle(sun.x, sun.y, SUN_RADIUS *2);


  if (frameCount > 1)
    gizmos.clear();
  gizmos.beginDraw();
  gizmos.colorMode(HSB);

  for (Planet p : planets) //Planets contain both system and gizmos graphics
    p.render();
  system.endDraw();

  //Mouse Actions -->
  if (mousePressed) {
    if (nPy < barPos) {
      gizmos.stroke(255);
      gizmos.strokeWeight(3);
      gizmos.noFill();
      if (mouseButton == LEFT && dist(nPx, nPy, sun.x, sun.y) > SUN_RADIUS) { //Catapult Graphic
        gizmos.circle(nPx, nPy, newPlanetRadius *2);
        gizmos.strokeCap(ROUND);
        gizmos.line(nPx, nPy, nPx + FAC_NEWP*(nPx - mouseX), nPy + FAC_NEWP*(nPy - mouseY));
      } else if (mouseButton == RIGHT) { //Size Graphic
        newPlanetRadius = constrain(dist(nPx, nPy, mouseX, mouseY), 8, SUN_RADIUS*2/3);
        gizmos.circle(nPx, nPy, newPlanetRadius *2);
      }
    } else if (nPy > barPos && mouseX < wd3csw && showColourBar) {
      //Colour Picker Pop-Up
      newPlanetColour = color(map(mouseX, 0, wd3csw, 0, 255), 255, 255);
      gizmos.stroke(128);
      gizmos.strokeWeight(10);
      gizmos.fill(newPlanetColour);
      gizmos.rect(mouseX, barPos - 32, width/10, -width/10, 20);
    }
  }

  //Colour Picker Bar -->
  if (showColourBar) {
    gizmos.strokeWeight(colSegWidth);
    gizmos.strokeCap(SQUARE);
    for (float i = 0; i < wd3+1; i+=colSegWidth) {
      gizmos.stroke(map(i, 0, wd3, 0, 255), 255, 255, 200);
      gizmos.line(i + colSegWidth/2, barPos, i + colSegWidth/2, height);
    }
  }

  //Custom Cursor -->
  gizmos.pushMatrix();
  gizmos.translate(mouseX, mouseY);
  gizmos.noFill();
  gizmos.stroke(255, 128);
  gizmos.strokeWeight(3);
  gizmos.beginShape();
  for (PVector p : mouse)
    gizmos.vertex(p.x, p.y);
  gizmos.endShape(CLOSE);
  gizmos.stroke(255, 200);
  gizmos.strokeWeight(1);
  gizmos.beginShape();
  for (PVector p : mouse)
    gizmos.vertex(p.x, p.y);
  gizmos.endShape(CLOSE);
  gizmos.popMatrix();

  gizmos.endDraw();
  image(system, 0, 0);
  image(gizmos, 0, 0);
}

PVector attract(Planet p) {
  PVector f = PVector.sub(sun, p.pos);
  float d = f.mag();
  f.normalize();
  float s = FAC_GRAV / (d*d);
  f.mult(s);
  return f;
}

PVector attractMass(Planet p) {
  float m = SUN_MASS * p.mass;
  float rsq = sq(dist(sun, p.pos));
  float q = m/rsq;
  return PVector.sub(sun, p.pos).normalize().mult(q);
}

void keyPressed() {
  if (key == CODED) {
    switch(keyCode) {
    }
  } else {
    switch(key) {
    case ' ':
      simRunning = !simRunning;
      break;
    case 't':
      trailTracking = !trailTracking;
      break;
    case 'h':
      showHeadingLine = !showHeadingLine;
      break;
    case 'p':
      showProperties = !showProperties;
      break;
    case 'c':
      showColourBar = !showColourBar;
      break;
    case 'q':
      trailHQ = !trailHQ;
      break;
    case 'x': //remove a hovered over planet
      for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        if (dist(mouseX, mouseY, p.pos.x, p.pos.y) < p.radius) {
          planets.remove(i);
        }
      }
      break;
    case 'z': //remove offscreen planets
      for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        if (!p.onScreen) {
          planets.remove(i);
        }
      }
      break;
    case 's':
      system.save("/screenshots/" + year() + nf(month(), 2) + nf(day(), 2) + "_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + ".png");
      break;
    }
  }
}

float dist(PVector v1, PVector v2) {
  return dist(v1.x, v1.y, v2.x, v2.y);
}
