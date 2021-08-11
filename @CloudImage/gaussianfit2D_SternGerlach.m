function [fitresult, gof] = gaussianfit2D_SternGerlach(OD, roi)
    xRegion = round(roi(1))+(0:round(roi(3)));
    yRegion = round(roi(2))+(0:round(roi(4)));
    X = reshape(repmat(xRegion',1,numel(yRegion))',1,[]);
    Y = repmat(yRegion,1,numel(xRegion));
    Z = reshape(OD(yRegion,xRegion),1,[]);
    
    xc=260;
    xa=260;
    yc=247;
    ya=292;
    
    dd=7;
    
    %sample the location of na and nc
    nc_init=max(max(OD(yc-dd:yc+dd,xc-dd:xc+dd)));
    na_init=max(max(OD(ya-dd:ya+dd,xa-dd:xa+dd)));
    
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
    
    ft=fittype('nTotal1/(2*pi*sx1*sy1)*exp(-(x-x01)^2/(2*sx1^2)-(y-y01)^2/(2*sy1^2)) + nTotal2/(2*pi*sx2*sy2)*exp(-(x-x02)^2/(2*sx2^2)-(y-y02)^2/(2*sy2^2))','independent', {'x', 'y'}, 'dependent', 'z');
%     ft = fittype( 'nTotal*(1-cf)/(2*pi*sx*sy)/1.202*gbec(2,exp(-((x-x0)^2/sx^2+(y-y0)^2/sy^2)/2),3)+nTotal*cf*5/(2*pi*rx*ry)*max((1-(x-x0)^2/rx^2-(y-y0)^2/ry^2),0)^(3/2)','independent', {'x', 'y'}, 'dependent', 'z' );
  % ft = fittype( 'nTotal*(1-cf)/(2*pi*sx*sy)/1.202*gbec(2,exp(-((x-x0)^2/sx^2+(y-y0)^2/sy^2)/2),3)+nTotal*cf*5/(2*pi*(alphax*sx)*(alphay*sy))*max((1-(x-x0)^2/(alphax*sx)^2-(y-y0)^2/(alphay*sy)^2),0)^(3/2)', 'independent', {'x', 'y'}, 'dependent', 'z' );
    
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    % the variables are nTotal1, nTotal2, sx1, sx2, sy1, sy2, x01, x02, y01, y02
    %opts.Lower =        [0.7*nTotal  xFWHM/10        yFWHM/10       xpeak-30     ypeak-30];
    %opts.StartPoint =   [nTotal      xFWHM           yFWHM           xpeak        ypeak];
    %opts.Upper =        [1.3*nTotal  inf             inf            xpeak+30     ypeak+30];
    opts.Lower =        [0     0      xFWHM/10   xFWHM/10     yFWHM/10  yFWHM/10     xpeak-30   xpeak-30  ypeak-30 ypeak-30];
    opts.StartPoint =   [nc_init   na_init    xFWHM      xFWHM        yFWHM      yFWHM         xpeak     xpeak     ypeak        ypeak];
    opts.Upper =        [inf       inf      inf        inf          inf        inf          xpeak+30   xpeak+30     ypeak+30 ypeak+30];    
    
    
% % % % %     add a position constraint by hand if we want
%    
%%%   x0 NC (TOP)
    opts.Lower(7) = xc - 10;% 248.3227 - 5
    opts.Upper(7) = xc + 10;%
 %%%   x0 NA (BOTTOM)   
    opts.Lower(8) = xa - 10;% 248.3227 - 5
    opts.Upper(8) = xa + 10;%
     
% %     y0 NC (TOP)
    opts.Lower(9) = yc - 15; %279.3659
    opts.Upper(9) = yc + 15;
 %%% y0 NC (BOTTOM)   
    opts.Lower(10) = ya - 15; %279.3659
    opts.Upper(10) = ya + 15;
% 

% % % % % % %     add a width constraint by hand if we want
%     
% %     dx NC (TOP)
    opts.Lower(3) =14 * (1 - 0.35); %29.5  %14
    opts.Upper(3) =14 * (1 + 0.35);
    % %     dx NA (BOTTOM)
    opts.Lower(4) =14 * (1 - 0.35); %29.5  %14
    opts.Upper(4) =14 * (1 + 0.35);


    % %     dy NC (TOP)
    opts.Lower(5) = 14 * (1 - 0.35); %29.8
    opts.Upper(5) = 14 * (1 + 0.35);
%     
% %     dy NA (BOTTOM)
    opts.Lower(6) = 14 * (1 - 0.25); %29.8
    opts.Upper(6) = 14 * (1 + 0.25);
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