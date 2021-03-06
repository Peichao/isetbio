function varargout = v_osBioPhysLightIncrementDecrementResponses(varargin)
% Validate the biophysical model for light increment and decrement stimuli
%
% This script tests the biophysically-based outer segment model of 
% photon isomerizations to photocurrent transduction that occurs in the
% cone outer segments.  This is for steps (1.5 sec), both incremental and
% decremental with respect to backgrounds of different intensities.
%
% STATUS as of 2/10/16.  We currently have no data to compare against.
%
% 1/12/16      npc   Created after separating the relevant 
%                    components from s_coneModelValidate.

    varargout = UnitTest.runValidationRun(@ValidationFunction, nargout, varargin);
end


%% Function implementing the isetbio validation code
function ValidationFunction(runTimeParams)

    %% Init
    ieInit;

    %% Load measured outer segment data
    [stimulusPhotonRateAmplitudesNeuralDataPoints, decToIncRatioNeuralDataPoints] = loadMeasuredDecIncRatios();
    
    % Set the simulation time interval. In general, the stimulation time interval should 
    % be set to a small enough value so as to avoid overflow errors.
    simulationTimeIntervalInSeconds = 5e-4;
    
    % Compute the simulation time axis
    pulseOnset  = 4000;
    pulseOffset = 7500;
    stimPeriod = [pulseOnset pulseOffset];
    nSamples   = pulseOffset+4000;
    simulationTime = (1:nSamples)*simulationTimeIntervalInSeconds;
    
    stimulusPhotonRateAmplitudes = 500 * 2.^(1:7); % photons/sec
    
    contrastsExamined = [-1 1];
    
    % create human sensor with 1 cone
    sensor = sensorCreate('human');
    sensor = sensorSet(sensor, 'size', [1 1]); % only 1 cone
    sensor = sensorSet(sensor, 'time interval', simulationTimeIntervalInSeconds);

    decrementResponseAmplitude = zeros(1, numel(stimulusPhotonRateAmplitudes));  
    incrementResponseAmplitude = zeros(1, numel(stimulusPhotonRateAmplitudes)); 
    
    for stepIndex = 1:numel(stimulusPhotonRateAmplitudes)
        % create stimulus temporal profile
        stimulusPhotonRate = zeros(nSamples, 1);
        stimulusPhotonRate(100:nSamples-100,1) = stimulusPhotonRateAmplitudes(stepIndex);
        
        for contrastIndex = 1:numel(contrastsExamined)   
            
            % generate step (decrement/increment)
            stimulusPhotonRateStep(contrastIndex, :) = stimulusPhotonRate;
            stimulusPhotonRateStep(contrastIndex, pulseOnset:pulseOffset) = stimulusPhotonRate(pulseOnset:pulseOffset,1) * (1+contrastsExamined(contrastIndex));
            
            % set the stimulus photon rate
            sensor = sensorSet(sensor, 'photon rate', reshape(squeeze(stimulusPhotonRateStep(contrastIndex,:)), [1 1 size(stimulusPhotonRateStep,2)]));
            pRate = sensorGet(sensor, 'photon rate');
            coneType = sensorGet(sensor, 'cone type');
            
            % create a biophysically-based outersegment model object
            osB = osBioPhys();
        
            % specify no noise
            noiseFlag = 0;
            osB.osSet('noiseFlag', noiseFlag);
            osB.osSet('timeStep', simulationTimeIntervalInSeconds);
    
            % compute the model's response to the stimulus
            osB.osCompute(pRate, coneType, 'bgR', 0);
            
            % get the computed current
            current = osB.osGet('coneCurrentSignal');

            % store copy for saving to validation file
            if ((stepIndex == 1) && (contrastIndex == 1))
                osBiophysOuterSegmentCurrent = zeros(numel(stimulusPhotonRateAmplitudes), numel(contrastsExamined), size(current,3));
            end
            osBiophysOuterSegmentCurrent(stepIndex, contrastIndex,:) = current(1,1,:);
            
        end % contrastIndex


        % Gauge response amplitude at 3 seconds
        [~, tBin3seconds] = min(abs(simulationTime-3.0));   % time bin to estimate response to inc/dec pulse
        [~, tBin5seconds] = min(abs(simulationTime-5.0));   % time bin to estimate response to pedestal
        adaptedDecrResponse = osBiophysOuterSegmentCurrent(stepIndex, 1, tBin5seconds);
        adaptedIncrResponse = osBiophysOuterSegmentCurrent(stepIndex, 2, tBin5seconds);
        decrementResponseAmplitude(stepIndex) = abs(osBiophysOuterSegmentCurrent(stepIndex, 1, tBin3seconds) - adaptedDecrResponse);
        incrementResponseAmplitude(stepIndex) = abs(osBiophysOuterSegmentCurrent(stepIndex, 2, tBin3seconds) - adaptedIncrResponse);
        fprintf('StepIndex %d: Decrement response amplitude: %2.2f, Increment response amplitude: %2.1f\n', stepIndex, decrementResponseAmplitude(stepIndex), incrementResponseAmplitude(stepIndex) );
        
        if (runTimeParams.generatePlots)  
            if (stepIndex == 1)
                h = figure(1); clf;
                set(h, 'Position', [10 10 900 1200]);
            end
            
            % plot stimulus on the left
            subplot(numel(stimulusPhotonRateAmplitudes),2,(stepIndex-1)*2+1); 
            plot([simulationTime(1) simulationTime(end)], stimulusPhotonRateAmplitudes(stepIndex)*[1 1], 'k-'); hold on;
            plot(simulationTime, stimulusPhotonRateStep(1,:), 'm-', 'LineWidth', 2.0);
            plot(simulationTime, stimulusPhotonRateStep(2,:), 'b-', 'LineWidth', 1.0);
            set(gca, 'XLim', [simulationTime(1) simulationTime(end)], 'YLim', [0 15e4]);
            if (stepIndex == numel(stimulusPhotonRateAmplitudes))
                xlabel('time (sec)','FontSize',12);
            else
                set(gca, 'XTickLabel', {});
            end
            ylabel('stimulus (photons/sec)','FontSize',12);
            text(0.1, stimulusPhotonRateAmplitudes(stepIndex)+10000, sprintf('step: %d ph/sec',stimulusPhotonRateAmplitudes(stepIndex)), 'FontSize',12);
            
            % plot responses on the right
            subplot(numel(stimulusPhotonRateAmplitudes),2,(stepIndex-1)*2+2); 
            plot(simulationTime, squeeze(osBiophysOuterSegmentCurrent(stepIndex, 1, :)), 'm-', 'LineWidth', 2.0); hold on;
            plot(simulationTime, squeeze(osBiophysOuterSegmentCurrent(stepIndex, 2, :)), 'b-', 'LineWidth', 1.0);
            
            set(gca, 'XLim', [simulationTime(1) simulationTime(end)], 'YLim', [-100 0]);
            if (stepIndex == numel(stimulusPhotonRateAmplitudes))
                xlabel('time (sec)','FontSize',12);
            else
                set(gca, 'XTickLabel', {});
            end
            ylabel('current (uAmps)','FontSize',12);
            
            drawnow;
        end % if (runTimeParams.generatePlots)
    end % stepIndex
    
    showFit = false;
    decToIncRatioNeural = zeros(1, numel(stimulusPhotonRateAmplitudes));
    decToIncRatioModel = zeros(1, numel(stimulusPhotonRateAmplitudes));
    
    for stepIndex = 1:numel(stimulusPhotonRateAmplitudes)
        [decToIncRatioNeural(stepIndex), stimulusPhotonRateAxisFit, decToIncRatioNeuralFit] = generateDecIncRatioEstimate(stimulusPhotonRateAmplitudes(stepIndex), showFit, stimulusPhotonRateAmplitudesNeuralDataPoints, decToIncRatioNeuralDataPoints);
        decToIncRatioModel(stepIndex) = decrementResponseAmplitude(stepIndex) / incrementResponseAmplitude(stepIndex);
    end
    
    h = figure(2); clf;
    set(h, 'Position', [10 10 1200 700]);
    hold on;
    plot(stimulusPhotonRateAmplitudesNeuralDataPoints, decToIncRatioNeuralDataPoints, 'mo', 'MarkerFaceColor', [1 0.7 0.7], 'MarkerSize', 8);
    %plot(stimulusPhotonRateAxisFit, decToIncRatioNeuralFit, 'r-', 'LineWidth', 2.0);
    plot(stimulusPhotonRateAmplitudes, decToIncRatioModel, 'bs', 'MarkerSize', 12, 'MarkerFaceColor', [0.7 0.7 1.0]);
    set(gca, 'FontSize', 12);
    xlabel('log10 background intensity (R*/cone/sec)', 'FontSize', 14);
    ylabel('decrement/increment response ratio', 'FontSize', 14);
    %hLegend = legend('neural data', 'fit to neural data (logistic)', '@osBiophys model data');
    hLegend = legend('neural data',  '@osBiophys model data');
    set(hLegend, 'Location', 'SouthEast', 'FontSize', 12);
    box on;
    grid on;
    hold off;
    drawnow;
    
    % Save validation data
    UnitTest.validationData('osBiophysCurrent', osBiophysOuterSegmentCurrent);
    UnitTest.validationData('simulationTime', simulationTime);
    UnitTest.validationData('stimPeriod', stimPeriod);
    UnitTest.validationData('stimulusPhotonRateAmplitudes',stimulusPhotonRateAmplitudes);
