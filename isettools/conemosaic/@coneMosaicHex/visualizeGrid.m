function visualizeGrid(obj, varargin)
% Visualize different aspects of the hex grid
%
% NPC, ISETBIO TEAM, 2015

    % parse input
    p = inputParser;
    p.addParameter('generateNewFigure', false, @islogical);
    p.addParameter('panelPosition', [1 1]);
    p.addParameter('showCorrespondingRectangularMosaicInstead', false, @islogical);
    p.addParameter('overlayNullSensors', false, @islogical);
    p.addParameter('overlayPerfectHexMesh', false, @islogical);
    p.addParameter('overlayConeDensityContour', false, @islogical);
    p.parse(varargin{:});
            
    showCorrespondingRectangularMosaicInstead = p.Results.showCorrespondingRectangularMosaicInstead;
    showNullSensors = p.Results.overlayNullSensors;
    showPerfectHexMesh = p.Results.overlayPerfectHexMesh;
    showConeDensityContour = p.Results.overlayConeDensityContour;
    generateNewFigure = p.Results.generateNewFigure;
    panelPosition = p.Results.panelPosition;
    
    if (showCorrespondingRectangularMosaicInstead)
        titleString = sprintf('<RECT grid> cones: %d x %d (%d total)', ...
            size(obj.patternOriginatingRectGrid,2), size(obj.patternOriginatingRectGrid,1), numel(obj.patternOriginatingRectGrid));
    else
        titleString = sprintf('<RECT grid> cones: %d x %d (%d total), <HEX grid> cones: %d (active), %d (total), resampling factor: %d', ...
            size(obj.patternOriginatingRectGrid,2), size(obj.patternOriginatingRectGrid,1), numel(obj.patternOriginatingRectGrid), ...
            numel(find(obj.pattern > 1)), numel(obj.pattern), ...
            obj.resamplingFactor);
    end
    
    sampledHexMosaicXaxis = obj.patternSupport(1,:,1) + obj.center(1);
    sampledHexMosaicYaxis = obj.patternSupport(:,1,2) + obj.center(2);
    
    % Choose the radius of the aperture obj.pigment.pdWidth vs obj.pigment.width
    radiusComesFrom = 'ConeAperture';
    if (strcmp(radiusComesFrom, 'ConeAperture'))
        dx = obj.pigment.pdWidth;
    else
        dx = obj.pigment.width;
    end
    
    pixelOutline.x = [-1 -1 1 1 -1]*dx/2;
    pixelOutline.y = [-1 1 1 -1 -1]*dx/2;
    originalPixelOutline.x = [-1 -1 1 1 -1]*dx/2.0;
    originalPixelOutline.y = [-1 1 1 -1 -1]*dx/2.0;
    
    iTheta = (0:5:360)/180*pi;
    apertureOutline.x = dx/2.0 * cos(iTheta);
    apertureOutline.y = dx/2.0 * sin(iTheta);
    
    rectCoords = obj.coneLocsOriginatingRectGrid;
    hexCoords = obj.coneLocsHexGrid;
    
    if (generateNewFigure)
        hFig = figure(round(rand()*100000)); 
        if (isempty(panelPosition))
            figPosition = [rand()*2000 rand()*1000 980 670];
        else
            figPosition = [(panelPosition(1)-1)*980 (panelPosition(2)-1)*700 980 670];
        end
    else
        
        if (isempty(panelPosition))
            hFig = figure(1);
            figPosition = [rand()*2000 rand()*1000 980 670];
        else
            hFig = figure(panelPosition(1)*10+panelPosition(2));
            figPosition = [(panelPosition(1)-1)*980 (panelPosition(2)-1)*700 980 670];
        end
    end
    clf; 
    set(hFig, 'Position', figPosition, 'Color', [1 1 1], 'MenuBar', 'none', 'NumberTitle', 'off');
    set(hFig, 'Name', titleString);
    subplot('Position', [0.06 0.06 0.91 0.91]);
    hold on;
    
    if (showConeDensityContour)
        mosaicRangeX = obj.center(1) + obj.width/2*[-1 1]  + [-obj.lambda obj.lambda]*1e-6;
        mosaicRangeY = obj.center(2) + obj.height/2*[-1 1] + [-obj.lambda obj.lambda]*1e-6;
        deltaX = 3*obj.lambda*1e-6;
        areaHalfWidth = deltaX*3;
        gridXPos = (mosaicRangeX(1)+areaHalfWidth):deltaX:(mosaicRangeX(2)-areaHalfWidth);
        gridYPos = (mosaicRangeY(1)+areaHalfWidth):deltaX:(mosaicRangeY(2)-areaHalfWidth);
        measurementAreaInMM2 = (2*areaHalfWidth*1e3)^2;
        densityMap = zeros(numel(gridYPos), numel(gridXPos));
        
        for iYpos = 1:numel(gridYPos)
        for iXpos = 1:numel(gridXPos)
            xo = gridXPos(iXpos);
            yo = gridYPos(iYpos);
            conesWithin = numel(find( ...
                obj.coneLocsHexGrid(:,1) >= xo-areaHalfWidth & ...
                obj.coneLocsHexGrid(:,1) <= xo+areaHalfWidth & ... 
                obj.coneLocsHexGrid(:,2) >= yo-areaHalfWidth & ...
                obj.coneLocsHexGrid(:,2) <= yo+areaHalfWidth ));
            densityMap(iYpos,iXpos) = conesWithin / measurementAreaInMM2;
        end
        end
    end
    
    % The active sensors (approximating the positions of the perfect hex grid)
    lineStyle = '-';
    
    if (showConeDensityContour)
        contourLevels = 10;
        gridXPos = mosaicRangeX(1) + (gridXPos - min(gridXPos))/(max(gridXPos) - min(gridXPos))*(mosaicRangeX(2)-mosaicRangeX(1));
        gridYPos = mosaicRangeY(1) + (gridYPos - min(gridYPos))/(max(gridYPos) - min(gridYPos))*(mosaicRangeY(2)-mosaicRangeY(1));
        [X,Y] = meshgrid(gridXPos, gridYPos);
        contourf(X,Y, densityMap, linspace(min(densityMap(:)), max(densityMap(:)), contourLevels), 'LineWidth', 3.0);
        colormap(1-gray);
    end
    
    if (~showCorrespondingRectangularMosaicInstead)
        if (showNullSensors)
            idx = find(obj.pattern==1);
            [iRows,iCols] = ind2sub(size(obj.pattern), idx);
            edgeColor = [0.4 0.4 0.4]; faceColor = 'none'; lineStyle = '-';
            renderPatchArray(pixelOutline, sampledHexMosaicXaxis(iCols), sampledHexMosaicYaxis(iRows), edgeColor, faceColor, lineStyle);
        end
        
        % L-cones
        idx = find(obj.pattern == 2);
        [iRows,iCols] = ind2sub(size(obj.pattern), idx);
        edgeColor = [1 0 0]; faceColor = [1.0 0.7 0.7];
        renderPatchArray(apertureOutline, sampledHexMosaicXaxis(iCols), sampledHexMosaicYaxis(iRows), edgeColor, faceColor, lineStyle);

        % M-cones
        idx = find(obj.pattern == 3);
        [iRows,iCols] = ind2sub(size(obj.pattern), idx);
        edgeColor = [0 0.7 0]; faceColor = [0.7 1.0 0.7];
        renderPatchArray(apertureOutline, sampledHexMosaicXaxis(iCols), sampledHexMosaicYaxis(iRows), edgeColor, faceColor, lineStyle);

        % S-cones
        idx = find(obj.pattern == 4);
        [iRows,iCols] = ind2sub(size(obj.pattern), idx);
        edgeColor = [0 0 1]; faceColor = [0.7 0.7 1.0];
        renderPatchArray(apertureOutline, sampledHexMosaicXaxis(iCols), sampledHexMosaicYaxis(iRows), edgeColor, faceColor, lineStyle);

        if (showPerfectHexMesh)
            % Superimpose hex mesh showing the locations of the perfect hex grid
            meshFaceColor = [0.8 0.8 0.8]; meshEdgeColor = [0.5 0.5 0.5]; meshFaceAlpha = 0.0; meshEdgeAlpha = 0.5; lineStyle = '-';
            renderHexMesh(hexCoords(:,1), hexCoords(:,2), meshEdgeColor, meshFaceColor, meshFaceAlpha, meshEdgeAlpha, lineStyle);
        end
    else    
        % Original rectangular mosaic
        % The original rect sensors
        idx = find(obj.patternOriginatingRectGrid==2);
        %[iRows,iCols] = ind2sub(size(obj.patternOriginatingRectGrid), idx);
        edgeColor = [0.3 0.3 0.3]; faceColor = [1.0 0.7 0.7];
        renderPatchArray(originalPixelOutline, rectCoords(idx,1), rectCoords(idx,2), edgeColor, faceColor, lineStyle);

        idx = find(obj.patternOriginatingRectGrid==3);
        %[iRows,iCols] = ind2sub(size(obj.patternOriginatingRectGrid), idx);
        edgeColor = [0.3 0.3 0.3]; faceColor = [0.7 1.0 0.7]; 
        renderPatchArray(originalPixelOutline, rectCoords(idx,1), rectCoords(idx,2), edgeColor, faceColor, lineStyle);

        idx = find(obj.patternOriginatingRectGrid==4);
        %[iRows,iCols] = ind2sub(size(obj.patternOriginatingRectGrid), idx);
        edgeColor = [0.3 0.3 0.3]; faceColor = [0.7 0.7 1.0];
        renderPatchArray(originalPixelOutline, rectCoords(idx,1), rectCoords(idx,2), edgeColor, faceColor, lineStyle);
    end
    
    if (showConeDensityContour)
        % Add colorbar
        ticks = linspace(min(densityMap(:)), max(densityMap(:)), 8);
        tickLabels = sprintf('%2.1fK\n', ticks/1000);
        hCbar = colorbar('northoutside', 'peer', gca, 'Ticks', ticks, 'TickLabels', tickLabels);
            hCbar.Orientation = 'horizontal';
            hCbar.Label.String = 'cone density (cones/mm2)';
            hCbar.FontSize = 14;
            hCbar.FontName = 'Menlo';
            hCbar.Color = [0.2 0.2 0.2];
    end
    
    
    hold off
    axis 'equal'; axis 'xy'
    xTicks = [sampledHexMosaicXaxis(1) obj.center(1) sampledHexMosaicXaxis(end)];
    yTicks = [sampledHexMosaicYaxis(1) obj.center(2) sampledHexMosaicYaxis(end)];
    xTickLabels = sprintf('%2.0f um\n', xTicks*1e6);
    yTickLabels = sprintf('%2.0f um\n', yTicks*1e6);
    set(gca, 'XTick', xTicks, 'YTick', yTicks, 'XTickLabel', xTickLabels, 'YTickLabel', yTickLabels);
    set(gca, 'FontSize', 16, 'XColor', [0.1 0.2 0.9], 'YColor', [0.1 0.2 0.9], 'LineWidth', 1.0);
    box on; grid off;
    set(gca, 'XLim', [sampledHexMosaicXaxis(1)-dx sampledHexMosaicXaxis(end)+dx]);
    set(gca, 'YLim', [sampledHexMosaicYaxis(1)-dx sampledHexMosaicYaxis(end)+dx]);
    drawnow;
