classdef TOFSeriesObject < ImageSeriesObject
properties (SetAccess=protected)
    toffset%
end
properties (Hidden = true)
    xWidthCache=0;
    yWidthCache=0;
end
properties (Constant)
    SERIES_VARIABLE='TOF';    
end

properties (SetAccess=protected,Dependent=true)
    xWidthFit%
    yWidthFit%
    xTemperature%temperature calculated from projected x widths in mK
    yTemperature%temperature calculated from projected y widths in mK
    xTemperatureError%error in temperature calculated from projected x widths in mK
    yTemperatureError%error in temperature calculated from projected y widths in mK
    xInitialWidth%initial cloud width calculated from projected x widths in meters
    yInitialWidth%initial cloud width calculated from projected y widths in meters
    xInitialWidthError%error in initial cloud width calculated from projected x widths in meters
    yInitialWidthError%error in initial cloud width calculated from projected y widths in meters
end
methods
    function obj = TOFSeriesObject(varargin)
        p = inputParser;
        p.CaseSensitive = false;
        p.KeepUnmatched = true;
        addOptional(p, 'toffset', 0, @isnumeric);
        parse(p, varargin{:});
        toffset = p.Results.toffset;
        delete(p);
        obj = obj@ImageSeriesObject(varargin{:});
        obj.toffset= toffset;
        obj.membersChanged=true;
        obj.xWidthFit;
        obj.yWidthFit;
                
%         if ismember({'TOF'},obj.imageVariables)
%             
%             for i=1:length(obj.imageHandles)
%                 xWidth(i)=obj.imageHandles{i}.xWidth...
%                     *obj.imageHandles{i}.PIXEL_SIZE/obj.imageHandles{i}.magnification;
%                 yWidth(i)=obj.imageHandles{i}.yWidth...
%                     *obj.imageHandles{i}.PIXEL_SIZE/obj.imageHandles{i}.magnification;
%                 time(i)=(obj.imageHandles{i}.TOF+obj.toffset)*10^-3;                                
%             end
%             
%             obj.xWidthFit=LinearModel.fit((time.^2)',(xWidth.^2)');
%             obj.yWidthFit=LinearModel.fit((time.^2)',(yWidth.^2)');
%             
%         else
%             error('Series does not contain TOF data, you idiot!')
%         end
%         a=obj.getProp('nC')
%         nCheck = LinearModel.fit(a(1),)
    end
    function xWidthFit = get.xWidthFit(obj)
        if obj.membersChanged
            if ismember({'TOF'},obj.imageVariables)
            
                for i=1:length(obj.imageHandles)
                    xWidth(i)=obj.imageHandles{i}.xWidth...
                       *obj.imageHandles{i}.PIXEL_SIZE/obj.imageHandles{i}.magnification;
                    time(i)=(obj.imageHandles{i}.TOF+obj.toffset)*10^-3;                                
                end
            
                xWidthFit=LinearModel.fit((time.^2)',(xWidth.^2)');
                obj.xWidthCache = xWidthFit;
            else
                error('Series does not contain TOF data, you idiot!')
            end
        else
            xWidthFit = obj.xWidthCache;
        end
    end
    function yWidthFit = get.yWidthFit(obj)
        if obj.membersChanged
            if ismember({'TOF'},obj.imageVariables)
            
                for i=1:length(obj.imageHandles)
                    yWidth(i)=obj.imageHandles{i}.yWidth...
                       *obj.imageHandles{i}.PIXEL_SIZE/obj.imageHandles{i}.magnification;
                        
                    time(i)=(obj.imageHandles{i}.TOF+obj.toffset)*10^-3;                                
                end
            
                yWidthFit=LinearModel.fit((time.^2)',(yWidth.^2)');
                obj.yWidthCache = yWidthFit;
            else
                error('Series does not contain TOF data, you idiot!')
            end
        else
            yWidthFit = obj.yWidthCache;
        end
    end
    function xTemperature = get.xTemperature(obj)
        xTemperature=obj.xWidthFit.Coefficients{2,1}*...
                obj.imageHandles{1}.MASS/obj.imageHandles{1}.BOLTZMANN_CONSTANT*10^6;
    end
    function yTemperature = get.yTemperature(obj)
        yTemperature=obj.yWidthFit.Coefficients{2,1}*...
                obj.imageHandles{1}.MASS/obj.imageHandles{1}.BOLTZMANN_CONSTANT*10^6;
    end
    function xTemperatureError = get.xTemperatureError(obj)
        xTemperatureError=obj.xWidthFit.Coefficients{2,2}*...
                obj.imageHandles{1}.MASS/obj.imageHandles{1}.BOLTZMANN_CONSTANT*10^3;
    end
    function yTemperatureError = get.yTemperatureError(obj)
        yTemperatureError=obj.yWidthFit.Coefficients{2,2}*...
                obj.imageHandles{1}.MASS/obj.imageHandles{1}.BOLTZMANN_CONSTANT*10^3;
    end
    function xInitialWidth = get.xInitialWidth(obj)
        xInitialWidth=sqrt(obj.xWidthFit.Coefficients{1,1});
    end
    function yInitialWidth = get.yInitialWidth(obj)
        yInitialWidth=sqrt(obj.yWidthFit.Coefficients{1,1});
    end
    function xInitialWidthError = get.xInitialWidthError(obj)
        xInitialWidthError=sqrt(obj.xWidthFit.Coefficients{1,2});
    end
    function yInitialWidthError = get.yInitialWidthError(obj)
        yInitialWidthError=sqrt(obj.yWidthFit.Coefficients{1,2});
    end    
    function set.xWidthFit(obj,val)
        obj.xWidthFit=val;
    end
    function set.yWidthFit(obj,val)
        obj.yWidthFit=val;
    end
    function varargout = showFits(obj)
        varargout{1}=figure;
        plot(obj.xWidthFit)
        title('x^2 vs t^2')
        varargout{2}=figure;
        plot(obj.yWidthFit)
        title('y^2 vs t^2')
    end    
    function varargout = showWidths(obj)
        hold on
        varargout{1}=figure;
        cm=colormap(winter(length(obj.imageHandles)));
        for i=1:length(obj.imageHandles)
            subplot(2,1,1)
            plot(obj.imageHandles{i}.xProjection,'color',cm(i,:))
            title('x fits')
            hold on
            subplot(2,1,2)
            plot(obj.imageHandles{i}.yProjection,'color',cm(i,:))
            title('y fits')
            hold on
        end
        %subplot(2,1,1)
        %title('x fits')
        %subplot(2,1,2)
        %title('y fits')
        hold off
    end
end
      
end