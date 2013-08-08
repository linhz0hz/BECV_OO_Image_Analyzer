classdef CompositeSeriesObject
    
properties (SetAccess = protected)
    seriesHandles
    sortParameter
end
    
properties (SetAccess = immutable)
    SERIESCLASS    
end

methods
    function obj = CompositeSeriesObject(varargin)
        p = inputParser;
        p.CaseSensitive=false;
        p.KeepUnmatched = true;
        addOptional(p,'sortby','');
        addOptional(p,'seriesclass','ImageSeriesObject');
        parse(p,varargin{:});
        obj.sortParameter=p.Results.sortby;
        obj.SERIESCLASS=p.Results.seriesclass;
        storage = ImageSeriesObject(varargin{:});
        delete(p);
        
        params=[];
        for i=1:length(storage.imageHandles)
            currentparam = storage.imageHandles{i}.(obj.sortParameter);
            if isempty(obj.seriesHandles)
                %this is the first one
                params(1)=currentparam;
                if strcmp(obj.SERIESCLASS,'ImageSeriesObject')
                    obj.seriesHandles{1}=ImageSeriesObject('files',{storage.imageHandles{1}.filename});
                elseif strcmp(obj.SERIESCLASS,'TOFSeriesObject')
                    obj.seriesHandles{1}=TOFSeriesObject('files',{storage.imageHandles{1}.filename},varargin{:});
                end
                propMeta = addprop(obj.seriesHandles{1},obj.sortParameter);
                obj.seriesHandles{1}.(obj.sortParameter)=currentparam;
                propMeta.SetAccess = 'protected';
            else
                if ~any(params==storage.imageHandles{i}.(obj.sortParameter))
                    %this is the first one with this param
                    params(length(params)+1)=currentparam;
                    if strcmp(obj.SERIESCLASS,'ImageSeriesObject')
                        obj.seriesHandles{length(obj.seriesHandles)+1} = ImageSeriesObject('files',{storage.imageHandles{i}.filename});
                    elseif strcmp(obj.SERIESCLASS,'TOFSeriesObject')
                        obj.seriesHandles{length(obj.seriesHandles)+1} = TOFSeriesObject('files',{storage.imageHandles{i}.filename},varargin{:});
                    end                    
                    propMeta = addprop(obj.seriesHandles{length(obj.seriesHandles)},obj.sortParameter);
                    obj.seriesHandles{length(obj.seriesHandles)}.(obj.sortParameter)=currentparam;
                    propMeta.SetAccess = 'protected';
                else
                    %one like it exists
                    whichParam = find(params==currentparam);
                    obj.seriesHandles{whichParam}.addImages({storage.imageHandles{i}.filename});
                end
            end  
        end
        
%         obj.seriesHandles = sort(obj.seriesHandles,)
        
    end
    function varargout =  parameterizedPlot(obj,xProp,yProp)
        h=figure;
        hold on
        
        colors={...
            [0;25;205]/255.,...   %"Royal Jesse Blue" <<the #1 Color!!!
            [205;38;38]/255.,...  %"Ivana Red"
            [67;205;128]/255.,... %"Yichao Green"
            [250;128;114]/255.,...%"Colin 'Crew-Neck' Salmon"
            [137;104;205]/255.,...%"Niki Lavender"
            [85;107;47]/255.,...  %"Will's Magical Dark Olive"
            };
        
        for i=1:length(obj.seriesHandles)
            style = {...
                'o',...
                'Color',colors{mod(i,length(colors))},...
                'MarkerSize',4.5,...
                'MarkerFaceColor',colors{mod(i,length(colors))},...
                'MarkerEdgeColor','k'};
            obj.seriesHandles{i}.ploterr(xProp,yProp,'supressfigure',true,'styleoptions',style);
        end
        
        hold off
        leg=cell(1,length(obj.seriesHandles));
        for i=1:length(obj.seriesHandles)
            leg{i}=num2str(obj.seriesHandles{i}.(obj.sortParameter));
        end
        legend(leg);
        varargout{1}=h;
    end
end
end