end

function renderPatchArray(pixelOutline, xCoords, yCoords, edgeColor, faceColor, lineStyle)
    
    verticesNum = numel(pixelOutline.x);
    x = zeros(verticesNum, numel(xCoords));
    y = zeros(verticesNum, numel(xCoords));
   
    for vertexIndex = 1:verticesNum
        x(vertexIndex, :) = pixelOutline.x(vertexIndex) + xCoords;
        y(vertexIndex, :) = pixelOutline.y(vertexIndex) + yCoords;
    end
    patch(x, y, [0 0 0], 'EdgeColor', edgeColor, 'FaceColor', faceColor, 'LineWidth', 1.0, 'LineStyle', lineStyle);
end
  
function renderHexMesh(xHex, yHex, meshEdgeColor, meshFaceColor, meshFaceAlpha, meshEdgeAlpha, lineStyle)
    x = []; y = [];
    triangleConeIndices = delaunayn([xHex(:), yHex(:)]);
    for triangleIndex = 1:size(triangleConeIndices,1)
        coneIndices = triangleConeIndices(triangleIndex, :);
        xCoords = xHex(coneIndices);
        yCoords = yHex(coneIndices);
        for k = 1:numel(coneIndices)
            x = cat(2, x, xCoords);
            y = cat(2, y, yCoords);
        end
    end
    patch(x, y, [0 0 0], 'EdgeColor', meshEdgeColor, 'EdgeAlpha', meshEdgeAlpha, 'FaceAlpha', meshFaceAlpha, 'FaceColor', meshFaceColor, 'LineWidth', 1.5, 'LineStyle', lineStyle);
end

