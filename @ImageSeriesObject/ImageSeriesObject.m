classdef ImageSeriesObject < dynamicprops
    properties (SetAccess = protected)
        imageHandles
        imageVariables
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
           expectedImageClass = {'AbsorptionImageObject','CloudImageObject'};
           addOptional(p,'imageclass',defaultImageClass,@(x) any(validatestring(x,expectedImageClass)));
           addOptional(p,'files','');
           addOptional(p,'magnification',.25,@isnumeric);
           addOptional(p,'shots',0);
           parse(p,varargin{:});
           obj.IMAGECLASS = p.Results.imageclass;
           magnification = p.Results.magnification;
           files = p.Results.files;
           shots = p.Results.shots;
           delete(p);

           if isempty(files)
               recent = shots;
               if recent > 0
                   fileParty = dir('D:\Data\Current');
                   sizeFP = size(fileParty);
                   sizeFP = sizeFP(1);
                   for i = (1+sizeFP-recent):1:sizeFP
                        filenames{i-sizeFP+recent} = fileParty(i).name;
                        path = 'D:\Data\Current\';
                   end
               path = char(path);
               else
               [filenames, path] = ImageSeriesObject.selectFiles('D:\Data\Current');
               end
           else
                filenames =files;
                path=pwd;
           end

           for i = 1:length(filenames)
               if i == 1
                   tempObj = CloudImageObject('magnification',magnification,'file',[path '\' filenames{i}]);
                   obj.imageVariables = tempObj.variables;
               else
                   tempObj=CloudImageObject('magnification',magnification,'file',[path filenames{i}],'resetROI',false);
                   if ~ ismember(tempObj.variables, obj.imageVariables)
                        error('Variable mismatch between members of image series!');
                   end
               end
               obj.imageHandles{i} = tempObj;
               assignin('base', genvarname(filenames{i}), obj.imageHandles{i}); 
           end
           
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
               tempObj=CloudImageObject('file',[path '\' filenames{i}]);
               if ~ isequal(tempObj.variables, obj.imageVariables)
                   error('Variable mismatch between members of image series!')
               end
               obj.imageHandles{iStart+i}=tempObj;
               assignin('base',genvarname(filenames{i}),obj.imageHandles{iStart+i}); 
           end
           obj.membersChanged = true;
        end
        function removeImage(obj, varargin)
            if ~nargin
                error('No Input')
            elseif isnumeric(varargin{1})
                removalIndex=varargin{1};
                obj.imageHandles=obj.imageHandles([1:(removalIndex-1),(removalIndex+1):length(obj.imageHandles)]);
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
            imstack=zeros([size(imlist{1}.thumbnail) numberOfImages]);
            for i=1:numberOfImages
                imstack(:,:,i)=imlist{i}.thumbnail;
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
            %if any(obj.imageVariables == prop)
                propList = zeros(length(obj.imageHandles),1);
                for i=1:length(obj.imageHandles)
                    propList(i)=obj.imageHandles{i}.(prop);
                end
            %end         
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
                varargout{1}=h;
            end
        end
        function hlist = findImagesWithProp(obj,PropName,PropValue)
            hlist=[];
            for i=1:length(obj.imageHandles)
                if isprop(obj.imageHandles{i},PropName)
                    if obj.imageHandles{i}.(PropName)==PropValue
                        hlist(length(hlist)+1)=obj.imageHandles{i};
                    end
                end
            end
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