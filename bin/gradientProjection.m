function Answer = gradientProjection(InitialGuess,Kernel1,Kernel2,Signal,options,handles)
% Gradient Projection (GP) regularization method for 2D-distance
% distribution obatined from TRIER experiments.
% -----------INPUT---------------------------------------------------------
%   InitialGuess             Initial guess for the 2D-distance distribution.
%                            (Needs to have same dimensions as Signal)
%
%   Kernel1          2D-Kernel describing integral transformation of first dimension
% 
%   Kernel2          2D-Kernel describing integral transformation of second dimension
%
%   Signal           2D-Time-domain experimental TRIER signal
%
%   options          Structure containing optional parameters
%          options.TolFun
%           --> Tolerance factor for the evaluation function
%          options.EvalFun
%           --> Evaluation function to be employed for the optimizer
%          options.ScalingMethod
%           --> Name of scaling matrix to be used
%                 'isra' ISRA scaling matrix    
%                 'hmz'  HMZ scaling matrix    
%                 'cgls' CGLS scaling matrix    
%          options.StepSizeMethod
%           --> Name of method for stepsize calculation
%                 'sd' Steepest Descent (SD)    
%                 'mg'  Minimal Gradient (GD)
%                 'cauchy' Cauchy stepsize
%                 'armijo' Armijo's rule
%                 'abb'  Adaptive Barzilai-Borwein (ABB)
%                 'abbs' Adaptive Barzilai-Borwein scaled (ABBS) 
%          options.isGUI
%           --> Flag for GUI (default to false if used programatically)
% -----------OUTPUT--------------------------------------------------------
%   Answer             Regularized 2D-distance distribution 
% -------------------------------------------------------------------------
% A good inital guess is required in order for the function to work 
% (recommended to use APT2D.m output as initial guess). 
% This regularization works as a deblurring procedure, hence completely
% absent peaks in the initial guess cannot be obtained by regularization.
%
% TrierRegularizationToolBox(TrierAnalysis), L. Fabregas, 2017

%Define algorithm stop requirements
stopFlag = false;
ToleranceFactor = options.TolFun;
IterationMax = options.MaxEval;
Answer = InitialGuess;
[Nx,Ny] = size(InitialGuess);
StartGuess = InitialGuess;
Cycle = 2;
%Run GP-algorithm for a maximum Iterations
for Iteration = 1:IterationMax
  %----------------Prepare objective function & gradient-------------------
  % Compute current objective function
  ObjectiveError = 0.5*norm(Kernel1*Answer*Kernel2' - Signal)^2;
  % Compute gradient vector of objective function
  TransformedAnswer = Kernel1*Answer*Kernel2';
%   TransformedAnswer = TransformedAnswer/TransformedAnswer(1,1);
  Gradient = (Kernel1'*(TransformedAnswer-Signal)*Kernel2);
  % Normalize gradient
  normFactor = Kernel1'*(Kernel1*Kernel2')*Kernel2;
%   Gradient = (Gradient/max(max(normFactor)));
    Gradient = (Gradient./normFactor);

  Gradient = reshape(Gradient,[],1);
  
  %-------------------Construct scaling matrices---------------------------
  switch options.ScalingMethod
    case 'cgls' %CGLS scaling matrix
      
      %Allowed  elements interval
      Lmin = options.ScalingTresholdMin;
      Lmax = options.ScalingTresholdMax;
      AnswerDifference = reshape(Answer - InitialGuess,[],1);
      %Get gradient of previous iteration
      PreviousGradient = (Kernel1'*(Kernel1*InitialGuess*Kernel2' - Signal)*Kernel2);
      % Normalize gradient
      normFactor = Kernel1'*(Kernel1*Kernel2')*Kernel2;
