function user=dbGuessUser()
% Guess user from login name.

[s,r] = system('whoami');
if s~=0
  user = [];
  return
end
r = strtrim(r);

% User name on nero to initials map.
usermap = {'jonarmond','jwa';
           'edharry','eh';
           'elinavladimirou','ev';
           'andrew','am';
           'chrissmith','cas';
           'masau','njb'};

matches = strfind(usermap(:,1),r);
hit = find(cellfun(@(x) length(x),matches));

if isempty(hit)
  user = [];
else
  user = usermap{hit,2};
end
