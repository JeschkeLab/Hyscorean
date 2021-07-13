function [TauValues] = brukertaus(BrukerParameters)


if isfield(BrukerParameters,'PlsSPELPrgTxt')
    %--------------------------------------------------------------
    % Data acquired by PulseSPEL-HYSCORE experiments
    %--------------------------------------------------------------
    
    %Extract the PulseSpel code for the experiment
    PulseSpelExp = BrukerParameters.PlsSPELEXPSlct;
    PulseSpelProgram = BrukerParameters.PlsSPELPrgTxt;
    %Find Indices to only scan executed PulseSpel experiment
    ProgStartIndex = strfind(PulseSpelProgram,PulseSpelExp);
    ProgEndIndex = ProgStartIndex -1 + strfind(PulseSpelProgram(ProgStartIndex:end),'end exp');
    %Identify the tau definition lines
    TauDefinitionIndexes = ProgStartIndex -1 + strfind(PulseSpelProgram(ProgStartIndex:ProgEndIndex),'d1=');
    if isempty(TauDefinitionIndexes)
        TauDefinitionIndexes = ProgStartIndex -1 + strfind(PulseSpelProgram(ProgStartIndex:ProgEndIndex),'d1 = ');
    end
    %Extract the tau-values
    for i=1:length(TauDefinitionIndexes)
        TauValues(i) = sscanf(PulseSpelProgram(TauDefinitionIndexes(i):TauDefinitionIndexes(i)+10),'d1%*[ =]%d');
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