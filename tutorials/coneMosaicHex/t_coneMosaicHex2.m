%% t_coneMosaicHex2
%
% Visualizes the effects of different resampling factors. 
% A resampling factor value of 1 gives a rectangular grid.
% A resampling factor of 2 gives pretty bad artifacts with large inhomogenities.
% As the resampling factor is increased beyond 2, inhomogeneities start to 
% disappear and the generated grid approximates a perfect hex grid.
%
% NPC ISETBIO Team, Copyright 2016

%% Initialize
ieInit; clear; close all;
    
rng('default'); rng(219347);

%% Unit test 1: display different aspects of a hex mosaic in a 4 panel display, including 
%% the hex mosaic, the originating rectangular mosaic, the hex grid used for sampling, and the null cones
% Mosaic Parameters
mosaicParams = struct(...
      'resamplingFactor', 7, ...
                  'size', [11 16], ...
        'spatialDensity', [0 1/3 1/3 1/3]...
    );
    
% Generate the hex mosaic
theHexMosaic = coneMosaicHex(mosaicParams.resamplingFactor, ...
                   'name', 'the hex mosaic', ...
                   'size', mosaicParams.size, ...
         'spatialDensity', mosaicParams.spatialDensity ...
    );
% Print some grid info and visualize it
theHexMosaic.displayInfo();
theHexMosaic.visualizeGrid();



% Display the corresponding rectangular grid instead
theHexMosaic.visualizeGrid(...
    'panelPosition', [1 2], ...
    'showCorrespondingRectangularMosaicInstead', true...
    );

% Overlay the null sensors as well
theHexMosaic.visualizeGrid(...
    'panelPosition', [2 1], ...
    'overlayNullSensors', true...
    );

% Overlap the perfect hexagonal mesh
theHexMosaic.visualizeGrid(...
    'panelPosition', [2 2], ...
    'overlayPerfectHexMesh', true...
    );

keepGoing = true;
while (keepGoing)
    commandwindow
    resamplingFactor = input(sprintf('\n<strong>Enter a new resampling factor [>= 1]. A negative exits the loop. New resampling Factor: </strong>'));
    if (isempty(resamplingFactor))
        resamplingFactor = 1;
    end
    
    if (resamplingFactor <= 0)
        keepGoing = false;
        continue;
    end
    theHexMosaic.resampleGrid(resamplingFactor);
    % Print some grid info and visualize it
    theHexMosaic.displayInfo();
    theHexMosaic.visualizeGrid();


    % Display the corresponding rectangular grid instead
    theHexMosaic.visualizeGrid(...
        'panelPosition', [1 2], ...
        'showCorrespondingRectangularMosaicInstead', true...
        );

    % Overlay the null sensors as well
    theHexMosaic.visualizeGrid(...
        'panelPosition', [2 1], ...
        'overlayNullSensors', true...
        );

    % Overlap the perfect hexagonal mesh
    theHexMosaic.visualizeGrid(...
        'panelPosition', [2 2], ...
        'overlayPerfectHexMesh', true...
        );
end
