classdef CloudImageObject < AbsorptionImageObject
   properties(SetAccess = protected)
        nX%Integrated area of Gaussian fit in x projection
        nY%Integrated area of Gaussian fit in y projection
        xFit %Fit objected containing Gaussian fit in x projection
        yFit %Fit object containing Gaussian fit in y projection
   end
   properties(Dependent)
       xWidth %
       yWidth %
       xMetricWidth %
       yMetricWidth %
       xPeakHeight %
       yPeakHeight %
       xPeakLocation %
       yPeakLocation %
       avOD %
       peakOD %
       phaseSpaceDensity %
       averageDensity %
       peakDensity %
       aspectRatio %
   end
   methods
       
       %%Constructor
       function obj = CloudImageObject(varargin)
           %define inputs
           p = inputParser;
           p.CaseSensitive = false;
           addOptional(p,'file','');
           addOptional(p,'magnification',.25,@isnumeric);
           addOptional(p,'fitOffset','none',@ischar);
           addOptional(p,'resetROI',true,@islogical);
           addOptional(p,'imagingDetuning',0,@isnumeric);
           addOptional(p,'last',false,@islogical);
           
           %parse inputs
           parse(p,varargin{:});
           magnification = p.Results.magnification;
           file = p.Results.file;
           fitOffset=p.Results.fitOffset;
           resetROI=p.Results.resetROI;
           imagingDetuning=p.Results.imagingDetuning;
           last = p.Results.last;
           delete(p)
            
           %check for / get valid file name
           [filename,path]=AbsorptionImageObject.checkForFilename(file);
           
           %check if object already exists, return handle to it if it does
           [objAlreadyExists,objHandle]=CloudImageObject.checkForObject(filename);
           
           %call subclass constructor
           obj=obj@AbsorptionImageObject(...
               'file',[path filename],...
               'magnification',magnification,...
               'keepImageData',true,...
               'objAlreadyExists',objAlreadyExists,...
               'resetROI',resetROI,...
               'imagingDetuning',imagingDetuning);
           
           %return handle to old object or make new one
           if objAlreadyExists    
                obj = objHandle;
           else
                obj.xFit=CloudImageObject.fitOffsetGaussian(...
                    obj.xCoordinates,obj.xProjection,'offset',fitOffset);
                obj.yFit=CloudImageObject.fitOffsetGaussian(...
                    obj.yCoordinates,obj.yProjection,'offset',fitOffset);
                setNumberOfAtoms(obj);           
                p=findprop(obj,'imageData'); %get rid of temporary imageData field
                delete(p);
           end
           
       end
       
       %%set methods. error checking goes here
       function set.xFit(obj,val)
           obj.xFit=val;
       end
       function set.yFit(obj,val)
           obj.yFit=val;
       end
       
       %%get methods for dependent properties
       function avOD = get.avOD(obj) 
       
           avODRangeX=max(round(obj.xFit.b-obj.xFit.c),1):...
               min(round(obj.xFit.b+obj.xFit.c),obj.xCoordinates(end));
           avODRangeY=max(round(obj.yFit.b-obj.yFit.c),1):...
               min(round(obj.yFit.b+obj.yFit.c),obj.yCoordinates(end));           
           avOD=sum(sum(obj.opticalDensity(avODRangeY,avODRangeX)))...
               /(length(avODRangeX)*length(avODRangeY));           
       end
       function peakOD = get.peakOD(obj)
           avODRangeX=max(round(obj.xFit.b-obj.xFit.c),1):...
               min(round(obj.xFit.b+obj.xFit.c),obj.xCoordinates(end));
           avODRangeY=max(round(obj.yFit.b-obj.yFit.c),1):...
               min(round(obj.yFit.b+obj.yFit.c),obj.yCoordinates(end));           
           peakOD=max(max(obj.opticalDensity(avODRangeY,avODRangeX)));
       end
       function phaseSpaceDensity = get.phaseSpaceDensity(obj)
           phaseSpaceDensity = obj.peakOD/(obj.xMetricWidth*obj.yMetricWidth)^(3/2);
       end
       function averageDensity = get.averageDensity(obj)
           averageDensity = obj.nC / (obj.xMetricWidth^2 * obj.yMetricWidth) * 10^-6 / 4 / pi * 3*0.397496;
       end
       function peakDensity = get.peakDensity(obj)
           avODRangeX=max(round(obj.xFit.b-obj.xFit.c),1):...
               min(round(obj.xFit.b+obj.xFit.c),obj.xCoordinates(end));
           avODRangeY=max(round(obj.yFit.b-obj.yFit.c),1):...
               min(round(obj.yFit.b+obj.yFit.c),obj.yCoordinates(end));
           nToAverage = max([round(length(avODRangeX)*length(avODRangeY)*.001) 5]);
           orderedDensities = sort(reshape(obj.opticalDensity(avODRangeY,avODRangeX),[],1),'descend');
           peakDensity = 1/obj.generalizedXS*...
               mean(orderedDensities(1:nToAverage))/(obj.xMetricWidth)/10^6;
       end
       function xWidth = get.xWidth(obj)
           xWidth = min(obj.xFit.c,280);
       end
       function yWidth = get.yWidth(obj)
           yWidth = min(obj.yFit.c,280);
       end
       function xMetricWidth = get.xMetricWidth(obj)
           xMetricWidth=obj.xWidth*obj.PIXEL_SIZE/obj.magnification;
       end
       function yMetricWidth = get.yMetricWidth(obj)
           yMetricWidth=obj.yWidth*obj.PIXEL_SIZE/obj.magnification;
       end
       function xPeakHeight= get.xPeakHeight(obj)
           xPeakHeight = obj.xFit.a;
       end
       function yPeakHeight= get.yPeakHeight(obj)
           yPeakHeight = obj.yFit.a;
       end
       function xPeakLocation= get.xPeakLocation(obj)
           xPeakLocation = obj.xFit.b;
       end
       function yPeakLocation= get.yPeakLocation(obj)
           yPeakLocation = obj.yFit.b;
       end
       function aspectRatio = get.aspectRatio(obj)
           aspectRatio = obj.xWidth/obj.yWidth;
       end

       %%UI routines/methods
       function h = uishow(obj,varargin)
           opticalDensity=obj.opticalDensity(obj.yCoordinates,obj.xCoordinates);
           opticalDensity(opticalDensity<0)=0;
           if nargin>1
               hh=figure(varargin{1});
               layout = uiextras.VBox('Parent',varargin{2},'Padding',0,'Spacing',0);               
           else
               hh=figure('MenuBar', 'none', ...
                'Toolbar', 'none', ...
                'NumberTitle', 'off');
               layout = uiextras.VBox('Parent',hh);
           end
           top = uiextras.HBox('Parent',layout,'Padding',25,'Spacing',50);
           bottom = uiextras.HBox('Parent',layout,'Padding',25,'Spacing',50);
           layout.Sizes=[-1 -3];
           
           axes('Parent',bottom,'ActivePositionProperty', 'Position')
           imagesc(opticalDensity);
           blu=transpose([1:-1/255:0;1:-1/255:0;ones(1,256)]);
           colormap(blu)
           set(gca,'XTick',1:(length(opticalDensity(1,:))-1)/2:(length(opticalDensity(1,:)-1)))
           set(gca,'XTickLabel',{'-s/2','0','s/2'})
           set(gca,'YTick',1:(length(opticalDensity(:,1))-1)/2:(length(opticalDensity(:,1)-1)))
           set(gca,'YTickLabel',{'-s','0','s/2'})
           axis tight
           
           axes('Parent',top,'ActivePositionProperty', 'Position')
           plot(obj.xFit,'--r',obj.xCoordinates,obj.xProjection,'b');
