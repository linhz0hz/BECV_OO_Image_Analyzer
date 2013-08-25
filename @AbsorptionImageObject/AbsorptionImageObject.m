classdef AbsorptionImageObject < ImageObject
%ABSORPTIONIMAGEOBJECT is an image class that implements ImageObject.
%Contains data selection routines, 

   properties (SetAccess = immutable)
       filename %string containing filename
       path %string containing the path
   end       
   properties(SetAccess = protected) 
        roiMask %imrect or imellipse object
        opticalDensity %array containing optical densities at each pixel
%         thumbnail %.1 scale image stored in RAM
        variables = {}; %cell array contaning names of variables imported from Cicero
        imagingDetuning %detuning from resonance in imaging light (MHz)
        generalizedXS %resonant xs corrected for imaging detuning
        magnification %magnification in the optical train   
        nC %discrete summation of optical density
        xProjection %
        yProjection %
   end
   properties (Dependent, SetAccess = protected)
        xCoordinates %x coordinates of the region of interest
        yCoordinates %y coordinates of the region of interest
        atoms %atom image; 1392*1040 pixels (greyscale 1-4095)
        light %light image; 1392*1040 pixels (greyscale 1-4095)
        darkField %dark field image; 1392*1040 pixels (greyscale 1-4095)
        normalizedImage %(atoms-dark field)/(light-dark field) image;
   end
   properties(Hidden, Access = protected)
       lastroiPos
   end
   methods
       
       %Constructor
       function obj = AbsorptionImageObject(varargin) %constructor for AbsorptionImageObjects
           
           %Define expected inputs
           p = inputParser;
           p.CaseSensitive = false;
           addOptional(p,'file','');
           addOptional(p,'magnification',.25,@isnumeric);
           addOptional(p,'resetroi',true,@islogical);
           addOptional(p,'objAlreadyExists',false,@islogical);
           addOptional(p,'keepImageData',false,@islogical);
           addOptional(p,'imagingDetuning',0,@isnumeric);
           
           %Parse inputs
           parse(p,varargin{:});
           magnification=p.Results.magnification;
           file = p.Results.file;
           resetroi=p.Results.resetroi;
           objAlreadyExists=p.Results.objAlreadyExists;
           keepImageData = p.Results.keepImageData;
           imagingDetuning = p.Results.imagingDetuning;                     
           delete(p)
           
           %check for flag from subclass constructor
           if ~objAlreadyExists
               [filename,path]=AbsorptionImageObject.checkForFilename(file);
               %avoid reprocessing data if it exists in memory
               if ~AbsorptionImageObject.objExists(filename)
                    obj.filename = filename;
                    obj.path = path;
                    obj.imagingDetuning=imagingDetuning;
                    obj.magnification=magnification;                                 
                    loadFromFile(obj,[obj.path obj.filename],keepImageData,resetroi);
               else
                   %obj already exists, do nothing
               end
           else
               %obj already exists, do nothing
           end
               
       end
              
       %%Set methods. Error checking goes here
       function set.roiMask(obj, val) %dispalys the image and a drawable rectangle to select region of interest 
           obj.roiMask=val;
       end 
       function set.opticalDensity(obj,val) %sets the optical density based on raw image data
           obj.opticalDensity=val;
       end
       function set.nC(obj,val)
           if val>=0
                obj.nC = val;
           else
               error('nC is negative!')
           end
       end
       
       %%Get methods for dependent properties
       function atoms = get.atoms(obj) %
           if isprop(obj,'imageData')
               atoms=obj.imageData{1}{2};
           else
               imageData = ImageObject.readAIA([obj.path obj.filename]);
               atoms=imageData{1}{2};
           end
       end       
       function light = get.light(obj) %
           if isprop(obj,'imageData')
               light=obj.imageData{2}{2};
           else
               imageData = ImageObject.readAIA([obj.path obj.filename]);
               light=imageData{2}{2};
           end
       end
       function darkField = get.darkField(obj) %
           if isprop(obj,'imageData')
               darkField=obj.imageData{3}{2};
           else
               imageData = ImageObject.readAIA([obj.path obj.filename]);
               darkField=imageData{3}{2};
           end
       end
       function normalizedImage = get.normalizedImage(obj) %
           normalizedImage = obj.calculateNormalizedImage();
       end
       function xCoordinates = get.xCoordinates(obj) %
           xCoordinates=1:size(obj.opticalDensity,2);
       end
       function yCoordinates = get.yCoordinates(obj) %
           yCoordinates=1:size(obj.opticalDensity,1);
       end
       
       %%UI routines/methods
       function h = show(obj, varargin) %displays whole normalized image
           h = imagesc(obj.normalizedImage);
       end
       function adjustroi(obj) %allows the user to pick a new region of interest
           obj.initializeroi();
           obj.initializeValues();
       end
       function [roiPos,roiMask] = roiPrompt(obj)
           global roi_global
           global roiMask_global
           
           f = figure('name','Select Analysis Range and Press Any Key','NumberTitle','off',...
                        'WindowStyle','modal');
           im = imshow(obj.normalizedImage,'Border','tight','InitialMagnification',55);
                      
           if isempty(obj.lastroiPos)
               if isempty(roi_global)
                   roi = imellipse(gca);
               else
                   roi = imellipse(gca,roi_global);
               end
           else
               roi = imellipse(gca,obj.lastroiPos);
           end
   
           fcn = makeConstrainToRectFcn('imellipse',get(gca,'XLim'),get(gca,'YLim'));
           setPositionConstraintFcn(roi,fcn);          
           pause                      
           roiMask = roi.createMask();
           roiPos = roi.getPosition();
           roi_global = roi.getPosition();
           roiMask_global = roi.createMask();
           close(gcf)
       end
   end
   
   methods (Access = protected)
       
       %%Object initialization routines
       function loadFromFile(obj,filename,keepImageData,resetROI) %routine which initializes the properties of the object
           p = addprop(obj,'imageData');    %adds a temporary field that conatins raw image data
           obj.imageData = ImageObject.readAIA(filename);   %get image data from file           
           if length(obj.imageData)>3           %add properties based on cicero list variables
               for i=4:length(obj.imageData)
                   propMeta = addprop(obj,obj.imageData{i}{1});
                   obj.variables {length(obj.variables)+1} = obj.imageData{i}{1};
                   obj.(obj.imageData{i}{1})=obj.imageData{i}{2};                
               end
           end
           normalizedImage = obj.normalizedImage;   %get and temporarily store the normalized image