end

function [intensities, decIncRatios] = loadMeasuredDecIncRatios()
    dataSource = {'resources/data/cones', 'decIncRatios.mat'};
    fprintf('Fetching remote data: dir=''%s''  file=''%s''. Please wait ...\n', dataSource{1}, dataSource{2});
    % Download neural data from isetbio's repository
    client = RdtClient('isetbio');
    client.crp(dataSource{1});
    [data, decIncRatiosArtifact] = client.readArtifact(dataSource{2}, 'type', 'mat');
    fprintf('Done fetching data.\n');
    intensities = data.intensities;
    decIncRatios = data.decIncRatios;
end

    
    
function [predictedDecToIncRatio, stimulusPhotonRateAxis, predictedDecToIncFunction] = generateDecIncRatioEstimate(backgroundIntensity, showFit, Intensities, DecIncRatio)
   
    logIntensDataPts = log10(Intensities);
    decIncRatioDataPts = DecIncRatio;
    if (showFit)
        figure(100); clf;
        plot(10.^logIntensDataPts, decIncRatioDataPts, 'ks');
    end
    
    % Initial params for logistic function
    gain = 4;
    minDecIncRatio = 1.7;
    kappa = 4;                % steepness
    logIntensity50 = 4.5;     % midpoint
    initialParams = [minDecIncRatio; gain; kappa; logIntensity50];
    
    % Fit logistic function to recorded data
    fittedParams = nlinfit(logIntensDataPts, decIncRatioDataPts, @logisticFunction, initialParams);
    
    if (showFit)
        logIntensityAxis = linspace(min(logIntensDataPts), max(logIntensDataPts), 100);
        decIncRatioFunction = logisticFunction(fittedParams, logIntensityAxis);
        hold on;
        plot(10.^logIntensityAxis, decIncRatioFunction, 'r-', 'LineWidth', 2.0);
        hold off;
        legend('data', 'fitted function');
        drawnow;
    end
    
    if ( (log10(backgroundIntensity) >= min(logIntensDataPts)) && ...
         (log10(backgroundIntensity) <= max(logIntensDataPts)) )
        predictedDecToIncRatio = logisticFunction(fittedParams, log10(backgroundIntensity));
    else
        predictedDecToIncRatio = nan;
    end
    
    stimulusPhotonRateAxis = 10.^(linspace(min(logIntensDataPts), max(logIntensDataPts), 100));
    predictedDecToIncFunction = logisticFunction(fittedParams, log10(stimulusPhotonRateAxis));
end


function y = logisticFunction(params, x)
    yo = params(1);
    gain = params(2); 
    kappa = params(3);
    x50 = params(4);
    y = yo + gain * (1 ./ (1 + exp(-kappa*(x-x50)))); 
end
