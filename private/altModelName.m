function alt=altModelName(name,reverse)
% Translate a model name to the alternative used in someplaces in NJB's code.

if nargin<2
  reverse=0;
end

if ~reverse
  switch name
    case 'poleMShMCproj'
      alt = 'poleMShMC_SistersProj';
    case 'poleMShMCprojvplus0'
      alt = 'poleMShMC_SistersProjvplus0';
    case '1D_harmonicwellMCMC'
      alt = 'MCMC1dHW';
    otherwise
      alt = name;
  end
else
  switch name
    case 'poleMShMC_SistersProj'
      alt = 'poleMShMCproj';
    case 'poleMShMC_SistersProjvplus0'
      alt = 'poleMShMCprojvplus0';
    otherwise
      alt = name;
  end
end
