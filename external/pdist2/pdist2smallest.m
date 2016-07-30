function [D, I] = pdist2smallest(X, Y)
%pdist2smallest Pairwise distance between two sets of observations.
% [D, I] = pdist2smallest(X,Y) returns a [1 x My] matrix D containing the minimum Euclidean 
% distances between each point in the My-by-N data matrix Y to all
% points in the MX-by-N data matrix X. The indices of the points in the data
% matrix X, which result in the minimun distances are also returned in the [1 x My] matrix, I.
%
%
% NPC ISETBIO Team, Copyright 2016

    [D, I] = pdist2smallestmex(X', Y');
end