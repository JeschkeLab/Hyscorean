function Data = ReadDataTable_Hyscorean %JS
% same function as in easyspin found in isotopes.m file (not callable from
% outside easyspin since it is a subfunction)
% for the generation of a list of isotopes in Hyscorean

% Determine data file name

esPath = fileparts(which('easyspin'));
DataFile = [esPath filesep 'private' filesep 'isotopedata.txt'];
%DataFile = [esPath filesep 'nucmoments.txt'];
if ~exist(DataFile,'file')
  error(sprintf('Could not open nuclear data file %s',DataFile));
end

fh = fopen(DataFile);
C = textscan(fh,'%f %f %s %s %s %f %f %f %f','commentstyle','%');
[Data.Protons,Data.Nucleons,Data.Radioactive,...
 Data.Element,Data.Name,Data.Spin,Data.gn,Data.Abundance,Data.qm] = C{:};

% idx = Data.Spin<=0;
% Data.Protons(idx) = [];
% Data.Nucleons(idx) = [];
% Data.Radioactive(idx) = [];
% Data.Element(idx) = [];
% Data.Name(idx) = [];
% Data.Spin(idx) = [];
% Data.gn(idx) = [];
% Data.Abundance(idx) = [];

return