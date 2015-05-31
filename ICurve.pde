interface ICurve {
    String getName();
    
    int getDegree();
    boolean canSetDegree();
    void setDegree(int degree);
    
    int getPointCnt();
    PVector getPoint(int i);
    void setPoint(int i, PVector p);
    void addPoint(PVector p);
    
    boolean hasKnots();
    int getKnotCnt();
    float getKnot(int i);
    void setKnot(int i, float knot);
    void makeKnotsUniform();
    
    float getMinParam();
    float getMaxParam();
    PVector eval(float t);
    boolean providesBlossom();
    PVector[][] getBlossom(float t);
};
