/*
 * pdist2smallestmex.c
 *
 * Calculates the minimum Euclidean distance between each point in the My-by-N data matrix Y to all
 * points in the MX-by-N data matrix X.
 *
 * This is a MEX-file for MATLAB.
 * 
 * NPC ISETBIO Team, Copyright 2016
 */


#include "mex.h"
#include <math.h>
#include <float.h>
#include <string.h>

/* Euclidean distance */
void computeMinDistancesForEachPointInYToAllPointsInX(double *x, double *y, double *distances, double *indices, int numPointsX, int numPointsY, int numCoords)
{
    double *xi, *yi, dist, minDist, indexOfMinDist, diff;
    int iPointX, iPointY, iCoord;
    
    yi = y;
    for (iPointY = 0; iPointY < numPointsY; iPointY++) { 
        minDist = DBL_MAX;
        xi = x;
        for (iPointX = 0; iPointX < numPointsX; iPointX++) {
            dist = 0;
            for (iCoord = 0; iCoord < numCoords; iCoord++) {
                dist += pow(yi[iCoord]-xi[iCoord],2.0);
            } // iCoord
            if (dist < minDist) {
                minDist = dist;
                indexOfMinDist = iPointX;
            }
            xi += numCoords;
        } // iPointX
        distances[iPointY] = sqrt(minDist);
        indices[iPointY] = indexOfMinDist + 1;
        yi += numCoords;
    } // iPointY   
}


/* the gateway function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    int     status;
    int     numCoordsX,numPointsX;
    int     numCoordsY,numPointsY;
    
    if (nrhs<2) {
        mexErrMsgIdAndTxt("MATLAB:pdist2smallest:TooFewInputs", "Two input args are required.");
    } else if (nrhs>2) {
        mexErrMsgIdAndTxt("MATLAB:pdist2smallest:TooManyInputs", "Two input args are required.");
    }

    if ((mxIsDouble(prhs[0]))  && (mxIsDouble(prhs[1]))) {
        double *X, *Y, *distances, *indices;
        /*  create a pointer to the input matrix X */
        X = mxGetPr(prhs[0]);
        
        /*  create a pointer to the input matrix Y */
        Y = mxGetPr(prhs[1]);
        
        /*  get the number of rows of input X */
        numCoordsX = mxGetM(prhs[0]);
        /*  get the number of cols of input X */
        numPointsX = mxGetN(prhs[0]);
        // mexPrintf("X matrix contains numPoints: %d (%d dim)\n", numPointsX, numCoordsX);
        
        /*  get the number of rows of input Y */
        numCoordsY = mxGetM(prhs[1]);
        /*  get the number of cols of input Y */
        numPointsY = mxGetN(prhs[1]);
        // mexPrintf("Y matrix contains numPoints: %d (%d dim)\n", numPointsY, numCoordsY);
        
        if (numCoordsX != numCoordsY) {
            mexErrMsgIdAndTxt("MATLAB:pdist2smallest:matchdims", "X and Y data points must be of same dimensionality.");
        }
        
        /*  set the first output pointer to the returned distance vector */
        plhs[0] = mxCreateDoubleMatrix(1, numPointsY, mxREAL);
        
        /*  set the second output pointer to the returned indices vector */
        plhs[1] = mxCreateDoubleMatrix(1, numPointsY, mxREAL);
        
        /*  create a pointer to a copy of the distances vector */
        distances = mxGetPr(plhs[0]);
  
        /*  create a pointer to a copy of the indices vector */
        indices = mxGetPr(plhs[1]);
        
        /* do the work */
        computeMinDistancesForEachPointInYToAllPointsInX(X, Y, distances, indices, numPointsX, numPointsY, numCoordsX);
  }
  
  else {
        mexErrMsgIdAndTxt("MATLAB:pdist2smallest::BadInputType",
                          "pdist2smallest only supports DOUBLE data.");
    }
}