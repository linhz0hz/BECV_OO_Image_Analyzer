function [fitStripes,xProjection,yProjection,X,Y,Z] = fit_stripes(a,varargin)

y1  = 251-35;%+10;
y2  = 251+35;%-10;

x1  = 263-35;%-20;
x2  = 263+35;%+20;

X   = x1:x2;
Y   = y1:y2;

OD  = a.opticalDensity(:,512:-1:1)';
OD0 = OD(Y,X);
Z   = -asin(exp(-OD0)-1);

fitStripes = fit_stripes_2(X,Y,Z,varargin{:});

xProjection = sum(OD,1);
yProjection = sum(OD,2)';
end

function [fitresult, gof] = fit_stripes_2(X, Y, Z, varargin)

p = inputParser;
addRequired(p,'X',@isnumeric);
addRequired(p,'Y',@isnumeric);
addRequired(p,'Z',@isnumeric);
addParameter(p,'lambda',0,@isnumeric);
addParameter(p,'angle',0,@isnumeric);
addParameter(p,'lambdaFixed',true,@islogical);
addParameter(p,'angleFixed',true,@islogical);
parse(p,X,Y,Z,varargin{:});

[xData, yData, zData] = prepareSurfaceData( X, Y, Z );

Z_x = mean(Z,1);
Z_y = mean(Z,2)';

if any(strcmp('lambda',p.UsingDefaults)) % if no 'lambda' is specified
    fitStripes = fit_stripes_3(X,Z_x);
else
    fitStripes = fit_stripes_3(X,Z_x,'lambda',p.Results.lambda);
end
fitGauss   = fit_stripes_4(Y,Z_y);

if any(strcmp('lambda',p.UsingDefaults)) % if no 'lambda' is specified   
  lambda0 = fitStripes.lambda;
  lambdaMin = 0;
  lambdaMax = 40;
else
  lambda0 = p.Results.lambda;
  
  if p.Results.lambdaFixed 
    lambdaMin = p.Results.lambda; % fixed
    lambdaMax = p.Results.lambda; % fixed
  else
    lambdaMin = p.Results.lambda * 0.85^2; % free
	lambdaMax = p.Results.lambda * 1.15^2; % free
  end
  
end

if any(strcmp('angle',p.UsingDefaults)) % if no 'angle' is specified     
  angle0 = 0;
  angleMin = -pi/4;
  angleMax = +pi/4;
else
  angle0 = p.Results.angle;
  
  if p.Results.angleFixed 
    angleMin = p.Results.angle; % fixed
    angleMax = p.Results.angle; % fixed
  else
    angleMin = p.Results.angle - 0.05; % free
	angleMax = p.Results.angle + 0.05; % free
  end
  
end

f = @(a,x0,y0,R,c,lambda,angle,phi,x,y) ...
    a * sqrt( 1 - ((x-x0)/R).^2 - ((y-y0)/R).^2 ) ... 
     .* ( 1 - ((x-x0)/R).^2 - ((y-y0)/R).^2 >= 0 ) ...
     .* (1+c*cos(2*pi/lambda*((x-x0)+angle*(y-y0))-2*pi*phi))/2;

% Set up fittype and options.
ft = fittype( f, 'independent', {'x', 'y'}, 'dependent', 'z' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';

Rguess = sqrt(fitStripes.Rx*fitGauss.Ry);

% Parameters:       a     x0             y0           R              c             lambda     angle     phi             
opts.StartPoint = [ 1     fitStripes.x0  fitGauss.y0  Rguess         fitStripes.c  lambda0    angle0    fitStripes.phi ];
opts.Upper      = [ 2.00  290            280          Inf            2             lambdaMax  angleMax  +1             ];
opts.Lower      = [ 0.00  230            220          5              0             lambdaMin  angleMin  -1             ];

[fitresult, gof] = fit( [xData, yData], zData, ft, opts );

end

function [fitresult] = fit_stripes_3(x, y, varargin)

p = inputParser;

addRequired(p,'x',@isnumeric);
addRequired(p,'y',@isnumeric);
addParameter(p,'lambda',0,@isnumeric);

parse(p,x,y,varargin{:});

if any(strcmp('lambda',p.UsingDefaults))    
  lambda0 = 9;
  lambdaMin = 5;
  lambdaMax = 40;
else
  lambda0 = p.Results.lambda;
  
  lambdaMin = p.Results.lambda;% -0.0001;
  lambdaMax = p.Results.lambda;% +0.0001;
 
end

[xData, yData] = prepareCurveData( x, y );

f = @(a,x0,Rx,c,lambda,phi,x) a * (1 - ((x-x0)/Rx).^2) .* (abs(x-x0)<=Rx) .* (1+c*cos(2*pi*x/lambda-2*pi*phi))/2;

ft = fittype( f, 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';

[~,I] = max(y);
x1Guess = x(I);
phiGuess = mod(x1Guess/lambda0 + 0.5,1) - 0.5;

% Parameters:       a     x0    Rx    c     lambda    phi             
opts.StartPoint = [ 0.35  260   20   0.05  lambda0   phiGuess ];
opts.Upper      = [ 1.00  290   Inf   4     lambdaMax 1 ];
opts.Lower      = [ 0.00  230   6     0.001 lambdaMin -1 ];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% ------------------------------------------------------------------------

f = @(a,x0,Rx,c,lambda,phi,x) a * (1 - ((x-x0)/Rx).^2) .* (abs(x-x0)<=Rx) .* (1+c*cos(2*pi*(x-x0)/lambda-2*pi*phi))/2;

ft = fittype( f, 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';

[~,I] = max(y);
x1Guess = x(I);
phiGuess = mod(fitresult.phi - fitresult.x0 / fitresult.lambda + 0.5,1) - 0.5;

% Parameters:       a           x0           Rx           c           lambda           x1             
opts.StartPoint = [ fitresult.a fitresult.x0 fitresult.Rx fitresult.c fitresult.lambda phiGuess ];
opts.Upper      = [ 1.00        300          Inf          4           lambdaMax        0.5        ];
opts.Lower      = [ 0.00        200          0            0.001       lambdaMin        -0.5       ];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

end

function [fitresult, gof] = fit_stripes_4(y,z)

%% Fit: 'untitled fit 2'.
[xData, yData] = prepareCurveData(y,z);

f = @(b,y0,Ry,y) b/2 * (1 - ((y-y0)/Ry).^2) .* (abs(y-y0)<=Ry);

% Set up fittype and options.
ft = fittype( f, 'independent', 'y', 'dependent', 'z' );
%ft = fittype( 'gauss1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';

opts.StartPoint = [ 1   245 20 ];
opts.Upper      = [ Inf 300 50 ]; 
opts.Lower      = [ 0   200 0  ];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% figure
% plot(y,z,'.');
% hold on
% plot(fitresult);
end
