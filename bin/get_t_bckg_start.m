function [t_start,n_start] = get_t_bckg_start(texp,vexp,options)
% Determines the time t_start and corresponding data point index n_start
% where an optimal background fit range starts, the optimum is considered
% to correspond to the point where the distance distribution determined by
% approximate Pake transformation deviates least from zero at the long
% distance limit
%
% texp      experimental time axis
% vexp      experimental data trace, must be 1D and already start at zero
%           time
% options   specifies the background model and background fit parameters
%  .model   0  fractal, n variable,  exp(-k*t^(n/3))
%           1  n-dimensional, n fixed, exp(-k*t^(n/3))
%           2  three-dimensional, exp(-k*t)
%           3  polynomial (fitted to logarithm)
%  .verbose flag specifying output mode, 1: command window output on
%           progress, 0 no output, defaults to 0
% 
% the following options need to be defined only if the corresponding 
% model is requested
%   .homdim     fractal dimension for homogeneous distribution (model 1)
%   .order      order of polynomial (model 3)
%
% Output:
%
% t_start   optimal start time for background fit range
% n_start   data point index corresponding to this time
%
% G. Jeschke, 25.8.2016

if ~isfield(options,'verbose'),
    options.verbose = 0;
end;

nexp = length(vexp);
pot=0; rem = nexp; % find minimum power of 2 which is still larger than number of data points 
while rem > 1,
    pot = pot+1;
    rem = rem/2;
end;
ksize=2^pot; % actual kernel size
p_string=sprintf('%d',ksize); % display
fname=sprintf('%s%s','kernel',p_string); % generate filename
load(fname);


% Adaptive background correction
% background start is tested between 19% and 50% of data trace length, but
% at least between points 1 and 5 of the trace
nfa = round(0.1*nexp);
if nfa<1, nfa = 1; end;
nfe = round(0.6*nexp);
if nfe<5, nfe = 5; end;
merit=zeros(1,nfe-nfa);
for nofitp0 = nfa:nfe,
	
    options.start = nofitp0;
	% Background fit    
	bckg = fit_bckg_2D(vexp,options);
    
	
	td_exp2 = vexp - bckg; % subtract background
	td_exp2 = td_exp2./bckg; % divide by background, eqn [13]
	dipevo = td_exp2/max(td_exp2); % normalize
    [m,n]=size(base); % size of kernel
	spc2=zeros(1,m); % initialize distribution
    td=zeros(1,n);
    td(1:length(texp)) = dipevo;
	tdx=td.*t; % eqn [21]
	for k=1:m, % sum in eqn [21]
      spc2(k)=spc2(k)+sum(base(k,:).*tdx)/tnorm(k); 
	end;
	spc3=crosstalk\spc2'; % crosstalk correction, eqn [22]
    merit(nofitp0-nfa+1)=sum(abs(spc3(1:3)));
    tact=texp(nofitp0);
    if options.verbose,
        fprintf(1,'%s%d%s%6.4f\n','Optimizing background fit range, Start: ',tact,' ns, Figure of merit: ',abs(spc3(1)));
    end;
end;
[~,meind] = min(merit);
n_start = meind+nfa-1;
t_start = texp(n_start);
if options.verbose,
    fprintf(1,'Optimized background fit start at t(%i) = %4.1f ns\n',n_start,t_start);
end;
