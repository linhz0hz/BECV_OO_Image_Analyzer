function [fitresult, gof] = fitLifetime(xval, yval, weights)
    % Fit: 'untitled fit 8'.
    [xData, yData, weights] = prepareCurveData( xval, yval, weights);
    
    % Set up fittype and options.
    ft = fittype( 'a*exp(-x/b)', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.Lower = [0 -Inf];
    opts.StartPoint = [max(max(yval)) 1/2*mean(mean(xval))];
    opts.Weights = weights;
    
    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, opts );
    
%     % Plot fit with data.
%     figure( 'Name', 'untitled fit 8' );
%     h = plot( fitresult, xData, yData );
%     legend( h, 'nC vs. time', 'untitled fit 8', 'Location', 'NorthEast' );
%     % Label axes
%     xlabel( 'time' );
%     ylabel( 'nC' );
%     grid on
    
    