%            obj.thumbnail=imresize(normalizedImage,.1); %create and store a thumbnail

           obj.initializeroi(resetROI)
           obj.initializeValues();
           if ~keepImageData
                delete(p); %get rid of the temporary imageData field
           end
       end
       function initializeroi(obj,varargin)
           global roi_global
           global roiMask_global
           
           if nargin==1
               [obj.lastroiPos,obj.roiMask] = obj.roiPrompt();
           elseif varargin{1}
               [obj.lastroiPos,obj.roiMask] = obj.roiPrompt();
           else
               if ~isempty(obj.roiMask)
                   %doNothing
               elseif ~isempty(roiMask_global)
                   obj.roiMask = roiMask_global;
               else
                   [obj.lastroiPos,obj.roiMask] = obj.roiPrompt();
               end
           end           
       end
       function initializeValues(obj)
           obj.generalizedXS=obj.calculategeneralizedXS();
           obj.opticalDensity = obj.calculateopticalDensity();
           obj.xProjection = obj.calculatexProjection();
           obj.yProjection = obj.calculateyProjection();
           obj.nC = obj.calculatenC();           
       end
       
       %%Calculation methods. Any science goes here.
       function nC = calculatenC(obj)
           opticalDensity = obj.opticalDensity;
           nC = (obj.PIXEL_SIZE/obj.magnification)^2/obj.generalizedXS*...
                sum(sum(opticalDensity.*obj.roiMask));
       end
       function normalizedImage = calculateNormalizedImage(obj)
           atoms=obj.atoms;
           darkField=obj.darkField;
           light=obj.light;
           atoms=atoms-darkField;
           light=light-darkField;
           scaling=mean(mean(atoms(900:1000,600:800)))/mean(mean(light(900:1000,600:800)));
           %%scaling=1;
           light(light==0)=Inf;
           normalizedImage = atoms./(scaling*light);
           normalizedImage(normalizedImage<=0)=1;
       end
       function xProjection = calculatexProjection(obj)
           xProjection = sum(obj.opticalDensity.*obj.roiMask,1);
       end
       function yProjection = calculateyProjection(obj)
           yProjection = sum(obj.opticalDensity.*obj.roiMask,2)';
       end
       function generalizedXS = calculategeneralizedXS(obj)
           generalizedXS = obj.RESONANT_XS/(1+(2*obj.imagingDetuning*10^6/obj.LINE_WIDTH)^2);
       end
       function opticalDensity = calculateopticalDensity(obj)
           opticalDensity = -log(obj.normalizedImage);%calculate and store optical density
       end
   end
   methods (Static=true)
       
       %%Class utility methods
       objList = findall()
       tf = objExists(filename)
       [filename, path] = checkForFilename(file)
   end
end