function stdmodel=standardizeModelName(model)
% Standardize model name to simplify all the switches everywhere

switch lower(model)
  case {'mshmc','sister hmc switcher model a: coherent/incoherent model'}
    stdmodel = 'MShMC';
  case {'polewardhmc_sisterswitcher','polemshmc','polemshmc_sisters',...
        'poleward mshmc:multiple poleward hmc sister switching algorithm'}
    stdmodel = 'poleMShMC';
  case {'polewardhmc_sisterswitcherproj','polemshmcproj', ...
        'polemshmc_sistersproj',...
        'proj poleward mshmc:multiple poleward hmc sister switching algorithm',...
        'projected sister poleward hmc switcher model a: coherent/incoherent model',...
        'sister poleward hmc switcher model a: coherent/incoherent model'}
    stdmodel = 'poleMShMCproj';
  case {'polemshmcprojvplus0','polemshmc_sistersprojvplus0'}
    stdmodel = 'poleMShMCprojvplus0';
  case {'1d_harmonicwellmcmc','1d harmonic model','nocadozoletreated','mcmc1dhw'}
    stdmodel = 'MCMC1DHW';
  case {'bm1d','1d brownian motion model with drift'}
    stdmodel = 'BM1D';
  case {'bm1dv0','1d brownian motion model'}
    stdmodel = 'BM1Dv0';
  case {'bm1dfree','1d brownian motion model without spring'}
    stdmodel = 'BM1Dfree';
  otherwise
    error(['Unknown model: ' model]);
end
