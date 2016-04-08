% t_rgcSubunit
% 
% Demonstrates the inner retina object calculation for the subunit RGC
% model (from Gollisch & Meister, 2008, Science).
% 
% This is a simplistic implementation of a bipolar-like subunit model for
% RGC computation. The receptive field is broken up into a number of
% subunit fields; at each time step, the input to each subunit is
% summed linearly, and the subunits activations are half-wave rectified and
% summed. The original Gollisch & Meister model is meant to account for
% latencies of spikes after a grating presentation, and the implementation
% here attaches the subunit model as a front end to the spike generating
% code by Pillow et al., Nature, 2008.
% 
% 3/2016 BW JRG HJ (c) isetbio team

%%
ieInit

%% Movie of the cone absorptions 
% % Get data from isetbio archiva server
% rd = RdtClient('isetbio');
% rd.crp('/resources/data/istim');
% a = rd.listArtifacts;
% 
% % Pull out .mat data from artifact
% whichA =1 ;
% data = rd.readArtifact(a(whichA).artifactId);
% % iStim stores the scene, oi and cone absorptions
% iStim = data.iStim;
% absorptions = iStim.absorptions;

%% Grating subunit stimulus
params.barWidth = 24;
iStim = ieStimulusGratingSubunit;

%% White noise
% iStim = ieStimulusWhiteNoise;

%% Show raw stimulus for osIdentity
figure;
for frame1 = 1:size(iStim.sceneRGB,3)
    imagesc(squeeze(iStim.sceneRGB(:,:,frame1,:)));
    colormap gray; drawnow;
end
close;

%% Outer segment calculation
% 
% Input = RGB
osI = osCreate('identity');

% Set size of retinal patch
patchSize = sensorGet(absorptions,'width','um');
osI = osSet(osI, 'patch size', patchSize);

% Set time step of simulation equal to absorptions
timeStep = sensorGet(absorptions,'time interval','sec');
osI = osSet(osI, 'time step', timeStep);

% Set osI data to raw pixel intensities of stimulus
osI = osSet(osI, 'rgbData', iStim.sceneRGB);
% os = osCompute(sensor);

% % Plot the photocurrent for a pixel
% osPlot(osI,absorptions);
%% Build the inner retina object

clear params
params.name      = 'Macaque inner retina 1'; % This instance
params.eyeSide   = 'left';   % Which eye
params.eyeRadius = 4;        % Radius in mm
params.eyeAngle  = 90;       % Polar angle in degrees

innerRetina0 = irCreate(osI, params);

% Create a coupled GLM model for the on midget ganglion cell parameters
innerRetina0.mosaicCreate('model','subunit','type','on midget');
innerRetina0.mosaicCreate('model','lnp','type','on midget');

irPlot(innerRetina0,'mosaic');

% Set subunit size
% When numberSubunits is set to the RF size, every pixel is a subunit
% This is the default, after Gollisch & Meister, 2008
sRFcenter = mosaicGet(innerRetina0.mosaic{1},'sRFcenter');
mosaicSet(innerRetina0.mosaic{1},'numberSubunits',size(sRFcenter));

% Alternatively, have 2x2 subunits for each RGC
% mosaicSet(innerRetina0.mosaic{1},'numberSubunits',[2 2]);
%% Compute RGC mosaic responses

innerRetina0 = irCompute(innerRetina0, osI);
irPlot(innerRetina0, 'psth');
irPlot(innerRetina0, 'linear');
% irPlot(innerRetina0, 'raster');

%% Show me the PSTH for one particular cell

% irPlot(innerRetina0, 'psth response','cell',[2 2]);
% irPlot(innerRetina0, 'raster','cell',[1 1]);