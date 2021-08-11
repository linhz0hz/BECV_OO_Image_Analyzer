function [fitresult, gof] = becfit2(OD, roi)
    
    xRegion = round(roi(1))+(0:round(roi(3)));
    yRegion = round(roi(2))+(0:round(roi(4)));
    X = reshape(repmat(xRegion',1,numel(yRegion))',1,[]);
    Y = repmat(yRegion,1,numel(xRegion));
    Z = reshape(OD(yRegion,xRegion),1,[]);
    ind = 1:length(X);% abs(Z)>=(median(reshape(OD,1,[])));
    X = X(ind);
    Y = Y(ind);
    Z = Z(ind);
    
    OD=OD(yRegion,xRegion);
    xProjection = sum(OD,1);
    yProjection = sum(OD,2)';
    xcm=sum(xRegion.*xProjection)/sum(xProjection);
    ycm=sum(yRegion.*yProjection)/sum(yProjection);
    xwidth=sqrt(sum((xRegion-xcm).^2.*xProjection)/sum(xProjection));
    ywidth=sqrt(sum((yRegion-ycm).^2.*yProjection)/sum(yProjection)); 

    % Clean up data
    [xData, yData, zData] = prepareSurfaceData( X, Y, Z );
    
    % Sum total number
    ntotal=sum(xProjection);
    
    %Find peak position
%     [peakVal, peakPos] = max(zData);
    
    % Set up fittype and options.
    ft = fittype( 'nth/gbec(2,1,3)*gbec(2,exp(-((x-x0)/sxth)^2/2-((y-y0)/syth)^2/2),3)+nbec*max((1-((x-x0)/sxbec)^2-((y-y0)/sybec)^2),0)^(3/2)', 'independent', {'x', 'y'}, 'dependent', 'z' );
    %ft = fittype( 'nth/(2*pi*sxth*syth*1.202)*gbec(2,exp(-(((x-x0)/sxth)^2+((y-y0)/syth)^2)/2),20)+nbec*5/(2*pi*sxbec*sybec)*max((1-((x-x0)/sxbec)^2-((y-y0)/sybec)^2),0)^(3/2)', 'independent', {'x', 'y'}, 'dependent', 'z' );

    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
  
    opts.Display = 'Off';
    opts.Lower = [0 0 0 0 0 0 xcm-.5*xwidth-1 ycm-.5*ywidth-1];
    opts.Upper = [Inf Inf Inf Inf Inf Inf xcm+.5*xwidth+1 ycm+.5*ywidth+1];
    opts.MaxFunEvals = 600;
    opts.MaxIter = 200;
    %opts.StartPoint = [peakVal/5 peakVal/200 numel(xRegion)/20 numel(xRegion)/2 numel(yRegion)/20 numel(yRegion)/2 xData(peakPos) yData(peakPos)];
    opts.StartPoint = [peakVal/5 peakVal/200 xwidth 2*xwidth ywidth 2*ywidth xcm ycm];
    opts.TolX = 1e-2;
    opts.TolFun = 1e-5;
    opts.DiffMinChange = 1e-8;
    opts.DiffMaxChange = 1e-7;
    % Fit model to data.
    tic
    [fitresult, gof] = fit( [xData, yData], zData, ft, opts );
    toc