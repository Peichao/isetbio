function varargout = v_osBioPhysEyeMovements(varargin)
% Check os biophysical model against neural data (simulating eye movements)
%
% This script tests the biophysically-based outer segment model of photon
% isomerizations to photocurrent transduction in the cone outer segments.
% The simulation is compared with a recording sesssion that simulated eye
% movements for a natural image stimulus.
%
% STATUS as of 2/10/16.  
%
%  * This fetches using the remote data toolbox the eyeMovementExample file
%  provided by Fred's lab and compares model predictions
% given input isomerizations with measured photocurrent.  
%  * The agreement is good up to a constant current offset, which we
%  understand is due to features of the measurement and/or the way the data were saved.
%
% Currently, the validation data DC value is simply shifted to match the
% model predictions.  Better would be to specify in the eyeMovementExample
% data file the offset that provides the best estimate of the real
% measurement offset. Or, if this isn't possible, then things are fine, but
% we should know that and write it down here and/or in a comment about the
% eyeMovementExample data file.
%
% 6/xx/2015    npc   Created.
% 7/xx/2015    jrg   Test with ISETBIO outersegment object
% 12/31/15     dhb   Added local copy of coneAdapt.            
% 1/7/16       dhb   Rename.  Started to remove reference to coneAdapt.  
%                    Last version with coneAdapt comparison is in tagged
%                    version OSObjectVsOrigValidation.
% 1/12/16      npc   Created this version after separating the eye movements 
%                    component from s_coneModelValidate.
%
% 2016 ISETBIO Team

varargout = UnitTest.runValidationRun(@ValidationFunction, nargout, varargin);

end

%% Function implementing the isetbio validation code
function ValidationFunction(runTimeParams)

    %% Init
    % ieInit;

    %% Load measured outer segment data.  usec time base
    [time, measuredOuterSegmentCurrent, stimulusPhotonRate] = loadMeasuredOuterSegmentResponses();
    
    %% Compute @os model response
    
    % Set the simulation time interval equal to the temporal sampling resolution of the measured measured data
    % In generar, the stimulation time interval should be set to a small enough value so as to avoid overflow errors.
    simulationTimeIntervalInSeconds = time(2)-time(1);
     
%     cmosaic = coneMosaic;
%     cmosaic.rows = 1; cmosaic.cols = 1;
%     cmosaic.integrationTime = simulationTimeIntervalInSeconds;
%     cmosaic.absorptions = stimulusPhotonRate*simulationTimeIntervalInSeconds;
% %     
% %     % Create a biophysically-based outersegment model object.
% 
%     cmosaic.os = osBioPhys();
%     cmosaic.os.timeStep = simulationTimeIntervalInSeconds;
%     pRate(1,1,:) = stimulusPhotonRate;%cmosaic.absorptions./cmosaic.integrationTime;
%     cmosaic.os.compute(pRate, cmosaic.pattern);
% 
%     osBiophysOuterSegmentCurrent = cmosaic.os.osGet('coneCurrentSignal');
%     
%     osBiophysOuterSegmentCurrent = squeeze(osBiophysOuterSegmentCurrent(1,1,:));
%     out1 = osBiophysOuterSegmentCurrent;
% Create human sensor with 1 cone and load its photon rate with
% the stimulus photon rate time sequence
    sensor = sensorCreate('human');
    sensor = sensorSet(sensor, 'size', [1 1]); % only 1 cone
    sensor = sensorSet(sensor, 'time interval', simulationTimeIntervalInSeconds);
    
%     sensor = sensorSet(sensor,'exposure time', simulationTimeIntervalInSeconds);
%     sensor = sensorSet(sensor,'integration time', simulationTimeIntervalInSeconds);
%     sensor = sensorSet(sensor, 'exp time', simulationTimeIntervalInSeconds);
    sensor = sensorSet(sensor, 'photon rate', reshape(stimulusPhotonRate, [1 1 numel(stimulusPhotonRate)]));
   
    pRate = sensorGet(sensor, 'photon rate');
    coneType = sensorGet(sensor, 'cone type');
    osB = osBioPhys();
    % Specify no noise
    noiseFlag = 0;
    osB.osSet('noiseFlag', noiseFlag);
    osB.osSet('timeStep', simulationTimeIntervalInSeconds);

    % Compute the model's response to the stimulus
    osB.osCompute(pRate, coneType);

