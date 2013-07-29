classdef ImageSeriesObject1 < dynamicprops
    properties (SetAccess = protected)
        imageHandles
        imageVariables
        imageFilenamesList
    end
    properties (SetAccess = immutable)
        IMAGECLASS
    end
    methods
        function obj = ImageSeriesObject1(varargin)
           p = inputParser;
           p.CaseSensitive = false;
           defaultImageClass = 'CloudImageObject';
           expectedImageClass = {'AbsorptionImageObject','CloudImageObject'};
           addOptional(p,'imageclass',defaultImageClass,@(x) any(validatestring(x,expectedImageClass)));
           addOptional(p,'files','');
           addOptional(p,'magnification',.25,@isnumeric);
           parse(p,varargin{:});
           obj.IMAGECLASS = p.Results.imageclass;
           magnification = p.Results.magnification;
           files = p.Results.files;
           delete(p);

           if isempty(files)
               [filenames, path] = ImageSeriesObject1.selectFiles('D:\Data\Current');
           else
               filenames = files;
               path = pwd;
           end
            imageFilenamesStart=filenames(1);
            imageFilenamesEnd=filenames(length(filenames));
            imageFilenamesList=[imageFilenamesStart imageFilenamesEnd];
           
           for i = 1:length(filenames)
               if i == 1
                   tempObj = CloudImageObject('magnification',magnification,'file',[path filenames{i}]);
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
        end
        function addImages(obj, varargin)
            if nargin
               filenames=varargin{1};
               path=pwd;
            else
               [filenames, path] = ImageSeriesObject1.selectFiles();
           end
           
           iStart=length(obj.imageHandles);
           for i=1:length(filenames)
               tempObj=CloudImageObject('file',[path filenames{i}]);
               if ~ tempObj.variables == obj.imageVariables
                   error('Variable mismatch between members of image series!')
               end
               obj.imageHandles{iStart+i}=tempObj;
               assignin('base',genvarname(filenames{i}),obj.imageHandles{iStart+i}); 
           end
        end
        function removeImage(obj, varargin)
            if ~nargin
                error('No Input')
            elseif isnumeric(varargin)
                %%stuff
            else
                error('Input not image index')
            end
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
                images{i}=imresize(imlist{i}.normalizedImage,.2);
            end
            h = figure('name',figureTitle);
            text(.25,1.25,figureTitle)
            hold on
            a=gca;
            columns=5;
            rows=mod(numberOfImages,columns);
            for i=1:numberOfImages
                subplot(rows,columns,i)
                imshow(images{i},'Border','tight')
                title(proplist(i))
            end
            varargout{1}=h;
            hold off
        end
        function movie = showMovie(obj,prop)
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
        function varargout = plot(obj,xProp,yProp)
            varargout={};
            if isprop(obj,xProp) && isprop(obj,yProp)
                for i=1:length(obj.imageHandles)
                    xPropList(i)=obj.imageHandles{i}.(xProp);
                    yPropList(i)=obj.imageHandles{i}.(yProp);
                end
                h = plot(xPropList,yPropList,'b*');
                ylabel(yProp)
                xlabel(xProp)
                title([yProp ' vs ' xProp])
                varargout{1}=h;
            else
                error([xProp ' and ' yProp ' are not properties of all objects in the series.'])
            end
        end
        function varargout = ploterr(obj,xProp,yProp)
            varargout={};
            if isprop(obj,xProp) && isprop(obj,yProp)
                for i=1:length(obj.imageHandles)
                    xPropList(i)=obj.imageHandles{i}.(xProp);
                    yPropList(i)=obj.imageHandles{i}.(yProp);
                end
                xBinned=unique(xPropList);
                for i=1:length(xBinned)
                    yBinned(i) = mean(yPropList(xPropList == xBinned(i)));
                    yBinnedSTD(i) = std(yPropList(xPropList == xBinned(i)))/sqrt(length(yBinned(i)));
                end
                h = errorbar(xBinned,yBinned,yBinnedSTD,'b*');
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