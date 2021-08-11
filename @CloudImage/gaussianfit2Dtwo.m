function [fitresult, gof] = gaussianfit2Dtwo(OD, roi)
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
    
    ft=fittype('n1/(2*pi*sx1*sy1)*exp(-(x-x1)^2/(2*sx1^2)-(y-y1)^2/(2*sy1^2))+n2/(2*pi*sx2*sy2)*exp(-(x-x2)^2/(2*sx2^2)-(y-y2)^2/(2*sy2^2))','independent', {'x', 'y'}, 'dependent', 'z');
%     ft = fittype( 'nTotal*(1-cf)/(2*pi*sx*sy)/1.202*gbec(2,exp(-((x-x0)^2/sx^2+(y-y0)^2/sy^2)/2),3)+nTotal*cf*5/(2*pi*rx*ry)*max((1-(x-x0)^2/rx^2-(y-y0)^2/ry^2),0)^(3/2)','independent', {'x', 'y'}, 'dependent', 'z' );
  % ft = fittype( 'nTotal*(1-cf)/(2*pi*sx*sy)/1.202*gbec(2,exp(-((x-x0)^2/sx^2+(y-y0)^2/sy^2)/2),3)+nTotal*cf*5/(2*pi*(alphax*sx)*(alphay*sy))*max((1-(x-x0)^2/(alphax*sx)^2-(y-y0)^2/(alphay*sy)^2),0)^(3/2)', 'independent', {'x', 'y'}, 'dependent', 'z' );
    
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    % the variables are n1, n2 sx1,sx2 sy1,sy2 x1,x2 y1 y2
    %opts.Lower =        [0.7*nTotal  xFWHM/10        yFWHM/10       xpeak-30     ypeak-30];
    %opts.StartPoint =   [nTotal      xFWHM           yFWHM           xpeak        ypeak];
    %opts.Upper =        [1.3*nTotal  inf             inf            xpeak+30     ypeak+30];
    opts.Lower =        [-inf    -inf   xFWHM/10 xFWHM/10 yFWHM/10 yFWHM/10 xpeak-30 xpeak-30 ypeak-30 ypeak-30];
    opts.StartPoint =   [nTotal  nTotal xFWHM    xFWHM    yFWHM    yFWHM    xpeak    xpeak    ypeak    ypeak];
    opts.Upper =        [inf     inf    inf      inf      inf      inf      xpeak+30 xpeak+30 ypeak+30 ypeak+30];    
    
    
% % % %     add a position constraint by hand if we want
% % %      
% % % % %     x1
%     opts.Lower(7) = 212 - 10;% 248.3227 - 5
%     opts.Upper(7) = 212 + 10;%
%     
% % % %     y1
%     opts.Lower(9) = 267.7 - 10; %279.3659
%     opts.Upper(9) = 267.7 + 10;
% 
% % % % %     x2
%     opts.Lower(8) = 17 - 10;% 248.3227 - 5
%     opts.Upper(8) = 17 + 10;%
%     
% % % %     y2
%     opts.Lower(10) = 17 - 10; %279.3659
%     opts.Upper(10) = 17 + 10;
%     
% % %     add a width constraint by hand if we want
    
% % %     sx
%    opts.Lower(2) = 6.0793 * 0.70;
%    opts.Upper(2) = 6.0793 * 1.30;
    
% % %     sy
%    opts.Lower(3) = 5.5589 * 0.70;
%    opts.Upper(3) = 5.5589 * 1.30;
% % %      
% %     opts.Lower =        [0.7*nTotal  xroi/8           xroi/8       xpeak-30     ypeak-30];
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