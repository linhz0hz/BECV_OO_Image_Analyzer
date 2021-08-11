function [fitresult, gof] = becfit2(OD, roi)
    xRegion = round(roi(1))+(0:round(roi(3)));
    yRegion = round(roi(2))+(0:round(roi(4)));
    X = reshape(repmat(xRegion',1,numel(yRegion))',1,[]);
    Y = repmat(yRegion,1,numel(xRegion));
    Z = reshape(OD(yRegion,xRegion),1,[]);
    
    OD=OD(yRegion,xRegion);
    xProjection = sum(OD,1);
    yProjection = sum(OD,2)';
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
    
    ft = fittype( 'nTotal*(1-cf)/(2*pi*sx*sy)/1.202*gbec(2,exp(-((x-x0)^2/sx^2+(y-y0)^2/sy^2)/2),3)+nTotal*cf*5/(2*pi*rx*ry)*max((1-(x-x0)^2/rx^2-(y-y0)^2/ry^2),0)^(3/2)', 'independent', {'x', 'y'}, 'dependent', 'z' );
  % ft = fittype( 'nTotal*(1-cf)/(2*pi*sx*sy)/1.202*gbec(2,exp(-((x-x0)^2/sx^2+(y-y0)^2/sy^2)/2),3)+nTotal*cf*5/(2*pi*(alphax*sx)*(alphay*sy))*max((1-(x-x0)^2/(alphax*sx)^2-(y-y0)^2/(alphay*sy)^2),0)^(3/2)', 'independent', {'x', 'y'}, 'dependent', 'z' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    
    opts.Lower =        [0      0.7*nTotal  xFWHM/10        yFWHM/10        xFWHM       yFWHM       xpeak-30     ypeak-30];
    opts.StartPoint =   [.9     nTotal      xFWHM           yFWHM           10*xFWHM	10*yFWHM    xpeak        ypeak];
    opts.Upper =        [1      1.3*nTotal  inf             inf             20*xFWHM    20*yFWHM    xpeak+30     ypeak+30];
    
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