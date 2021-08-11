classdef LifetimeSeriesObject < ImageSeriesObject
    properties (SetAccess = protected)
        tau
        tauErr
        fit
    end
    methods
        function obj = LifetimeSeriesObject(varargin)
            p = inputParser;
            p.CaseSensitive = false;
            p.KeepUnmatched = true;
%             addOptional(p, 'toffset', 0, @isnumeric);
            parse(p, varargin{:});
            delete(p);
            obj = obj@ImageSeriesObject(varargin{:});
            obj.fit = obj.calculateFit();
            obj.tau = obj.calculateTau();
            obj.tauErr = obj.calculateTauErr();
        end
        
        function fit = calcuateFit(obj)
            [y,yerr,x]=obj.errvector(selectxvar(),selectyvar());
            fit = fitLifetime(x,y,yerr);
        end
        function tau = calcualteTau(obj)
            tau=obj.fit.b;
        end
        function tauErr = calculateTauErr(obj)
            tauErr=obj.fit.Coefficients{1,2};
        end        
        function yvar = selectyvar(obj)
            yvar = 'time';
        end
        function selectxvar(obj)
            xyar = 'nBEC';
        end
        function h = showFit(obj)
            figure( 'Name', 'untitled fit 8' );
            h = plot( obj.fit, xData, yData );
            % Label axes
            xlabel( 'time' );
            ylabel( obj.selectyvar() );
            grid on
        end
    end
    
    
    
    methods (Static = true)
        [fit, gof] = fitLifetime(x,y)
    end 
end