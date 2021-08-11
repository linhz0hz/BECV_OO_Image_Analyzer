function [fitresult, gof] = becfit(OD, roi)
    
    xRegion = round(roi(1))+(0:round(roi(3)));
    yRegion = round(roi(2))+(0:round(roi(4)));
    
    X=sum(OD(:,xRegion),1);
    Y=sum(OD(yRegion,:),2);
    
    %% Fit: 'untitled fit 1'.
    [xData, xRegion] = prepareCurveData(X,xRegion);
    [yData, yRegion] = prepareCurveData(Y,yRegion);
    
    [xpeak,xindex]=max(xData);
    [ypeak,yindex]=max(yData);
    
    % Set up fittype and options.
    'nth/gbec(2,1,3)*gbec(2,exp(-((x-x0)/sxth)^2/2-((y-y0)/syth)^2/2),3)+nbec*max((1-((x-x0)/sxbec)^2-((y-y0)/sybec)^2),0)^(3/2)', 'independent', {'x', 'y'}, 'dependent', 'z' );
    ft = fittype( 'a*gbec(3/2,exp(-(x-b).^2/(2*c^2)),3)+d*max(0,1-(x-b).^2/(f^2))', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.Lower = [0 0 0 0 0];
    opts.StartPoint = [peak peak/10 length(OD)/100 length(OD)/20 xData(index)]; %in the order: [nbec nth sxbec sxth x0]
    
    % Fit model to xdata.
    [xfitresult, xgof] = fit( xRegion, xData, ft, opts );
        
    % Fit model to ydata.
    [yfitresult, ygof] = fit( xRegion, xData, ft, opts );
    
    
        
