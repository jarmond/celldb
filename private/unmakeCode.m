function [trajIdx,cellIdx]=unmakeCode(code)
% Encapsulate inverse of trajectory code in function

trajIdx = mod(code,1000);
cellIdx = (code - trajIdx)/1000;
