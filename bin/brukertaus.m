function [TauValues,FirstTauValues,exptype] = brukertaus(BrukerParameters)

% Function to extract tau-values and experiment type for 4pHYSCORE and 6pHYSCORE bruker data

if isfield(BrukerParameters,'PlsSPELPrgTxt')
    %--------------------------------------------------------------
    % Data acquired by PulseSPEL-HYSCORE experiments
    %--------------------------------------------------------------
    
    %Extract the PulseSpel code for the experiment
    PulseSpelExp = BrukerParameters.PlsSPELEXPSlct;
    PulseSpelProgram = BrukerParameters.PlsSPELPrgTxt;
    %Find Indices to only scan executed PulseSpel experiment
    ProgStartIndex = strfind(PulseSpelProgram,PulseSpelExp);
    if isempty(ProgStartIndex) % in case exp. name is not defined in PulseSpel
        ProgStartIndex = 1;
    else
        ProgStartIndex = ProgStartIndex(end);
    end
    ProgEndIndex = ProgStartIndex(end) -1 + strfind(PulseSpelProgram(ProgStartIndex(end):end),'end exp');
    %Identify the tau definition lines
    TauDefinitionIndexes = ProgStartIndex -1 + strfind(PulseSpelProgram(ProgStartIndex:ProgEndIndex),'d1=');
    
    if isempty(TauDefinitionIndexes)
        TauDefinitionIndexes = ProgStartIndex -1 + strfind(PulseSpelProgram(ProgStartIndex:ProgEndIndex),'d1 = ');
    end
    
    % Find the indices for the second tau-values if 6pHYSCORE is loaded
    if PulseSpelExp == '6P HYSCORE'
        TauDefinitionIndexes2 = ProgStartIndex -1 + strfind(PulseSpelProgram(ProgStartIndex:ProgEndIndex),'d2=');
        if isempty(TauDefinitionIndexes2)
            TauDefinitionIndexes2 = ProgStartIndex -1 + strfind(PulseSpelProgram(ProgStartIndex:ProgEndIndex),'d2 = ');
        end
        if numel(TauDefinitionIndexes) ~= numel(TauDefinitionIndexes2)          % Check if the numbe of tau-values match
            warndlg('Read in of tau-values for 6pHYSCORE did not work out, number of tau1 values not equal to number of tau2 values read in','warning');
        end
    end
    
    %Extract the tau-values
    if PulseSpelExp ~= '6P HYSCORE'     % 4pHYSCORE
        for i=1:length(TauDefinitionIndexes)
            TauValues(i) = sscanf(PulseSpelProgram(TauDefinitionIndexes(i):TauDefinitionIndexes(i)+10),'d1%*[ =]%d');
        end
        TauValues2 = [];    
    else                                % 6pHYSCORE
        for i=1:length(TauDefinitionIndexes)
            % Store 2nd tau-values as TauValues and the 1st tauvalues as FirstTauValues
            TauValues(i) = sscanf(PulseSpelProgram(TauDefinitionIndexes2(i):TauDefinitionIndexes2(i)+10),'d2%*[ =]%d');
            FirstTauValues(i) = sscanf(PulseSpelProgram(TauDefinitionIndexes(i):TauDefinitionIndexes(i)+10),'d1%*[ =]%d');
        end  
    end
    
    if ~exist('TauValues')
        
        PulseSpelVariables = BrukerParameters.PlsSPELGlbTxt;
        %Identify the tau definition lines
        TauDefinitionIndexes = strfind(PulseSpelVariables,'d1 ');
        if PulseSpelExp == '6P HYSCORE'
             TauDefinitionIndexes2 = strfind(PulseSpelVariables,'d2 ');
        end
       
        %Extract the tau-values
        for i=1:length(TauDefinitionIndexes)
            Shift = 7;
            while ~isspace(PulseSpelVariables(TauDefinitionIndexes(i) + Shift))
                TauString(Shift - 2) =  PulseSpelVariables(TauDefinitionIndexes(i) + Shift);
                Shift = Shift + 1;
            end
            TauValues(i)  = str2double(TauString);
            FirstTauValues = [];
            % If experiment is 6P HYSCORE: Overwrite TauValues with the tau-values between 4. and 5. pulse after storing them in FirstTauValues-vector
            if PulseSpelExp == '6P HYSCORE'
                FirstTauValues = TauValues;
                while ~isspace(PulseSpelVariables(TauDefinitionIndexes2(i) + Shift))
                    TauString2(Shift - 2) =  PulseSpelVariables(TauDefinitionIndexes2(i) + Shift);
                    Shift = Shift + 1;
                end
                TauValues(i)  = str2double(TauString2);
            end
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

% Store the experiment type
if BrukerParameters.PlsSPELEXPSlct == '6P HYSCORE'
    exptype = '6pHYSCORE';
else
    exptype = '4pHYSCORE';
end
  

end