%%%%%%%%%%
%     osB = osBioPhys();
%     % Specify no noise
%     noiseFlag = 0;
%     osB.osSet('noiseFlag', noiseFlag);
%     osB.osSet('timeStep', simulationTimeIntervalInSeconds);
%     pRate = cmosaic.absorptions/cmosaic.integrationTime;
%     coneType = 2;
%     % Compute the model's response to the stimulus
%     osB.osCompute(pRate, coneType);
%%%%%%%%%%
    % Get the computed current
    osBiophysOuterSegmentCurrent = osGet(osB,'coneCurrentSignal');
        
    osBiophysOuterSegmentCurrent = squeeze(osBiophysOuterSegmentCurrent(1,1,:));
    out2 = osBiophysOuterSegmentCurrent;
    offset1Time = 0.35;
    [~,offset1TimeBin] = min(abs(time - offset1Time ));

    offset2Time = 9.1;
    [~,offset2TimeBin] = min(abs(time - offset2Time ));
    
    % Make the current level match at the offset times
    measuredOuterSegmentCurrentOffset1 = measuredOuterSegmentCurrent +  (osBiophysOuterSegmentCurrent(offset1TimeBin)-measuredOuterSegmentCurrent(offset1TimeBin));
    measuredOuterSegmentCurrentOffset2 = measuredOuterSegmentCurrent +  (osBiophysOuterSegmentCurrent(offset2TimeBin)-measuredOuterSegmentCurrent(offset2TimeBin));
    
    % compute RMS error.  Why are there so many NaNs in the measured data?
    residual1 = osBiophysOuterSegmentCurrent(:)-measuredOuterSegmentCurrentOffset1(:);
    residual2 = osBiophysOuterSegmentCurrent(:)-measuredOuterSegmentCurrentOffset2(:);
    validIndices = find(~isnan(measuredOuterSegmentCurrent));
    errorRMS1 = sqrt(mean(residual1(validIndices).^2));
    errorRMS2 = sqrt(mean(residual2(validIndices).^2));

    % Plot the two calculations and compare against measured data.
    if (runTimeParams.generatePlots)
        h = vcNewGraphWin([],'tall');
        subplot(2,1,1)
        % subplot('Position', [0.05 0.54 0.94 0.42]);
        stairs(time,stimulusPhotonRate, 'r-',  'LineWidth', 2.0);
        set(gca, 'XLim', [time(1) time(end)], 'FontSize', 12);
        ylabel('Stimulus (R*/sec)','FontSize',14);
        
        subplot(2,1,2)
        % subplot('Position', [0.05 0.03 0.94 0.46]);
        plot(time, measuredOuterSegmentCurrent, '.-', 'LineWidth', 2.0); hold on;
        plot(time, measuredOuterSegmentCurrentOffset1, 'm-', 'LineWidth', 2.0);
        plot(time, measuredOuterSegmentCurrentOffset2, 'b-', 'LineWidth', 2.0);
        plot(time, osBiophysOuterSegmentCurrent, 'k-',  'LineWidth', 2.0);
        plot(time(offset1TimeBin)*[1 1], [-100 100], 'm-');
        plot(time(offset2TimeBin)*[1 1], [-100 100], 'b-');
        set(gca, 'XLim', [time(1) time(end)], 'FontSize', 12);
        xlabel('Time (sec)','FontSize',14);
        ylabel('Photocurrent (pA)','FontSize',14);
        h = legend('measured (as saved in datafile)', sprintf('measured (adjusted to match model at %2.2f sec)', offset1Time),  sprintf('measured (adjusted to match model at %2.2f msec)',offset2Time) , 'osBioPhys model', 'location', 'NorthWest');
        set(h, 'FontSize', 12);
        title(sprintf('rms: %2.2f pA (offset at %2.2f sec)\nrms: %2.2f pA (offset at %2.2f sec)', errorRMS1, offset1Time, errorRMS2, offset2Time), 'FontName', 'Fixed');
        drawnow;
    end
    
    % Save validation data
    UnitTest.validationData('osBiophysCur', osBiophysOuterSegmentCurrent);
    UnitTest.validationData('time', time);
    UnitTest.validationData('stimulusPhotonRate', stimulusPhotonRate);
end

% Helper functions
function [time, measuredOuterSegmentCurrent, stimulusPhotonRate] = loadMeasuredOuterSegmentResponses()
    
    dataSource = {'resources/data/cones', 'eyeMovementExample'};
    fprintf('Fetching remote data: dir=''%s''  file=''%s''. Please wait ...\n', dataSource{1}, dataSource{2});
    % Download neural data from isetbio's repository
    client = RdtClient('isetbio');
    client.crp(dataSource{1});
    [eyeMovementExample, eyeMovementExampleArtifact] = client.readArtifact(dataSource{2}, 'type', 'mat');
    fprintf('Done fetching data.\n');
    
    extraTimeForBaselineComputation = 2.0;
    
    % time axis
    dt = eyeMovementExample.data.TimeAxis(2)-eyeMovementExample.data.TimeAxis(1);
    postStimulusTime = eyeMovementExample.data.TimeAxis(end) + dt*(1:(round(extraTimeForBaselineComputation/dt)));
    time = [eyeMovementExample.data.TimeAxis postStimulusTime];
    
    measuredOuterSegmentCurrent = nan(size(time));
    stimulusPhotonRate = time * 0;
    
    % Retrieve the (baseline-corrected) outer segment current
    stimTimeBins = 1:numel(eyeMovementExample.data.TimeAxis);
    measuredOuterSegmentCurrent(stimTimeBins) = squeeze(eyeMovementExample.data.Mean);
    
    % standard deviation of the current ?
    % measuredOuterSegmentCurrentSD = eyeMovementExample.data.SD;
    
    % stimulus in isomerizations/sec
    stimulusPhotonRate(stimTimeBins) = eyeMovementExample.data.Stim;
end

