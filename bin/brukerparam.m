function [Param] = brukerparam(BrukerParameters)

if isfield(BrukerParameters,'PlsSPELGlbTxt')
    %--------------------------------------------------------------
    % Data acquired by PulseSPEL-HYSCORE experiments
    %--------------------------------------------------------------
    %Extract pulse lengths
    PulseSpelText = BrukerParameters.PlsSPELGlbTxt;
    Pulse90DefinitionIndex = strfind(PulseSpelText,'p0   = ');
    Pulse180DefinitionIndex = strfind(PulseSpelText,'p1   = ');
    Shift = 7;
    while ~isspace(PulseSpelText(Pulse90DefinitionIndex + Shift))
        Pulse90String(Shift - 2) =  PulseSpelText(Pulse90DefinitionIndex + Shift);
        Shift = Shift + 1;
    end
    Shift = 7;
    while ~isspace(PulseSpelText(Pulse180DefinitionIndex + Shift))
        Pulse180String(Shift - 2) =  PulseSpelText(Pulse180DefinitionIndex + Shift);
        Shift = Shift + 1;
    end
    CenterfieldString = BrukerParameters.CenterField;
    Centerfield = str2double(CenterfieldString(1:strfind(CenterfieldString,' G')));
    Param.Centerfield = 0.1*Centerfield; %mT
    Param.mwFreq = BrukerParameters.MWFQ/1e9;
    Param.Pulse90 = str2double(Pulse90String)/1000;
    Param.Pulse180 = str2double(Pulse180String)/1000;
    Param.ShotRepTime = str2double(BrukerParameters.ShotRepTime(1:strfind(BrukerParameters.ShotRepTime,' ')));
    Param.ShotsPerLoop = BrukerParameters.ShotsPLoop;
    Param.NbScansDone = BrukerParameters.NbScansDone;
    Param.VideoGain = str2double(BrukerParameters.VideoGain(1:strfind(BrukerParameters.VideoGain,' ')));
    Param.VideoBandwidth = str2double(BrukerParameters.VideoBW(1:strfind(BrukerParameters.VideoBW,' ')));
    
else
    %--------------------------------------------------------------
    % Data acquired by XEPR-HYSCORE experiments
    %--------------------------------------------------------------
    CenterfieldString = BrukerParameters.CenterField;
    Centerfield = str2double(CenterfieldString(1:strfind(CenterfieldString,' G')));
    Param.Centerfield = 0.1*Centerfield; %mT
    Param.mwFreq = BrukerParameters.MWFQ/1e9;
    Pulse90String = BrukerParameters.FTEzMWPiHalf;
    Param.Pulse90 = str2double(Pulse90String(1:strfind(Pulse90String,' ns')))/1000;
    Pulse180String = BrukerParameters.FTEzMWPiHalf;
    Param.Pulse180 = str2double(Pulse180String(1:strfind(Pulse180String,' ns')))/1000;
    Param.ShotRepTime = str2double(BrukerParameters.ShotRepTime(1:strfind(BrukerParameters.ShotRepTime,' ')));
    Param.ShotsPerLoop = BrukerParameters.ShotsPLoop;
    Param.NbScansDone = BrukerParameters.NbScansDone;
    Param.VideoGain = str2double(BrukerParameters.VideoGain(1:strfind(BrukerParameters.VideoGain,' ')));
    Param.VideoBandwidth = str2double(BrukerParameters.VideoBW(1:strfind(BrukerParameters.VideoBW,' ')));
end