function t_pdist2smallest
% Unit tests for pdist2smallest
%
% NPC ISETBIO Team, Copyright 2016

    mDims = 2;
    nXPoints = 10;
    X = rand(nXPoints,mDims);
    nYPoints = 3;
    Y = rand(nYPoints,mDims);
    
    directOutput = zeros(1, nYPoints);
    for pt1 = 1:nYPoints
        d = sqrt(sum((bsxfun(@minus, X, Y(pt1,:))).^2,2));
        directOutput(1,pt1) = min(d);
    end
    directOutput
    
    [matlabOutput, matlabIndices] = pdist2(X, Y, 'euclidean', 'Smallest', 1)
    
    [mexOutput, mexIndices] = pdist2smallest(X, Y)
end
