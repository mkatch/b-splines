import processing.pdf.*;

final float POINT_RADIUS = 7;
final float SLIDER_SIZE = 5;
final color WHITE = #FFFFFF;
final color LIGHT = #E3F4F5;
final color MIDDLE = #D3E0E0;
final color DARK = #50A2A2;

ICurve curve;
PVector translation;
float zoom;
float sliderBegX;
float sliderEndX;
float sliderY;
float blossomParam = 0.5;
int hoverPoint = -1;
int hoverKnot = -1;
boolean hoverBlossomParam = false;

void setup() {
    size(800, 600);//, PDF, "/Users/mkacz/Desktop/spline.pdf");
    sliderBegX = 100;
    sliderEndX = width - 100;
    sliderY = height - 100;
    translation = new PVector(width / 2, sliderY / 2);
    zoom = 0.2 * width;
    ellipseMode(RADIUS);
    textAlign(LEFT, TOP);
    
    curve = new BSpline();
    
    loop();
}

PVector lerp(PVector u, PVector v, float alpha) {
    PVector w = PVector.mult(u, 1 - alpha);
    w.add(PVector.mult(v, alpha));
    return w;
}

float clamp(float x, float a, float b) {
    return max(a, min(b, x));
}

PVector toView(PVector v) {
    PVector u = PVector.mult(v, zoom);
    u.add(translation);
    return u;
}

PVector toScene(PVector v) {
    PVector u = PVector.sub(v, translation);
    u.div(zoom);
    return u;
}

PVector toSlider(float t) {
    return new PVector(lerp(sliderBegX, sliderEndX, t), sliderY);
}

float fromSlider(float x) {
    return (x - sliderBegX) / (sliderEndX - sliderBegX);
}

void draw() {
    background(LIGHT);
    
    final int pointCnt = curve.getPointCnt();
    final int degree = curve.getDegree();
    final float minParam = curve.getMinParam();
    final float maxParam = curve.getMaxParam();
    
    // Draw control polygon
    stroke(MIDDLE);
    strokeWeight(1);
    noFill();
    beginShape();
    for (int i = 0; i < pointCnt; ++i) {
        PVector p = toView(curve.getPoint(i));
        vertex(p.x, p.y);
    }
    endShape();
    
    // Draw blossom polygon
    if (curve.providesBlossom()) {
        stroke(MIDDLE);
        strokeWeight(1);
        PVector[][] blossom = curve.getBlossom(blossomParam);
        for (int i = 0; i < blossom.length; ++i) {
            noFill();
            beginShape();
            for (int j = 0; j < blossom[i].length; ++j) {
                PVector p = toView(blossom[i][j]);
                vertex(p.x, p.y);
            }
            endShape();
        }
    }
    
    // Draw curve
    stroke(DARK);
    strokeWeight(3);
    noFill();
    beginShape();
    for (int i = 0; i <= 100; ++i) {
        float t = lerp(minParam, maxParam, float(i) / float(100));
        PVector p = toView(curve.eval(t));
        vertex(p.x, p.y); 
    }
    endShape();
    
    // Draw control points
    stroke(MIDDLE);
    strokeWeight(2);
    for (int i = 0; i < pointCnt; ++i) {
        PVector p = toView(curve.getPoint(i));
        fill(i == hoverPoint ? MIDDLE : WHITE);
        ellipse(p.x, p.y, POINT_RADIUS, POINT_RADIUS);
    }
    
    if (curve.providesBlossom() || curve.hasKnots()) {
        // Draw slider bar
        stroke(MIDDLE);
        strokeWeight(1);
        line(sliderBegX, sliderY, sliderEndX, sliderY);
        stroke(DARK);
        strokeWeight(3);
        float paramBegX = lerp(sliderBegX, sliderEndX, minParam);
        float paramEndX = lerp(sliderBegX, sliderEndX, maxParam);
        line(paramBegX, sliderY, paramEndX, sliderY);
    }
    
    if (curve.hasKnots()) {
        // Draw knot sliders
        final int knotCnt = curve.getKnotCnt();
        stroke(MIDDLE);
        strokeWeight(1);
        for (int i = 0; i < knotCnt; ++i) {
            PVector k = toSlider(curve.getKnot(i));
            fill(i == hoverKnot ? MIDDLE : WHITE);
            beginShape();
                vertex(k.x, k.y);
                vertex(k.x - SLIDER_SIZE, k.y - SLIDER_SIZE);
                vertex(k.x - SLIDER_SIZE, k.y - 3 * SLIDER_SIZE);
                vertex(k.x + SLIDER_SIZE, k.y - 3 * SLIDER_SIZE);
                vertex(k.x + SLIDER_SIZE, k.y - SLIDER_SIZE);
            endShape(CLOSE);
        };
    }
    
    if (curve.providesBlossom()) {
        // Draw blossom
        PVector b = toSlider(blossomParam);
        stroke(MIDDLE);
        strokeWeight(1);
        fill(hoverBlossomParam ? MIDDLE : WHITE);
        beginShape();
            vertex(b.x, b.y);
            vertex(b.x + SLIDER_SIZE, b.y + SLIDER_SIZE);
            vertex(b.x + SLIDER_SIZE, b.y + 3 * SLIDER_SIZE);
            vertex(b.x - SLIDER_SIZE, b.y + 3 * SLIDER_SIZE);
            vertex(b.x - SLIDER_SIZE, b.y + SLIDER_SIZE);
        endShape(CLOSE);
    }
    
    // Draw info text
    fill(DARK);
    noStroke();
    String info =
        "name: " + curve.getName() + "\n" +
        "degree: " + curve.getDegree() + "\n" +
        "control points: " + pointCnt + "\n" +
        (curve.hasKnots() ? "knots: " + curve.getKnotCnt() + "\n" : "");
    text(info, 10, 10);
    
}

