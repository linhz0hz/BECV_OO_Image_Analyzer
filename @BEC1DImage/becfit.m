function [fitresult, gof] = becfit(proj)
    
    xRegion = 1:numel(proj);    
    X=sum(proj(:,xRegion),1);

    
    %% Fit: 'untitled fit 1'.
    [xData, xRegion] = prepareCurveData(X,xRegion);
    
    [xpeak,xindex]=max(xData);
    
    % Set up fittype and options.
    ft = fittype( 'nth/sqrt(2*pi*thermalwidth^2)/1.2021*gbec(5/2,exp(-(x-x0).^2/(2*thermalwidth^2)),3)+15/16*nbec/becwidth*max(0,1-(x-x0).^2/(becwidth^2))', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.Lower = [0 0 0 0 0];
    opts.StartPoint = [40 1000 500 30 240];
    opts.StartPoint = [20 xpeak*20 xpeak*sqrt(2*pi*20^2) 40 xindex]; %in the order: [becwidth nbec nth thermalwidth x0]
    
    % Fit model to xdata.
    [fitresult, gof] = fit( xRegion, xData, ft, opts );       
