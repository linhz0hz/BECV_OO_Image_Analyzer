classdef CloudImageObject < AbsorptionImageObject
   properties(SetAccess = protected)
        nC%Discrete summation of optical density
        nX%Integrated area of Gaussian fit in x projection
        nY%Integrated area of Gaussian fit in y projection
        photonsPerAtom %Number of photon counts registered by the CCD per atom per pixel
        xFit %Fit objected containing Gaussian fit in x projection
        yFit %Fit object containing Gaussian fit in y projection
   end
   properties(Dependent)
       xProjection %
       yProjection %
       xWidth %
       yWidth %
       xMetricWidth %
       yMetricWidth %
       xPeakHeight %
       yPeakHeight %
       xPeakLocation %
       yPeakLocation %
       avPhotonsPerAtom %
       avOD %
       peakOD %
       phaseSpaceDensity %
       averageDensity %
       peakDensity %
       aspectRatio %
   end
   methods
       function obj = CloudImageObject(varargin)
           
           p = inputParser;
           p.CaseSensitive = false;
           addOptional(p,'file','');
           addOptional(p,'magnification',.25,@isnumeric);
           addOptional(p,'fitOffset','none',@ischar);
           addOptional(p,'resetROI',true,@islogical);
           addOptional(p,'imagingDetuning',0,@isnumeric);
           addOptional(p,'last',false,@islogical);
           
           parse(p,varargin{:});
           magnification = p.Results.magnification;
           file = p.Results.file;
           fitOffset=p.Results.fitOffset;
           resetROI=p.Results.resetROI;
           imagingDetuning=p.Results.imagingDetuning;
           last = p.Results.last;
           delete(p)

           if strcmp(file,'')
                [filename, path]=AbsorptionImageObject.selectFile('D:\Data\Current');
           else
                [path, filename, ext] = fileparts(file);
                if strcmpi(ext,'.aia')
                    if strcmp(path,'')
                         path=[pwd '\'];
                    else
                         path=[path '\'];
                    end
                    filename=[filename ext];                    
                else
                    %file not aia
                    error('file not .aia')
                end
           end
           currentObjects = CloudImageObject.findall();
           objIndex=0;
           objAlreadyExists = false;
           while ~objAlreadyExists && objIndex<length(currentObjects)
               objIndex=objIndex+1;
               if currentObjects{objIndex}.filename == filename
                   objAlreadyExists = true;
               end
               
           end
           
           obj=obj@AbsorptionImageObject(...
               'file',[path filename],...
               'magnification',magnification,...
               'keepImageData',true,...
               'objAlreadyExists',objAlreadyExists,...
               'resetROI',resetROI,...
               'imagingDetuning',imagingDetuning);
           
           if objAlreadyExists    
                obj=currentObjects{objIndex};
           else
                obj.xFit=CloudImageObject.fitOffsetGaussian(...
                    obj.regionOfInterest.x,obj.xProjection,'offset',fitOffset);
                obj.yFit=CloudImageObject.fitOffsetGaussian(...
                    obj.regionOfInterest.y,obj.yProjection,'offset',fitOffset);
                setNumberOfAtoms(obj);
                setPhotonsPerAtom(obj);           
                p=findprop(obj,'imageData'); %get rid of temporary imageData field
                delete(p);
           end
           
       end
       function avPhotonsPerAtom = get.avPhotonsPerAtom(obj)
           avPhotonsPerAtom=mean(mean(obj.photonsPerAtom));
       end
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
           peakDensity = 1/obj.SCATTERING_XS*...
               mean(orderedDensities(1:nToAverage))/(obj.xMetricWidth)/10^6;
       end
       function xProjection = get.xProjection(obj)
           xProjection = sum(obj.opticalDensity(obj.regionOfInterest.y,obj.regionOfInterest.x),1);
       end
       function yProjection = get.yProjection(obj)
           yProjection = sum(obj.opticalDensity(obj.regionOfInterest.y,obj.regionOfInterest.x),2)';
       end
       function xWidth = get.xWidth(obj)
           xWidth = min(obj.xFit.c,280);
       end
       function yWidth = get.yWidth(obj)
           yWidth = min(obj.yFit.c,280);
       end
       function xMetricWidth = get.xMetricWidth(obj)
           xMetricWidth=obj.xWidth*obj.PIXEL_SIZE/obj.MAGNIFICATION;
       end
       function yMetricWidth = get.yMetricWidth(obj)
           yMetricWidth=obj.yWidth*obj.PIXEL_SIZE/obj.MAGNIFICATION;
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
       function set.xFit(obj,val)
           obj.xFit=val;
       end
       function set.yFit(obj,val)
           obj.yFit=val;
       end
       function h = show(obj,varargin)
           opticalDensity=obj.opticalDensity(obj.regionOfInterest.y,obj.regionOfInterest.x);
           opticalDensity(opticalDensity<0)=0;
           if nargin>1
               hh=figure(varargin{1});
           else
               hh=figure;
           end
           subplot(3,3,[4 5 7 8]);
           imagesc(opticalDensity);
           blu=transpose([1:-1/255:0;1:-1/255:0;ones(1,256)]);
           colormap(blu)
           set(gca,'XTick',1:(length(opticalDensity(1,:))-1)/2:(length(opticalDensity(1,:)-1)))
           set(gca,'XTickLabel',{'-s/2','0','s/2'})
           set(gca,'YTick',1:(length(opticalDensity(:,1))-1)/2:(length(opticalDensity(:,1)-1)))
           set(gca,'YTickLabel',{'-s','0','s/2'})
           
           subplot(3,3,[1 2])
           plot(obj.xFit,'--r',obj.regionOfInterest.x,obj.xProjection,'b');
           axis tight
           xlabel(''),ylabel(''),legend('off')
           
           subplot(3,3,[6 9]);
           plot(obj.yFit,'--r',obj.regionOfInterest.y,obj.yProjection,'b');
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
       function h = showPhotonsPerAtom(obj)
           figure, hh = imagesc(obj.photonsPerAtom);
           title('Photons Per Atom')
           xlabel('x (pixels)')
           ylabel('y (pixels)')
           colorbar;
           if nargout
                h=hh;
           end
       end
       function h = showFits(obj)
           hh = figure;
           hold on
           plot(obj.regionOfInterest.x,obj.xProjection,'b');
           plot(obj.regionOfInterest.y,obj.yProjection,'g');
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
   methods (Access = protected, Hidden = true)
       function setNumberOfAtoms(obj)
           nX=abs(sqrt(2*pi)*obj.xFit.a*obj.xFit.c*...
               (obj.PIXEL_SIZE/obj.MAGNIFICATION)^2/obj.SCATTERING_XS);
           nY=abs(sqrt(2*pi)*obj.yFit.a*obj.yFit.c*...
               (obj.PIXEL_SIZE/obj.MAGNIFICATION)^2/obj.SCATTERING_XS);
           nC=(obj.PIXEL_SIZE/obj.MAGNIFICATION)^2/obj.SCATTERING_XS*...
                sum(sum(obj.opticalDensity(obj.regionOfInterest.y,obj.regionOfInterest.x)));
           obj.nC=nC;
           obj.nX=nX;
           obj.nY=nY;
       end
       function setPhotonsPerAtom(obj)
           ppaRangeX=max(round(obj.xFit.b-obj.xFit.c),1):...
               min(round(obj.xFit.b+obj.xFit.c),obj.xCoordinates(end));
           ppaRangeY=max(round(obj.yFit.b-obj.yFit.c),1):...
               min(round(obj.yFit.b+obj.yFit.c),obj.yCoordinates(end));
           adjustedOpticalDensity=obj.opticalDensity;
           adjustedOpticalDensity(adjustedOpticalDensity==0)=1;
           obj.photonsPerAtom=abs(obj.light(ppaRangeY,ppaRangeX)./...
               adjustedOpticalDensity(ppaRangeY,ppaRangeX)...
               *obj.CAMERA_GAIN*obj.SCATTERING_XS/...
               (obj.PIXEL_SIZE/obj.MAGNIFICATION)^2);
           meanppa=mean(mean(obj.photonsPerAtom));
           stdppa=std(std(obj.photonsPerAtom));
           cutoffppa=(meanppa+2*stdppa);
           obj.photonsPerAtom(obj.photonsPerAtom>cutoffppa)=0;
       end
   end
   methods (Static)
       fitObj = fitOffsetGaussian( x, y, varargin)
       objList = findall(varargin)
   end
end