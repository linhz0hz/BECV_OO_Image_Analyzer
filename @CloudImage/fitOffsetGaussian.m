function [fitObj, gofObj] = fitOffsetGaussian(x, y,varargin)
%CREATEFIT(X,PROJECTEDCOLUMNDENSITY)
%  Create a fit.
%
%  Data for 'Gaussian with Linear Offset' fit:
%      X Input : X
%      Y Output: projectedColumnDensity
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  See also FIT, CFIT, SFIT.

%  Auto-generated by MATLAB on 07-Sep-2012 14:50:49


%% Fit: 'Gaussian with Linear Offset'.
[xData, yData] = prepareCurveData( x, y );

p=inputParser;
p.CaseSensitive=false;
addRequired(p,'x',@isnumeric);
addRequired(p,'projetedColumnDensity',@isnumeric);
offsetOptions = {'none','constant','linear'};
addParamValue(p,'removeSaturation',false, @islogical);
addParamValue(p,'offset','none', @(x) any(validatestring(x,offsetOptions)));
addParamValue(p,'bConstraint',0,@isnumeric);
addParamValue(p,'cConstraint',0,@isnumeric);
parse(p,x,y,varargin{:});
offset=p.Results.offset;
removeSaturation = p.Results.removeSaturation;

% nPoints=length(x);
startPoint = [max(y)-median(y(1:35))... %guess for a1
                   median(x)...         %guess for b1
                   length(x)/2 ... %guess for c1
                   median(y(1:int16((length(y)/10))))...   %guess for d1
                   0 ...%(median(projectedColumnDensity(1:10))... %guess for f1
                        %-median(projectedColumnDensity((nPoints-10):nPoints)))...
                        %/length(x)
                  ];
              
switch offset
    case 'none'
        % Set up fittype and options.
        ft = fittype( 'a*exp(-1/2*((x-b)/c)^2)', 'independent', 'x', 'dependent', 'y' );
        opts = fitoptions( ft );
        opts.StartPoint=startPoint(1:3);
    case 'constant'
        % Set up fittype and options.
        ft = fittype( 'a*exp(-1/2*((x-b)/c)^2)+d', 'independent', 'x', 'dependent', 'y' );
        opts = fitoptions( ft );
        opts.StartPoint=startPoint(1:4);
    case 'linear'
        % Set up fittype and options.
        ft = fittype( 'a*exp(-1/2*((x-b)/c)^2)+d+f*x', 'independent', 'x', 'dependent', 'y' );
        opts = fitoptions( ft );
        opts.StartPoint=startPoint(1:5);
end

opts.Algorithm='Levenberg-Marquardt';
opts.Lower = [0 x(1) 0 -Inf -Inf];
opts.Upper = [Inf Inf Inf Inf Inf];

% allow negative atom numbers if we want
opts.Lower(1) = -Inf;
opts.Upper(1) = +Inf;

% add a position constraint by hand if we want
if p.Results.bConstraint ~= 0
    opts.Lower(2) = p.Results.bConstraint - 2.4;
    opts.Upper(2) = p.Results.bConstraint + 2.4;
end

% add a width constraint by hand if we want
if p.Results.cConstraint ~= 0
    opts.Lower(3) = p.Results.cConstraint * (1 - 0.20);
    opts.Upper(3) = p.Results.cConstraint * (1 + 0.20);
end

opts.Display = 'Off';
opts.TolX = 1e-7;
opts.TolFun = 1e-7;
% opts.Robust='on';

% Fit model to data.
[fitObj, gofObj] = fit( xData, yData, ft, opts );
% fitObj.c = fitObj.c;

%refit after removing saturated region
if removeSaturation
    yData(xData>(fitObj.b-.5*fitObj.c) & xData<(fitObj.b+.5*fitObj.c))=[];
    xData(xData>(fitObj.b-.5*fitObj.c) & xData<(fitObj.b+.5*fitObj.c))=[];  
    size(xData)
    size(yData)
    
    [fitObj, gofObj] = fit( xData, yData, ft, opts );
end