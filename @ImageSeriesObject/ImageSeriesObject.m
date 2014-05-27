classdef ImageSeriesObject < dynamicprops
    properties (SetAccess = protected)
        imageHandles
        imageVariables
        imageroi
    end
    properties (Hidden=true)
        membersChanged = false;
    end
    properties (SetAccess = immutable)
        IMAGECLASS
    end
    methods
        function obj = ImageSeriesObject(varargin)
           p = inputParser;
           p.CaseSensitive = false;
           p.KeepUnmatched = true;
           defaultImageClass = 'CloudImageObject';
           expectedImageClass = {'AbsorptionImageObject','CloudImageObject','BECImageObject'};
           addOptional(p,'imageclass',defaultImageClass,@(x) any(validatestring(x,expectedImageClass)));
           addOptional(p,'files','');
           addOptional(p,'magnification',2,@isnumeric);
           addOptional(p,'shots',0);
           addOptional(p,'roi',[]);
           addOptional(p,'imagingDetuning',0);
           parse(p,varargin{:});
           obj.IMAGECLASS = p.Results.imageclass;
           magnification = p.Results.magnification;
           files = p.Results.files;
           shots = p.Results.shots;
           obj.imageroi = p.Results.roi;
           imagingDetuning = p.Results.imagingDetuning;
           delete(p);

           if isempty(files)
               recent = shots;
               if recent > 0
                   storageList = dir(['Z:\' '*.aia']);
                   [~,x]=sort([storageList(:).datenum],'ascend');
                   fileParty = {storageList(x).name}';
                   sizeFP = size(fileParty);
                   sizeFP = sizeFP(1);
                   for i = (1+sizeFP-recent):1:sizeFP
                        filenames{i-sizeFP+recent} = fileParty{i};
                        path = 'Z:\';
                   end
               path = char(path);
               else
               [filenames, path] = ImageSeriesObject.selectFiles('Z:\');
               filenames = strcat(path,filenames);
               end
           else
                filenames = files;
           end

           for i = 1:length(filenames)
               if i == 1
                   if strcmp(obj.IMAGECLASS,'CloudImageObject')
                        tempObj = CloudImageObject('magnification',magnification,'file',[filenames{i}],'imagingDetuning',imagingDetuning,'roi',obj.imageroi);
                   elseif strcmp(obj.IMAGECLASS,'BECImageObject')
                        tempObj = BECImageObject('magnification',magnification,'file',[filenames{i}],'imagingDetuning',imagingDetuning,'roi',obj.imageroi);
                   end
                   obj.imageroi = tempObj.roi;
                   
                   imVars = tempObj.variables;
                   vals=zeros(1,length(imVars));
                   valHasChanged=zeros(1,length(imVars));
                   goodvals = zeros(1,length(imVars));
                   for j=1:length(imVars)
                       val=tempObj.(imVars{j});
                       if isnumeric(val)
                           vals(j)=val;
                           goodvals(j)=1;
                       end
                   end
                   imVars = imVars(goodvals==1);
                   vals = vals(goodvals==1);
                   valHasChanged=valHasChanged(goodvals==1);
               else
                   if strcmp(obj.IMAGECLASS,'CloudImageObject')
                        tempObj=CloudImageObject('magnification',magnification,'file',[filenames{i}],'roi',obj.imageroi,'imagingDetuning',imagingDetuning);
                   elseif strcmp(obj.IMAGECLASS,'BECImageObject')
                        tempObj=BECImageObject('magnification',magnification,'file',[filenames{i}],'roi',obj.imageroi,'imagingDetuning',imagingDetuning);
                   end
                   [imVars,ind]= intersect(imVars,tempObj.variables);
                   vals=vals(ind);
                   valHasChanged=valHasChanged(ind);
                   for j=1:length(vals)
                       if tempObj.(imVars{j})~=vals(j)
                           valHasChanged(j) = 1;
                       end
                   end
               end
               obj.imageHandles{i} = tempObj;
               assignin('base', genvarname(filenames{i}), obj.imageHandles{i});
           end
           
           obj.imageVariables = imVars(valHasChanged==1);
           %%%%%%%%%
           
%            BigPropList=properties(obj.imageHandles{1});
%            for i=1:length(BigPropList)
%                propMeta = addprop(obj,BigPropList{i});
%                littlePropList = zeros(length(obj.imageHandles));
%                for j=1:length(obj.imageHandles)
%                     littlePropList(i) =obj.imageHandles{j}.(BigPropList{i}); 
%                end
%                obj.(BigPropList{i})= littlePropList;
%                propMeta.SetAccess = 'protected';
%                propMeta.Hidden = true;
%                propMeta.Dependent = true;
%            end
        end
        function addImages(obj, varargin)
           if (nargin-1)
               filenames=varargin{1};
               path=pwd;
           else
               [filenames, path] = ImageSeriesObject.selectFiles();
           end
           
           iStart=length(obj.imageHandles);
           for i=1:length(filenames)
               tempObj=CloudImageObject('file',[filenames{i}]);
%                if ~ isequal(tempObj.variables, obj.imageVariables)
%                    error('Variable mismatch between members of image series!')
%                end
               obj.imageHandles{iStart+i}=tempObj;
               assignin('base',genvarname(filenames{i}),obj.imageHandles{iStart+i}); 
           end
           obj.membersChanged = true;
        end
        function removeImages(obj, varargin)
            if ~nargin
                error('No Input')
            elseif isnumeric(varargin{1})
                removalIndex=varargin{1};
                obj.imageHandles(removalIndex)=[];
            else
                error('Input not image index')
            end
            obj.membersChanged = true;
        end
        function varargout = show(obj,varargin)
            numberOfImages=length(obj.imageHandles);
            if (nargin-1) 
                [imlist,proplist]=obj.orderedList(varargin{1});
                figureTitle=varargin{1};
            else
                imlist=obj.imageHandles;
                for i=1:numberOfImages
                    filename=obj.imageHandles{i}.filename;
                    proplist{i}=['...' filename(12:19)];
                end
                figureTitle='filename';
            end
            for i=1:numberOfImages
                images{i}=imlist{i}.opticalDensity;
            end
            h = figure('name',figureTitle);
            text(.25,1.25,figureTitle)
            hold on
            a=gca;
            columns=5;
            rows=ceil(numberOfImages/columns);
            for i=1:numberOfImages
                subplot(rows,columns,i)
                imshow(imresize(images{i},.1),'Border','tight')
                title(proplist(i))
            end
            varargout{1}=h;
            hold off
        end
        function varargout = movie(obj,varargin)
            numberOfImages=length(obj.imageHandles);
            if (nargin-1) 
                [imlist,proplist]=obj.orderedList(varargin{1});
                figureTitle=varargin{1};
            else
                imlist=obj.imageHandles;
                for i=1:numberOfImages
                    filename=obj.imageHandles{i}.filename;
                    proplist{i}=['...' filename(12:19)];
                end
                figureTitle='filename';
            end
            imstack=zeros([size(imlist{1}.normalizedImage) numberOfImages]);
            for i=1:numberOfImages
                imstack(:,:,i)=imlist{i}.normalizedImage;
            end
            varargout{1} = implay(imstack,3);
            
        end
        function tf=isprop(obj,prop)
            tf=true;
            i=1;
            while tf && i<=length(obj.imageHandles)
                if ~isprop(obj.imageHandles{i},prop)
                    tf = false;   
                end
                i=i+1;
            end
        end     
        function [imageList,varList] = orderedList(obj,prop)
           if isprop(obj,prop)
               for i=1:length(obj.imageHandles)
                    varList(i)=obj.imageHandles{i}.(prop);
                    imageList(i)=obj.imageHandles(i);
                end
                [varList,sortIndex]=sort(varList);
                imageList=imageList(sortIndex);
           else
                error('Property not found in series!')
           end
        end
        function propList = getProp(obj,prop)
            if isprop(obj.imageHandles{1},prop)
                if numel(obj.imageHandles{1}.(prop))==1
                    propList = zeros(length(obj.imageHandles),1);
                    for i=1:length(obj.imageHandles)
                        propList(i)=obj.imageHandles{i}.(prop);
                    end
                else
                    propList = cell(length(obj.imageHandles),1);
                    for i=1:length(obj.imageHandles)
                        propList{i}=obj.imageHandles{i}.(prop);
                    end
                end
            else
                error('not a property of objects in this series')
            end
        end
        function prop = getPropMean(obj, prop)
            prop_list = obj.getProp(prop);
            prop_mean = mean(prop_list);
            prop_std = std(prop_list);
            if length(prop_list) > 1
                prop_std = prop_std / sqrt(length(prop_list) - 1);
            end
            prop = [prop_mean, prop_std];
        end
        function [yBinned,yBinnedSTD,xBinned] = errvector(obj,xProp,yProp)
            if isprop(obj,xProp) && isprop(obj,yProp)
                for i=1:length(obj.imageHandles)
                    xPropList(i)=obj.imageHandles{i}.(xProp);
                    yPropList(i)=obj.imageHandles{i}.(yProp);
                end
                xBinned=unique(xPropList);
                for i=1:length(xBinned)
                    yBinned(i) = mean(yPropList(xPropList == xBinned(i)));
                    yBinnedSTD(i) = std(yPropList(xPropList == xBinned(i)))/sqrt(nnz(xPropList == xBinned(i)));
                end
            end
        end
        function varargout = plot(obj,xProp,yProp,varargin)
            p=inputParser;
            addRequired(p,'xProp',@ischar);
            addRequired(p,'yProp',@ischar);
            addOptional(p,'supressfigure',false,@islogical);
            defaultStyle={...
                'o',...
                'Color',[0;25;205]/255.,...
                'MarkerSize',4.5,...
                'MarkerFaceColor',[0;25;205]/255.,...
                'MarkerEdgeColor','k'};
            addOptional(p,'styleoptions',defaultStyle,@iscell);
       
            
            parse(p,xProp,yProp,varargin{:})
            xProp = p.Results.xProp;
            yProp = p.Results.yProp;
            supressFigure = p.Results.supressfigure;
            styleOptions = p.Results.styleoptions;
            
            varargout={};
            
            if isprop(obj,xProp) && isprop(obj,yProp)
                for i=1:length(obj.imageHandles)
                    xPropList(i)=obj.imageHandles{i}.(xProp);
                    yPropList(i)=obj.imageHandles{i}.(yProp);
                end
                
                if supressFigure
                    h = gcf;
                else
                    h=figure;
                end
                
                plot(xPropList,yPropList,styleOptions{:});
                ylabel(yProp)
                xlabel(xProp)
                title([yProp ' vs ' xProp])
                varargout{1}=h;
            else
                error([xProp ' and ' yProp ' are not properties of all objects in the series.'])
            end
        end
        function varargout = ploterr(obj,xProp,yProp,varargin)
            p=inputParser;
            addRequired(p,'xProp',@ischar);
            addRequired(p,'yProp',@ischar);
            addOptional(p,'supressfigure',false,@islogical);
            defaultStyle={...
                'o',...
                'Color',[0;25;205]/255.,...
                'MarkerSize',4.5,...
                'MarkerFaceColor',[0;25;205]/255.,...
                'MarkerEdgeColor','k'};
            addOptional(p,'styleoptions',defaultStyle,@iscell);
            
            parse(p,xProp,yProp,varargin{:})
            xProp = p.Results.xProp;
            yProp = p.Results.yProp;
            supressFigure = p.Results.supressfigure;
            styleOptions = p.Results.styleoptions;
            
            varargout={};
            if isprop(obj,xProp) && isprop(obj,yProp)
                for i=1:length(obj.imageHandles)
                    xPropList(i)=obj.imageHandles{i}.(xProp);
                    yPropList(i)=obj.imageHandles{i}.(yProp);
                end
                xBinned=unique(xPropList);
                for i=1:length(xBinned)
                    yBinned(i) = mean(yPropList(xPropList == xBinned(i)));
                    yBinnedSTD(i) = std(yPropList(xPropList == xBinned(i)))/sqrt(nnz(xPropList == xBinned(i)));
                end
                
                if supressFigure
                    h = gcf;
                else
                    h=figure;
                end
                
                errorbar(xBinned,yBinned,yBinnedSTD,styleOptions{:});
                ylabel(yProp)
                xlabel(xProp)
                title([yProp ' vs ' xProp])
                grid on
                varargout{1}=h;
            end
        end
        function varargout = paramplot(obj,xProp,yProp,paramProp,varargin)
%             [imgList,varList]=obj.orderedList(paramProp);
%             [paramPropVals,imgStartIndx]=unique(varList);
%             imgEndIndx=vertcat(imgStartIndx(2:end)-1, numel(varList));
            tempList = CompositeSeriesObject('files',obj.filenames{:},'sortby',paramProp);
            
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
            
            for i=1:length(tempList.seriesHandles)
                mod(i,length(colors))
                style = {...
                    'o',...
                    'Color',colors{mod(i-1,length(colors))+1},...
                    'MarkerSize',4.5,...
                    'MarkerFaceColor',colors{mod(i-1,length(colors))+1},...
                    'MarkerEdgeColor','k'};
                tempList.seriesHandles{i}.ploterr(xProp,yProp,'supressfigure',true,'styleoptions',style);
            end
            
            hold off
            leg=cell(1,length(tempList.seriesHandles));
            for i=1:length(tempList.seriesHandles)
                leg{i}=num2str(tempList.seriesHandles{i}.(tempList.sortParameter));
            end
            legHandle = legend(leg);
            set(get(legHandle, 'title'),'string',tempList.sortParameter);
            varargout{1}=h;
        end
        function varargout = uiplot(obj,xProp,yProp,varargin)
            [parent,parentFigure,param,averaging,styleOptions] = parseInput(varargin{:});
            
            h=figure(parentFigure);
            if isempty(param)
                if averaging
                    [yBinned,yBinnedSTD,xBinned] = errvector(obj,xProp,yProp);
                    axes('Parent',parent)
                    errorbar(xBinned,yBinned,yBinnedSTD,styleOptions{:});
                else
                    xPropList=obj.getProp(xProp);
                    yPropList=obj.getProp(yProp);
                    axes('Parent',parent)
                    plot(xPropList,yPropList,styleOptions{:},'Parent',parent)
                end
            else
                tempList = CompositeSeriesObject('files',obj.filenames,'sortby',paramProp);
            end
            title([yProp ' vs ' xProp])
            ylabel(yProp)
            xlabel(xProp)
            
            if nargout
                varargout{1}=h;
            end
            
            function [parent,parentFigure,param,averaging,styleOptions] = parseInput(varargin)
                p=inputParser;
                addOptional(p,'param',[]);
                addOptional(p,'figure',[])
                addOptional(p,'parent',[]);
                addOptional(p,'averaging',true,@islogical)
                defaultStyle={...
                    'o',...
                    'Color',[0;25;205]/255.,...
                    'MarkerSize',4.5,...
                    'MarkerFaceColor',[0;25;205]/255.,...
                    'MarkerEdgeColor','k'};
                addOptional(p,'styleoptions',defaultStyle);
                parse(p,varargin{:});
                parentFigure = p.Results.figure;
                parent = p.Results.parent;
                param = p.Results.param;
                averaging = p.Results.averaging;
                styleOptions = p.Results.styleoptions;
                
                if isempty(parentFigure)
                    parentFigure = figure;
                end
                if isempty(parent)
                    parent= uiextras.VBox('Parent',parentFigure);
                end
            end
                
        end
        
        
        function hlist = findImagesWithProp(obj,PropName,PropValue)
            hlist=[];
            for i=1:length(obj.imageHandles)
                if isprop(obj.imageHandles{i},PropName)
                    if obj.imageHandles{i}.(PropName)==PropValue
                        hlist{length(hlist)+1}=obj.imageHandles{i};
                    end
                end
            end
        end  
        function varargout = mathploterr(obj,xProp,yProp,varargin)
            for i = 1:length(obj.imageHandles)
                px{i} = addprop(obj.imageHandles{i},'tempxProp');
                py{i} = addprop(obj.imageHandles{i},'tempyProp');
                obj.imageHandles{i}.tempxProp = obj.imageHandles{i}.math(xProp);
                obj.imageHandles{i}.tempyProp = obj.imageHandles{i}.math(yProp);
            end
            obj.ploterr(tempxProp,tempyProp)
            for i = 1:length(obj.imageHandles)
               delete(px{i});
               delete(py{i});
            end       
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
    methods (Access = protected)
        function makeLegend(obj,property)
            if isprop(obj,property)
                legend=cell(1,length(obj.imageHandles));
                for i=1:length(obj.imageHandles)
                    legend{i}=num2str(obj.imageHandles{i}.(property));
                end
            end
        end
    end
    methods ( Static = true)
        [filenames, filepaths] = selectFiles(varargin) %UI to select a file
        objList = findall()
        h = displaySeries(varargin)
    end
end