PVector getMousePos() { return new PVector(mouseX, mouseY); }

void mouseMoved() {
    PVector pos = getMousePos();
    
    // We search through collections of selectable items in order opposite to
    // drawing order. This ensures that among intersecting items the topmost
    // one gets selected.
    
    hoverPoint = -1;
    for (int i = curve.getPointCnt() - 1; i >= 0; --i)
        if (PVector.dist(pos, toView(curve.getPoint(i))) <= POINT_RADIUS) {
            hoverPoint = i;
            break;
        }
   
    hoverKnot = -1;
    if (hoverPoint == -1 && curve.hasKnots()) {
        final int knotCnt = curve.getKnotCnt();
        for (int i = knotCnt - 1; i >= 0; --i) {
            PVector s = toSlider(curve.getKnot(i));
            if (
                abs(s.x - pos.x) <= SLIDER_SIZE
                && pos.y <= s.y && s.y - 3 * SLIDER_SIZE <= pos.y
            ) {
                hoverKnot = i;
                break;
            } 
        }
    }
    
    hoverBlossomParam = false;
    if (hoverPoint == -1 && hoverKnot == -1 && curve.providesBlossom()) {
        PVector b = toSlider(blossomParam);
        hoverBlossomParam = abs(b.x - pos.x) <= SLIDER_SIZE
                         && b.y <= pos.y && pos.y <= b.y + 3 * SLIDER_SIZE;
    }
}

void mouseDragged() {
    if (hoverPoint != -1)
        curve.setPoint(hoverPoint, toScene(getMousePos()));
    else if (hoverKnot != -1)
        curve.setKnot(hoverKnot, fromSlider(mouseX));
    else if (hoverBlossomParam)
        blossomParam = fromSlider(mouseX);
    
    blossomParam = clamp(blossomParam, curve.getMinParam(), curve.getMaxParam());
}

void mouseClicked() {
    if (hoverPoint != -1 || hoverKnot != -1)
        return;
        
    curve.addPoint(toScene(getMousePos()));
}

void keyPressed() {
    if (key == CODED) {
        switch (keyCode) {
            case UP:
                if (curve.canSetDegree())
                    curve.setDegree(curve.getDegree() + 1);
                break;
            
            case DOWN:
                if (curve.canSetDegree())
                    curve.setDegree(curve.getDegree() - 1);
                break;
        }
    } else {
        switch (key) {
            case 'u':
            case 'U':
                if (curve.hasKnots())
                    curve.makeKnotsUniform();
                break;
        }
    }
}
