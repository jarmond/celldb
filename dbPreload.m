% Preload db with project data.

%dbAddModel('poleMShMC','Sister pair coherent/incoherent model. Forces: v+-, spring, anti-poleward. NO FORCE PROJECTION');
dbAddModel('poleMShMCproj','Sister pair coherent/incoherent model. Forces: v+-, spring, anti-poleward. Projected spring force to MPP normal');
% 'tau','vplus','vminus','L','kappa','alpha','pb','pbs'
%'Gaussian','Gaussian','Gamma','Gaussian','Gaussian','Beta','Beta'

%dbAddModel('poleMShMCprojvplus0','Sister pair coherent/incoherent model. Forces: v+-, spring, anti-poleward. Projected spring force to MPP normal and vplus=0');
dbAddModel('1D_harmonicwellMCMC','A simple 1D harmonic well model on the intersister distance');

dbAddUser('Jonathan Armond','jwa');
dbAddUser('Nigel Burroughs','njb');
dbAddUser('Ed Harry','eh');
dbAddUser('Chris Smith','cas');
dbAddUser('Elina Vladimirou','ev');
dbAddUser('Andrew McAinsh','am');

dbAddMicroscope('ultraview');
dbAddMicroscope('dv1');
dbAddMicroscope('dv2');

%dbAddExperiment('eh','ultraview','HeLaJ_WT/trajData_HeLaJ_WT.mat','', ...
%                'HeLaJ','WT');
%dbAddExperiment('eh','ultraview','HeLaJ_noc/trajData_HeLaJ_noc.mat','', ...
%                'HeLaJ','nocodazole');

defaultPriors.L=[0.788 0.148^2];
defaultPriors.kappa=[0.05 10000];
defaultPriors.tau=[0.5 0.001];
defaultPriors.v=[0.03 10];
defaultPriors.alpha=[0.01 10000];
defaultPriors.pb=[2.5 1];
defaultPriors.pbs=[2 1];

