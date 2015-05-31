class BSpline implements ICurve{    
    private int degree;
    private PVector[] points;
    private float[] knots;
    private PVector[][] blossom;
    
    public BSpline() {
        degree = 0;
        knots = new float[0];
        points = new PVector[3];
        for (int i = 0; i < points.length; ++i) {
            float angle = i * TWO_PI / points.length;
            points[i] = new PVector(sin(angle), cos(angle));
        }
        setDegree(2);
    }
    
    public String getName() { return "B-Spline"; }
    
    public int getDegree() { return degree; }
    
    public boolean canSetDegree() { return true; }
    
    public void setDegree(int degree) {
        if (this.degree == degree)
            return;
        if (degree < 1 || points.length < degree + 1)
            throw new IllegalArgumentException("degree");
            
        this.degree = degree;
        updateKnots();
        
        blossom = new PVector[degree][];
        for (int i = 0; i < degree; ++i)
            blossom[i] = new PVector[degree - i]; 
    }
    
    public int getPointCnt() { return points.length; }
    
    public PVector getPoint(int i) { return points[i].get(); }
    
    public void setPoint(int i, PVector p) { points[i] = p.get(); }
    
    public void addPoint(PVector p) {
        PVector[] oldPoints = points;
        points = new PVector[oldPoints.length + 1];
        for (int i = 0; i < oldPoints.length; ++i)
            points[i] = oldPoints[i];
        points[points.length - 1] = p;
        updateKnots();
    }
    
    public boolean hasKnots() { return true; }
    
    public int getKnotCnt() { return knots.length; }
    
    public float getKnot(int i) { return knots[i]; }
    
    public void setKnot(int i, float knot) {
        if (i == 0 || i == knots.length - 1)
            return;
        knots[i] = min(knots[i + 1], max(knots[i - 1], knot));
    }
    
    public void makeKnotsUniform() {
        for (int i = 0; i < knots.length; ++i)
            knots[i] = i / float(knots.length - 1);
    }
    
    public float getMinParam() { return knots[degree - 1]; }
    
    public float getMaxParam() { return knots[knots.length - degree]; }
    
    public PVector eval(float t) {
        // Renaming
        final int n = degree;
        final int K = knots.length - 1;
        final PVector[] p = points;
        final PVector[][] b = blossom;
        
        // Determine segment, i.e. knot interval
        int k = n - 1;
        while (k < K - n && knots[k + 1] < t)
            ++k;
        
        // Initiate blossom table
        for (int j = 0; j < n; ++j)
            b[0][j] = lerp(p[k + j - n + 1], p[k + j - n + 2], local(k + j - n + 1, k + j + 1, t));
        
        // Continue de Boor algorithm
        for (int i = 1; i < n; ++i)
            for (int j = 0; j < n - i; ++j)
                b[i][j] = lerp(b[i - 1][j], b[i - 1][j + 1], local(k + j + i - n + 1, k + j + 1, t));
        
        return b[n - 1][0];
    }
    
    public boolean providesBlossom() { return true; }
    
    public PVector[][] getBlossom(float t) {
        eval(t);
        return blossom.clone();
    }
    
    private void updateKnots() {
        float[] oldKnots = knots;
        knots = new float[degree + points.length - 1];
        //float lastOldKnot = min(oldKnots.length, knots.length) / 
        for (int i = 0; i < min(oldKnots.length, knots.length); ++i)
            knots[i] = i * oldKnots[i] / (knots.length - 1);
        for (int i = oldKnots.length; i < knots.length; ++i)
            knots[i] = i / float(knots.length - 1);
    }
    
    private float local(int i, int j, float t) {
        return (t - knots[i]) / (knots[j] - knots[i]);
    }
}