%             imagesc(rand(100,100))
           axis tight
           xlabel(''),ylabel(''),legend('off')
           
           axes('Parent',top,'ActivePositionProperty', 'Position')
           axis off
           text(.5,.5,['nC=' num2str(obj.nC,'%10.3e\n')],...
            'FontSize',10,'HorizontalAlignment','center')
           
           axes('Parent',bottom,'ActivePositionProperty', 'Position')
           plot(obj.yFit,'--r',obj.yCoordinates,obj.yProjection,'b');
%             imagesc(rand(100,100))
           xlabel(''),ylabel(''),legend('off')
           view(90,90);
           axis tight
           
           bottom.Sizes = [-3 -1];
           top.Sizes = [-3 -1];
           
           if nargout
                h=hh;
           end
       end
       function h = show(obj,varargin)
           opticalDensity=obj.opticalDensity(obj.yCoordinates,obj.xCoordinates);
           opticalDensity(opticalDensity<0)=0;
           if nargin>1
               hh=figure(varargin{1});
               subplot(3,3,[4 5 7 8],'Parent',varargin{2});
           else
               hh=figure;
               subplot(3,3,[4 5 7 8]);
           end
           
           imagesc(opticalDensity);
           blu=transpose([1:-1/255:0;1:-1/255:0;ones(1,256)]);
           colormap(blu)
           set(gca,'XTick',1:(length(opticalDensity(1,:))-1)/2:(length(opticalDensity(1,:)-1)))
           set(gca,'XTickLabel',{'-s/2','0','s/2'})
           set(gca,'YTick',1:(length(opticalDensity(:,1))-1)/2:(length(opticalDensity(:,1)-1)))
           set(gca,'YTickLabel',{'-s','0','s/2'})
           
           subplot(3,3,[1 2])
           plot(obj.xFit,'--r',obj.xCoordinates,obj.xProjection,'b');
           axis tight
           xlabel(''),ylabel(''),legend('off')
           
           subplot(3,3,[6 9]);
           plot(obj.yFit,'--r',obj.yCoordinates,obj.yProjection,'b');
           xlabel(''),ylabel(''),legend('off')
           view(90,90);
           axis tight
           
           subplot(3,3,3)
           axis off           
           text(.5,.5,['nC=' num2str(obj.nC,'%10.3e\n')],...
            'FontSize',10,'HorizontalAlignment','center')           
           if nargout
                h=hh;
           end
       end
       function h = showFits(obj)
           hh = figure;
           hold on
           plot(obj.xCoordinates,obj.xProjection,'b');
           plot(obj.yCoordinates,obj.yProjection,'g');
           plot(obj.xFit,'--r');
           plot(obj.yFit,'--r');
           legend('X projection', 'Y projection');
           xlabel('pixel')
           ylabel('projected OD')
           hold off
           if nargout
                h=hh;
           end
       end
   end
   methods (Access = protected)
       
       %%object initialization routines
       function setNumberOfAtoms(obj)
           nX=abs(sqrt(2*pi)*obj.xFit.a*obj.xFit.c*...
               (obj.PIXEL_SIZE/obj.magnification)^2/obj.generalizedXS);
           nY=abs(sqrt(2*pi)*obj.yFit.a*obj.yFit.c*...
               (obj.PIXEL_SIZE/obj.magnification)^2/obj.generalizedXS);
           obj.nX=nX;
           obj.nY=nY;
       end
       
       %%calculation methods. any science goes here.

   end
   methods (Static)
       
       %%class utility methods
       fitObj = fitOffsetGaussian( x, y, varargin)
       objList = findall(varargin)
       [tf,obj] = checkForObject(filename)
   end
end

%%Depreciated functions
%        function setPhotonsPerAtom(obj)
%            ppaRangeX=max(round(obj.xFit.b-obj.xFit.c),1):...
%                min(round(obj.xFit.b+obj.xFit.c),obj.xCoordinates(end));
%            ppaRangeY=max(round(obj.yFit.b-obj.yFit.c),1):...
%                min(round(obj.yFit.b+obj.yFit.c),obj.yCoordinates(end));
%            adjustedOpticalDensity=obj.opticalDensity;
%            adjustedOpticalDensity(adjustedOpticalDensity==0)=1;
%            obj.photonsPerAtom=abs(obj.light(ppaRangeY,ppaRangeX)./...
%                adjustedOpticalDensity(ppaRangeY,ppaRangeX)...
%                *obj.CAMERA_GAIN*obj.generalizedXS/...
%                (obj.PIXEL_SIZE/obj.magnification)^2);
%            meanppa=mean(mean(obj.photonsPerAtom));
%            stdppa=std(std(obj.photonsPerAtom));
%            cutoffppa=(meanppa+2*stdppa);
%            obj.photonsPerAtom(obj.photonsPerAtom>cutoffppa)=0;
%        end