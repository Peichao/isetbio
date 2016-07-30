function [D, I] = pdist2smallest(X, Y)
%pdist2smallest Pairwise distance between two sets of observations.
% D = pdist2smallest(X,Y) returns a [1 x My] matrix D containing the minimum Euclidean 
% distance between each point in the My-by-N data  matrix Y to all
% points in the MX-by-N data matrix X.
%
%
% NPC ISETBIO Team, Copyright 2016

    [D, I] = pdist2smallestmex(X', Y');
end