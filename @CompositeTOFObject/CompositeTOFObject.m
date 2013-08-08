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
            style = {...
                'o',...
                'MarkerSize',4.5,...
                'MarkerFaceColor',colors{mod(i,length(colors))},...
                'MarkerEdgeColor','k'};
            for i=1:length(obj.seriesHandles)    
                errorbar(obj.seriesHandles{i}.(obj.sortParameter),obj.seriesHandles{i}.xTemperature,...
                    obj.seriesHandles{i}.xTemperatureError,style{:},'Color',[0;25;205]/255.);
                errorbar(obj.seriesHandles{i}.(obj.sortParameter),obj.seriesHandles{i}.yTemperature,...
                    obj.seriesHandles{i}.yTemperatureError,style{:},'Color',[205;38;38]/255.);
                legend('xTemperature','yTemperature')
%                 title([yProp ' vs ' xProp])
                varargout{1}=h;
            end
        end
    end
end