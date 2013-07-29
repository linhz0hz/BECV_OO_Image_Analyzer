classdef CompositeTOFObject < CompositeSeriesObject
    properties (Dependent)
        
    end
    methods
        function obj = CompositeTOFObject(varargin)
            obj=obj@CompositeSeriesObject('seriesclass','TOFSeriesObject',varargin{:});
        end
        
        function varargout = plottemps(obj)
            varargout={};
            h = figure;
            hold on
            for i=1:length(obj.seriesHandles)    
                errorbar(obj.seriesHandles{i}.(obj.sortParameter),obj.seriesHandles{i}.xTemperature,...
                    obj.seriesHandles{i}.xTemperatureError,'b*');
                errorbar(obj.seriesHandles{i}.(obj.sortParameter),obj.seriesHandles{i}.yTemperature,...
                    obj.seriesHandles{i}.yTemperatureError,'r*');
                legend('xTemperature','yTemperature')
%                 title([yProp ' vs ' xProp])
                varargout{1}=h;
            end
        end
    end
end