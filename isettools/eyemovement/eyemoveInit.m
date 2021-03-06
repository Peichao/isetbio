function sensor = eyemoveInit(sensor, params, varargin)
%% Init eye movement parameters in the sensor structure
%
%   sensor = eyemoveInit(sensor, [params])
%
% Inputs:
%   sensor:  human sensor structure (see sensorCreate)
%   params:  eye-movement parameters, optional, for default value see
%            auxilary function emFillParams below
%     .emFlag   - 3x1 flag vector, indicating whether or not to include
%                 tremor, drift and micro-saccade respectively
%     .sampTime - sampling time in secs, e.g. 0.001 stands for 1ms per
%                 sample
%     .totTime  - total time of eye-movement sequence in secs, will be
%                 rounded to a multiple of sampTime
%     .tremor   - parameters for tremor, could include
%        .interval   = mean of occurring interval in secs
%        .intervalSD = standard deviation of interval
%        .amplitude  = the randomness of tremor in degrees
%        
%     .drift    - parameters for drift, could include
%        .speed     = speed of the slow drifting
%        .speedSD   = standard deviation of speed
%     .msaccade - parameters for microsaccade, could also be named as
%                 .microsaccade, could include fields as
%        .interval   = mean of occurring interval in secs
%        .intervalSD = standard deviation of interval
%        .dirSD      = the randomness of moving direction
%        .speed      = speed of micro-saccade
%        .speedSD    = standard deviation of speed
%
%   varargin: name value pairs for eyemovement parameters, see emSet for
%             supported parameters
%
% Output Parameter:
%   sensor       - sensor with eye movement related parameters set, see
%                  sensorGet for how to retrieve these parameters. Note
%                  that his will not generate the eye-movement sequence,
%                  for generating eye-movement sequence, see emGenSequence
%
% Notes:
%   1) For all eye-movements, we assume that the acceleration time is
%      neglectable
%   2) Drift and tremor can be superimposed. However, during the 
%      microsaccade, both drift and tremor are suppressed
%   3) We assume that drift works like a 2D brownian motion. This is
%      reasonable when micro-saccade is present. However, when
%      micro-saccade is suppressed, drift will somehow towards the fixation
%      point. The actual pattern is unknown and this return-to-origin
%      feature is not implemented here.
%   4) For micro-saccade, speed and amplitude follows main-squence as
%      saccade and here, we just use speed
%   5) We don't add a field 'duration' to microsaccade and in computation,
%      the duration of microsaccade will be estimated by the speed and
%      distance between current position to the fixation point
%
% Reference:
%   1) Susana Martinez-Conde et. al, The role of fixational eye movements
%      in visual perception, Nature reviews | neuroscience, Vol. 5, 2004,
%      page 229~240
%   2) Susana Martinez-Conde et. al, Microsaccades: a neurophysiological
%      analysis, Trends in Neurosciences, Volume 32, Issue 9, September
%      2009, Pages 463~475
%
% Example:
%   sensor = eyemoveInit;
%   sensor = sensorCreate('human');
%   sensor = eyemoveInit(sensor);
%   p.emType = ones(3,1);
%   p.totTime = 1;
%   sensor = eyemoveInit(sensor, p);
%   sensor = eyemoveInit(sensor, p, 'tremor amplitude', 0.1);
%
% See also:
%   emGenSequence
%
% (HJ) Copyright PDCSOFT TEAM 2014

%% Init
if notDefined('sensor'), sensor = sensorCreate('human'); end
if notDefined('params'), params = []; end

%% Generate eye-movement parameters
em = emCreate(params, varargin{:});

%% Set eye-movement parameters to sensor
sensor = sensorSet(sensor, 'eye movement', em);
nSamples = 5000;
if isfield(params, 'nSamples')
    nSamples = params.nSamples;
elseif isfield(params, 'totTime')
    sampTime = sensorGet(sensor, 'sample time interval');
    nSamples = round(params.totTime / sampTime);
end
pos    = zeros(nSamples, 2);
sensor = sensorSet(sensor, 'sensor positions', pos);

sensor = emGenSequence(sensor);

% ePos = sensorGet(sensor,'sensor positions');
% vcNewGraphWin; plot(ePos(:,1),ePos(:,2),'-.')
end

