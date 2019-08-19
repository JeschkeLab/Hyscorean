function [TauValues] = brukertaus(BrukerParameters)


if isfield(BrukerParameters,'PlsSPELPrgTxt')
    %--------------------------------------------------------------
    % Data acquired by PulseSPEL-HYSCORE experiments
    %--------------------------------------------------------------
    
    %Extract the PulseSpel code for the experiment
    PulseSpelProgram = BrukerParameters.PlsSPELPrgTxt;
    %Identify the tau definition lines
    TauDefinitionIndexes = strfind(PulseSpelProgram,'d1=');
    %Extract the tau-values
    for i=1:length(TauDefinitionIndexes)
        Shift = 3;
        while ~isspace(PulseSpelProgram(TauDefinitionIndexes(i) + Shift))
            TauString(Shift - 2) =  PulseSpelProgram(TauDefinitionIndexes(i) + Shift);
            Shift = Shift + 1;
        end
        TauValues(i)  = str2double(TauString);
    end
    
    if ~exist('TauValues')
        
        PulseSpelVariables = BrukerParameters.PlsSPELGlbTxt;
        %Identify the tau definition lines
        TauDefinitionIndexes = strfind(PulseSpelVariables,'d1 ');
        %Extract the tau-values
        for i=1:length(TauDefinitionIndexes)
            Shift = 7;
            while ~isspace(PulseSpelVariables(TauDefinitionIndexes(i) + Shift))
                TauString(Shift - 2) =  PulseSpelVariables(TauDefinitionIndexes(i) + Shift);
                Shift = Shift + 1;
            end
            TauValues(i)  = str2double(TauString);
        end
    end
    
else
    %--------------------------------------------------------------
    % Data acquired by XEPR-HYSCORE experiments
    %--------------------------------------------------------------
    
    %Get the field with the tau-value
    TauString = BrukerParameters.FTEzDelay1;
    %Convert to double
    Pos = strfind(TauString,' ns');
    TauValues = str2double(TauString(1:Pos));
    
end



end