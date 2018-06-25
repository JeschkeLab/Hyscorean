% eprload  Load experimental EPR data
%
%   y = eprload(FileName)
%   [x,y] = eprload(FileName)
%   [x,y,Pars] = eprload(FileName)
%   [x,y,Pars,FileN] = eprload(FileName)
%   ... = eprload(FileName,Scaling)
%   ... = eprload
%
%   Read spectral data from a file specified in the string
%   'FileName' into the arrays x (abscissa) and y (ordinate).
%   The structure Pars contains entries from the parameter
%   file, if present.
%
%   All strings in the parameter structure containing numbers
%   are converted to numbers for easier use.
%
%   If FileName is a directory, a file browser is
%   displayed. If FileName is omitted, the current
%   directory is used as default. eprload returns the
%   name of the loaded file (including its path) as
%   fourth parameter FileN.
%
%   For DSC/DTA data, x contains the vector or
%   the vectors specifying the abscissa or abscissae of the
%   spectral data array, i.e. magnetic field range
%   for cw EPR, RF range for ENDOR and time delays
%   for pulse EPR. Units are those specified in
%   the parameter file. See the fields XPTS, XMIN, XWID
%   etc. in the Pars structure.
%
%   Supported formats are identified via the extension
%   in 'FileName'. Extensions:
%
%     Bruker BES3T:        .DTA, .DSC
%     Bruker ESP, WinEPR:  .spc, .par
%     SpecMan:             .d01, .exp
%     Magnettech:          .spe (binary), .xml (xml)
%     Active Spectrum:     .ESR
%     Adani:               .dat
%     JEOL:                (variable)
%
%     MAGRES:              .PLT
%     qese, tryscore:      .eco
%     Varian:              .spk, .ref
%     ESE:                 .d00, .exp
%
%     For reading general ASCII formats, use textscan(...)
%
%   'Scaling' tells eprload to scale the data (works only for Bruker files):
%
%      'n':   divide by number of scans
%      'P':   divide by square root of microwave power in mW
%      'G':   divide by receiver gain
%      'T':   multiply by temperature in kelvin
%      'c':   divide by conversion/sampling time in milliseconds