%       PreviousGradient = reshape(PreviousGradient/max(max(normFactor)),[],1);
      PreviousGradient = reshape(PreviousGradient./normFactor,[],1);

      GradientDifference = Gradient - PreviousGradient;
      %Construct scaling matrix
      ScalingMatrix = eye(Nx*Nx,Ny*Ny) - (AnswerDifference*GradientDifference'/(GradientDifference'*AnswerDifference));
      ScalingMatrix(isnan(ScalingMatrix)) = 0;
      ScalingMatrix(ScalingMatrix > Lmax) = Lmax;
      ScalingMatrix(ScalingMatrix < Lmin) = Lmin;
    case 'isra' % ISRA scaling matrix
      %Allowed diagonal elements interval
      Lmin = options.ScalingTresholdMin;
      Lmax = options.ScalingTresholdMax;
      %Construct scaling matrix
      ScalingMatrix = reshape((Answer./(Kernel1'.*(Kernel1.*Answer.*Kernel2').*Kernel2)),[],1);
      %Threshold diagonal elements in prefixed interval
      ScalingMatrix(isnan(ScalingMatrix)) = 0;
      ScalingMatrix(ScalingMatrix > Lmax) = Lmax;
      ScalingMatrix(ScalingMatrix < Lmin) = Lmin;
      
      ScalingMatrix = reshape(ScalingMatrix,Nx,Nx);
      ScalingMatrix = reshape(ScalingMatrix,[],1);

      %Convert into diagonal matrix
      ScalingMatrix = eye(Nx*Nx,Ny*Ny).*ScalingMatrix;
      
    case 'hmz' %HMZ scaling matrix
      %Allowed diagonal elements interval
      Lmin = options.ScalingTresholdMin;
      Lmax = options.ScalingTresholdMax;
      AnswerDifference = reshape(Answer - InitialGuess,[],1);
      PreviousGradient = (Kernel1'*(Kernel1*InitialGuess*Kernel2' - Signal)*Kernel2);
      % Normalize
      normFactor = Kernel1'*(Kernel1*Kernel2')*Kernel2;
      PreviousGradient = reshape(PreviousGradient./normFactor,[],1);
      
      GradientDifference = Gradient - PreviousGradient;
      %Compute Barzilai-Borwein (BB1) step (cyclic form)
      CycleLength = 2;
      if Cycle == CycleLength
      alphaBB1 = (AnswerDifference'*AnswerDifference)/(AnswerDifference'*GradientDifference);
      alphaBB1(isnan(alphaBB1)) = 0;
      Cycle = 0;
      end
      Cycle = Cycle + 1; 
      %Construct scaling matrix
      ScalingMatrix = alphaBB1*Answer/(Answer + alphaBB1*max(0,(Kernel1'*(Kernel1*Answer*Kernel2')*Kernel2 - Kernel1'*Signal*Kernel2)));
      ScalingMatrix = reshape(ScalingMatrix,[],1);
      %Threshold diagonal elements in prefixed interval
      ScalingMatrix(isnan(ScalingMatrix)) = 0;
      ScalingMatrix(ScalingMatrix > Lmax) = Lmax;
      ScalingMatrix(ScalingMatrix < Lmin) = Lmin;
      %Convert into diagonal matrix
      ScalingMatrix = eye(Nx*Nx,Ny*Ny).*ScalingMatrix;
  end
  
  switch options.StepSizeMethod
    
    case 'sd'  %Scaled Steepest Descent (SD) step size
      
      alpha = Gradient'*ScalingMatrix*Gradient/((norm(reshape((Kernel1*reshape(ScalingMatrix'*Gradient,Nx,Nx)*Kernel2'),[],1))));
      
    case 'mg' %Scaled Minimal Gradient (MG) step size
      
      alpha = Gradient'*ScalingMatrix*reshape(Kernel1'*(Kernel1*reshape(Gradient,Nx,Nx)*Kernel2')*Kernel2,[],1)/(norm((Kernel1'*(Kernel1*reshape(ScalingMatrix'*Gradient,Nx,Nx)*Kernel2')*Kernel2)));
      
    case 'abb' % Adaptive Barzilai-Borwein (ABB) step size
      
      tau = options.ABBSwitch;
      AnswerDifference = reshape(Answer - InitialGuess,[],1);
      PreviousGradient = (Kernel1'*(Kernel1*InitialGuess*Kernel2' - Signal)*Kernel2);
      % Normalize Gradient
      normFactor = Kernel1'*(Kernel1*Kernel2')*Kernel2;
      PreviousGradient = reshape(PreviousGradient./normFactor,[],1);
      GradientDifference = Gradient - PreviousGradient;
      
      %Compute Barzilai-Borwein 1 Scaled (BB1S) stepsize
      alphaBB1 = norm(AnswerDifference)^2/(AnswerDifference'*GradientDifference);
      %Compute Barzilai-Borwein 2 Scaled (BB2S) stepsize
      alphaBB2 = AnswerDifference'*GradientDifference/(norm(GradientDifference)^2);
      %First interation and possibly others may cause NaNs due to having same answer
      alphaBB1(isnan(alphaBB1)) = 0;
      alphaBB2(isnan(alphaBB2)) = 0;
      % Check switching criterion between both stepsizes
      if alphaBB2/alphaBB1 < tau
        alpha = alphaBB2;
      else
        alpha = alphaBB1;
      end
      
    case 'abbs' % Adaptive Barzilai-Borwein Scaled (ABBS) step size
      
      tau = options.ABBSwitch;
      AnswerDifference = reshape(Answer - InitialGuess,[],1);
      PreviousGradient = (Kernel1'*(Kernel1*InitialGuess*Kernel2' - Signal)*Kernel2);
      % Normalize
      normFactor = Kernel1'*(Kernel1*Kernel2')*Kernel2;
      PreviousGradient = reshape(PreviousGradient./normFactor,[],1);
      GradientDifference = Gradient - PreviousGradient;
      
      invScalingMatrix = (ScalingMatrix).^(-1);
      %Compute Barzilai-Borwein 1 Scaled (BB1S) stepsize
      alphaBBS1 = (AnswerDifference')*ScalingMatrix*AnswerDifference/((GradientDifference')*ScalingMatrix*ScalingMatrix*AnswerDifference);
      %Compute Barzilai-Borwein 2 Scaled (BB2S) stepsize
      alphaBBS2 = AnswerDifference'*(invScalingMatrix)*(invScalingMatrix)*GradientDifference/(GradientDifference'*(invScalingMatrix)*GradientDifference);
      %First interation and possibly others may cause NaNs due to having same answer
      alphaBBS1(isnan(alphaBBS1)) = 0;
      alphaBBS2(isnan(alphaBBS2)) = 0;
      % Check switching criterion between both stepsizes
      if alphaBBS2/alphaBBS1 < tau
        alpha = alphaBBS2;
      else
        alpha = alphaBBS1;
      end
      
    case 'armijo' % Armijo's rule for stepsize
      
      % Parameters Armijo's rule
      Basis = options.ArmijoBasis;                  % Restricted to 0<beta<1
      Scale = options.ArmijoScale;                      % Restricted to z>0
      Penalty = options.ArmijoPenalty;                 % Restricted to 0<z<1
      alphamin = options.ArmijoMinimum;
      m = 0;
      alpha = Basis^m*Scale;
      
      %----Compute new answer--------------------------------------------------
      Answer = reshape(Answer,[],1);
      NewAnswer = (Answer - alpha*ScalingMatrix*Gradient);
      NewAnswer = reshape(NewAnswer,Nx,Ny);
      %   % Normalize
      normFactor = abs(Kernel1*NewAnswer*Kernel2');
      NewAnswer = NewAnswer/normFactor(1,1);
      NewError = 0.5*norm(Kernel1*(NewAnswer)*Kernel2' - Signal)^2;
      NewAnswer = reshape(NewAnswer,[],1);
      ObjectiveError = round(ObjectiveError,10);
      %------------------------------------------------------------------------
      while (ObjectiveError - NewError) < Penalty*alpha*Gradient'*ScalingMatrix*Gradient
        m = m + 1;
        alpha = round(Basis^m*Scale,10); %round alpha to zero at very low values
        
        %----Compute new answer & Corresponding error--------------------------
        NewAnswer = (Answer - alpha*ScalingMatrix*Gradient);
        NewAnswer = reshape(NewAnswer,Nx,Ny);
        % Normalize
        normFactor = (Kernel1*NewAnswer*Kernel2');
        NewAnswer = NewAnswer/normFactor(1,1);
        NewError = round(0.5*norm(Kernel1*(NewAnswer)*Kernel2' - Signal)^2,10);
        NewAnswer = reshape(NewAnswer,[],1);
        %----------------------------------------------------------------------
        if alpha < alphamin
          alpha = alphamin;
          break;
        end
        
      end
      
    case 'cauchy' %Gauchy Steep Descent step size
      alpha = Gradient'*Gradient/(Gradient'*reshape((Kernel1*reshape(Gradient,Nx,Nx)*Kernel2'),[],1));
  end
  alphamax = 100;
  alphamin = 0.000001;
  if alpha<alphamin
    alpha = alphamin;
  elseif alpha>alphamax
    alpha=alphamax;
  end
  
  
  Answer = reshape(Answer,[],1);
  %----Compute new answer & Corresponding error--------------------------
  NewAnswer = (Answer - alpha*ScalingMatrix*Gradient);
  NewAnswer = reshape(NewAnswer,Nx,Ny);
  % Normalize
  normFactor = (Kernel1*NewAnswer*Kernel2');
  NewAnswer = NewAnswer/normFactor(1,1);
  NewError = 0.5*norm(Kernel1*(NewAnswer)*Kernel2' - Signal)^2;
  NewAnswer = reshape(NewAnswer,[],1);
  %----------------------------------------------------------------------
  
  %--------------Projection into positive orthant----------------------------
  
  %Construct diagonal matrix and find negative entries in new answer
  D = zeros(Nx^2,Nx^2);
  for i = 1:length(NewAnswer)
    if NewAnswer(i) >= 0
      D(i,i) = 1;
    end
  end
  
  %Store previous answer as initial guess
  InitialGuess = Answer;
  InitialGuess = reshape(InitialGuess,Nx,Nx);
  % Project into positive orthant, assuming constant linesearch mu=1
  Answer = D*NewAnswer;
  
  %-------------------------Finish iteration---------------------------------
  % Reshape definitive answers for this iteration
  Answer = reshape(Answer,Nx,Ny);
  NewAnswer = reshape(NewAnswer,Nx,Ny);
  % Normalize
  normFactor = (Kernel1*Answer*Kernel2');
  Answer = Answer/normFactor(1,1);
  
  % Get definitive error for this iteration
  NewError = 0.5*norm(Kernel1*(Answer)*Kernel2' - Signal)^2;
  
  %Compute evaluation function for this iteration
  switch options.EvalFun
    case 1  % Relative Error Difference
      EvalFun(Iteration) = (ObjectiveError - NewError)/ObjectiveError;
      
    case 2  % Relative Answer Difference
      EvalFun(Iteration) = norm(InitialGuess - Answer)/norm(InitialGuess);
      
    case 3  % Objective Error
      EvalFun(Iteration) = NewError;
  end
  
  if options.verbose
    %Display algorithm status on console
    info = sprintf('GP Iter=%d Eval=%f',Iteration, EvalFun(Iteration));
    disp(info);
  end
  %Update plots on GUI
  if options.isGUI
    colormap jet
    pcolor(handles.RegularizedPlot,options.r1,options.r2,Answer)
    xlabel(handles.RegularizedPlot,'r_1 [nm]')
    ylabel(handles.RegularizedPlot,'r_2 [nm]')
    drawnow
    hold(handles.ConvergencePlot,'on')
    plot(handles.ConvergencePlot,1:length(EvalFun),(EvalFun),'ko'),drawnow
    hold(handles.ConvergencePlot,'on')
    drawnow
  end
  % Stop if convergence of evalutaion function satisfies condition or is stopped
  if options.isGUI
    if get(handles.StopButton,'userdata') || abs(EvalFun(Iteration)) < ToleranceFactor % stop condition
      stopFlag = true;
    end
  else
    if abs(EvalFun(Iteration)) < ToleranceFactor % stop condition
      stopFlag = true;
    end
  end
  if stopFlag
    ObjectiveError = 0.5*norm(Kernel1*Answer*Kernel2' - Signal)^2;
    InputError = 0.5*norm(Kernel1*StartGuess*Kernel2' - Signal)^2;
    fprintf('----------------------------------------------\n')
    fprintf('GP - ALGORITHM FINISHED \n')
    if stopFlag
      fprintf('Algorithm stopped by user\n');
    end
    fprintf('Stop Iteration %i\n',Iteration);
    fprintf('EvalFun %f\n',EvalFun(Iteration));
    fprintf('Error function reduced by %f percent \n',100*abs(ObjectiveError-InputError)/InputError);
    fprintf('----------------------------------------------\n')
    break;
  end

end
