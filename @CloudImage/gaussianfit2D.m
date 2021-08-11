function [fitresult, gof] = gaussianfit2D(OD, roi)
    xRegion = round(roi(1))+(0:round(roi(3)));
    yRegion = round(roi(2))+(0:round(roi(4)));
    X = reshape(repmat(xRegion',1,numel(yRegion))',1,[]);
    Y = repmat(yRegion,1,numel(xRegion));
    Z = reshape(OD(yRegion,xRegion),1,[]);
    
    OD=OD(yRegion,xRegion);
    xProjection = sum(OD,1);
    yProjection = sum(OD,2)';
    xroi=roi(3);
    yroi=roi(4);
%     xcm=sum(xRegion.*xProjection)/sum(xProjection);
%     ycm=sum(yRegion.*yProjection)/sum(yProjection);
    [m,xpeak]=max(xProjection);
    xpeak=xRegion(xpeak);
    ind=find(xProjection<=m/2);
    xFWHM=max(diff(ind));
    [m,ypeak]=max(yProjection);
    ypeak=yRegion(ypeak);
    ind=find(yProjection<=m/2);
    yFWHM=max(diff(ind));
%     xSTD=sqrt(sum((xRegion-xcm).^2.*xProjection)/sum(xProjection));
%     ySTD=sqrt(sum((yRegion-ycm).^2.*yProjection)/sum(yProjection)); 
    
    % Sum total number
    nTotal=abs(sum(xProjection));

    % Clean up data
    [xData, yData, zData] = prepareSurfaceData( X, Y, Z ); 
    
    % Set up fittype and options.
    
    ft=fittype('nTotal/(2*pi*sx*sy)*exp(-(x-x0)^2/(2*sx^2)-(y-y0)^2/(2*sy^2))','independent', {'x', 'y'}, 'dependent', 'z');
%     ft = fittype( 'nTotal*(1-cf)/(2*pi*sx*sy)/1.202*gbec(2,exp(-((x-x0)^2/sx^2+(y-y0)^2/sy^2)/2),3)+nTotal*cf*5/(2*pi*rx*ry)*max((1-(x-x0)^2/rx^2-(y-y0)^2/ry^2),0)^(3/2)','independent', {'x', 'y'}, 'dependent', 'z' );
  % ft = fittype( 'nTotal*(1-cf)/(2*pi*sx*sy)/1.202*gbec(2,exp(-((x-x0)^2/sx^2+(y-y0)^2/sy^2)/2),3)+nTotal*cf*5/(2*pi*(alphax*sx)*(alphay*sy))*max((1-(x-x0)^2/(alphax*sx)^2-(y-y0)^2/(alphay*sy)^2),0)^(3/2)', 'independent', {'x', 'y'}, 'dependent', 'z' );
    
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    % the variables are nTotal, sx, sy, x0, y0
    %opts.Lower =        [0.7*nTotal  xFWHM/10        yFWHM/10       xpeak-30     ypeak-30];
    %opts.StartPoint =   [nTotal      xFWHM           yFWHM           xpeak        ypeak];
    %opts.Upper =        [1.3*nTotal  inf             inf            xpeak+30     ypeak+30];
    opts.Lower =        [-inf        xFWHM/10        yFWHM/10       xpeak-30     ypeak-30];
    opts.StartPoint =   [nTotal      xFWHM           yFWHM           xpeak        ypeak];
    opts.Upper =        [inf         inf             inf            xpeak+30     ypeak+30];    
    
    
% % % % %     add a position constraint by hand if we want
     
%   x0
    opts.Lower(4) = 271 - 10;% 248.3227 - 5
    opts.Upper(4) = 271 + 10;%
    
%     y0
    opts.Lower(5) = 257 - 10; %279.3659
    opts.Upper(5) = 257 + 10;

% % % % % %     add a width constraint by hand if we want
    
%     dx
    opts.Lower(2) =14 * (1 - 0.25); %29.5  %14
    opts.Upper(2) =14 * (1 + 0.25);
    
%     dy
    opts.Lower(3) = 14 * (1 - 0.25); %29.8
    opts.Upper(3) = 14 * (1 + 0.25);
% % % % % % % % %      
%     opts.Lower =        [0.7*nTotal  xroi/8           xroi/8       xpeak-30     ypeak-30];
%     opts.StartPoint =   [nTotal      xroi/4           xroi/4           xpeak        ypeak];
%     opts.Upper =        [1.3*nTotal  inf             inf            xpeak+30     ypeak+30];
%     
    opts.MaxFunEvals = 800;
    opts.MaxIter = 600;
    opts.TolX = 1e-6;
    opts.TolFun = 1e-6;
    opts.DiffMinChange = 1e-8;
    opts.DiffMaxChange = 1e-2;
    
    opts.Display = 'Off';
    
    % Fit model to data.
    tic
    [fitresult, gof] = fit( [xData, yData], zData, ft, opts );
    toc
    
end