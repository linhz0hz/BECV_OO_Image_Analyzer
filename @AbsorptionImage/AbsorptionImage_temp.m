classdef AbsorptionImage < becvImage
%AbsorptionImage is an image class that implements ImageObject.
%   Contains data selection routines, etc.
%   Jesse Amato-Grill, MIT 10/13/2014

   properties (SetAccess = immutable)
   end       
   properties(SetAccess = protected)
        cameraID %cameraID
        roi %roi object
        variables %cell array contaning names of variables imported from Cicero
        imagingDetuning %detuning from resonance in imaging light (MHz)
        generalizedXS %resonant xs corrected for imaging detuning
        magnification %magnification in the optical train   
        nC %discrete summation of optical density
        xProjection %projection of image onto xCoordinates
        yProjection %projection of image onto yCoordinates
        fringeCanceling % nth order background correction
        scaling %first order background correction
   end
   properties (Dependent, SetAccess = protected)
        xCoordinates %x coordinates of the region of interest
        yCoordinates %y coordinates of the region of interest
        atoms %atom image; 1392*1040 pixels (grayscale 1-4095)
        light %light image; 1392*1040 pixels (grayscale 1-4095)
        darkField %dark field image; 1392*1040 pixels (grayscale 1-4095)
        normalizedImage %(atoms-dark field)/(light-dark field) image;
        opticalDensity %array containing optical densities at each pixel
        xCenterOfMass
        yCenterOfMass
        xRMSWidth
        yRMSWidth
   end
   properties (Hidden, SetAccess = protected)
       keepImageData
       imageData
   end
   methods
       
       %Constructor
       function obj = AbsorptionImage(varargin) %constructor for AbsorptionImages
           
           %Define expected inputs
           p = inputParser;
           p.CaseSensitive = false;
           addOptional(p,'file','');
           addOptional(p,'magnification',0.3,@isnumeric);
           addOptional(p,'roi',[]);
           addOptional(p,'objAlreadyExists',false,@islogical);
           addOptional(p,'keepImageData',false,@islogical);
           addOptional(p,'imagingDetuning',0,@isnumeric);
           
           addOptional(p,'usingDER',0);
           addOptional(p,'atomsIn',0);
           addOptional(p,'noAtomsIn',0);
           addOptional(p,'darkFieldIn',0);
           addOptional(p,'ciceroNames',0);
           addOptional(p,'ciceroValues',0);
           
           addOptional(p,'fringeCanceling',false,@islogical); % added by Niki
           
           %Parse inputs, including those from DER
           parse(p,varargin{:});
           magnification=p.Results.magnification;
           file = p.Results.file;
           roi=p.Results.roi;
           objAlreadyExists=p.Results.objAlreadyExists;
           keepImageData = p.Results.keepImageData;
           imagingDetuning = p.Results.imagingDetuning;
           
           usingDER = p.Results.usingDER;
           atomsIn = p.Results.atomsIn;
           noAtomsIn = p.Results.noAtomsIn;
           darkFieldIn = p.Results.darkFieldIn;
           ciceroNames = p.Results.ciceroNames;
           ciceroValues = p.Results.ciceroValues;
           
           fringeCanceling = p.Results.fringeCanceling; % added by Niki
           
           delete(p)
           
           %check for flag from subclass constructor
           if ~objAlreadyExists
               if usingDER == 0
                    [filename,path]=AbsorptionImage.checkForFilename(file);
               else
                    filename = '';
                    path = '';
               end
               %avoid reprocessing data if it exists in memory
               if ~AbsorptionImage.objExists(filename)
                    obj.filename = filename;
                    obj.path = path;
                    obj.imagingDetuning=imagingDetuning;
                    obj.magnification=magnification;
                    obj.atomsIn = atomsIn;
                    obj.noAtomsIn = noAtomsIn;
                    obj.darkFieldIn = darkFieldIn;
                    
                    obj.fringeCanceling = fringeCanceling; % added by Niki
                   
                    loadFromFile(obj,[obj.path obj.filename],keepImageData,roi);
               else
                   %obj already exists, do nothing
               end
           else
               %obj already exists, do nothing
           end
               
       end
              
       %%Set methods. Error checking goes here
       function set.roi(obj, val) %dispalys the image and a drawable rectangle to select region of interest 
           obj.roi=val;
       end 
       function set.opticalDensity(obj,val) %sets the optical density based on raw image data
           obj.opticalDensity=val;
       end
       function set.nC(obj,val)
           if val>=0
                obj.nC = val;
           else
               obj.nC = 0;
%                error('nC is negative!')
           end
       end
       function set.scaling(obj,val)
          
                obj.scaling = val;
           
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
       function xCenterOfMass = get.xCenterOfMass(obj)
           xCenterOfMass = obj.calculatexCenterOfMass();
       end
       function yCenterOfMass = get.yCenterOfMass(obj)
           yCenterOfMass = obj.calculateyCenterOfMass();
       end
       function xRMSWidth = get.xRMSWidth(obj)
           xRMSWidth = obj.calculatexRMSWidth();
       end
       function yRMSWidth = get.yRMSWidth(obj)
           yRMSWidth = obj.calculateyRMSWidth();
       end
       
       %%UI routines/methods
       function h = show(obj, varargin) %displays whole normalized image
           h = imagesc(obj.normalizedImage);
       end
       function adjustroi(obj,varargin) %allows the user to pick a new region of interest
           if nargin>1
               obj.roi.update('parentAxes',varargin{1},'initialPosition',obj.roi.pos)
           else
               obj.roi.update('image',obj.opticalDensity,'initialPosition',obj.roi.pos)
           end
           obj.initializeAbsorptionValues();
       end
   end
   
   methods (Access = protected)
       
       %%Object initialization routines
       function loadFromFile(obj,filename,keepImageData,roi) %routine which initializes the properties of the object
           p = addprop(obj,'imageData');    %adds a temporary field that contains raw image data
           if obj.usingDER == 0
                obj.imageData = ImageObject.readAIA(filename);%get image data from file
           else
                obj.imageData = ImageObject.readArrays(obj.atomsIn,obj.noAtomsIn,obj.darkFieldIn,obj.ciceroNames,obj.ciceroValues);%get image data from arrays
           end
           if length(obj.imageData)>3           %add properties based on cicero list variables
               for i=4:length(obj.imageData)
                   propMeta = addprop(obj,obj.imageData{i}{1});
                   obj.variables {length(obj.variables)+1} = obj.imageData{i}{1};
                   obj.(obj.imageData{i}{1})=obj.imageData{i}{2};                
               end
           end
%            normalizedImage = obj.normalizedImage;   %get and temporarily store the normalized image
%            obj.thumbnail=imresize(normalizedImage,.1); %create and store a thumbnail
           obj.initializeroi(roi);
           
           atoms=obj.atoms; % added by Niki
           darkField=obj.darkField; % added by Niki
           light=obj.light; % added by Niki
           atoms=atoms-darkField; % added by Niki
           light=light-darkField; % added by Niki
                      
           if obj.fringeCanceling % added by Niki
               PCA = load('Z:\PCAbasis.mat');
               W = PCA.W;
               mu = PCA.mu;
               light(:) = mu;
               [~,N] = size(W);
               for i=1:N
                   light(:) = light(:) + sum((atoms(:)-mu').*W(:,i)) * W(:,i); % expand atoms-shot in PCA basis to construct light-shot
               end
               tempMask = mod(obj.roi.mask+1,2);
               light = sum(atoms(:).*tempMask(:)) / sum(light(:).*tempMask(:)) * light;
           end
           light = light + darkField; % added by Niki
           obj.imageData{2}{2} = light; % added by Niki
           
           
           if ~obj.fringeCanceling % added by Niki
               obj.scaleImage(); % Jesse
           end % added by Niki
           
%              if ~obj.imagingDetuning && isprop(obj,'F2IMGMHz')
%                 obj.imagingDetuning = obj.F2IMGMHz;
%              end
           obj.initializeAbsorptionValues();
           if ~keepImageData
                delete(p); %get rid of the temporary imageData field
           end
       end
       function loadFromDatabase(obj, runID)
       end
       function initializeroi(obj,usethisroi)
           if isempty(usethisroi)
               obj.roi = roi('image',obj.normalizedImage);
           else
               obj.roi = usethisroi; 
           end
       end
       function scaleImage(obj)
           tempMask = mod(obj.roi.mask+1,2);
           obj.scaling=mean(mean(obj.atoms(tempMask==1)))/mean(mean(obj.light(tempMask==1)));       
%             obj.scaling=mean(mean(obj.atoms(90:100,310:350)))/mean(mean(obj.light(90:100,310:350)));
       %     obj.scaling=1;
       end
       function initializeAbsorptionValues(obj)
           %obj.magnification = obj.calculateMagnification();
           obj.generalizedXS=obj.calculategeneralizedXS();
           obj.opticalDensity = obj.calculateopticalDensity();
           obj.xProjection = obj.calculatexProjection();
           obj.yProjection = obj.calculateyProjection();
           obj.nC = obj.calculatenC();           
       end
       
       
       %%Calculation methods. Any science goes here.
       function nC = calculatenC(obj)
           nC = (obj.PIXEL_SIZE/obj.magnification)^2/obj.generalizedXS*...
                sum(sum(obj.opticalDensity.*obj.roi.mask));
       end
       function normalizedImage = calculateNormalizedImage(obj)
           
           %definitions
           atoms=obj.atoms;
           darkField=obj.darkField;
           light=obj.light;
           atoms=atoms-darkField;
           light=light-darkField;
           
           %cleanup
           light(light==0)=Inf;
           
           normalizedImage = atoms./(obj.scaling*light);
           normalizedImage(normalizedImage<=0)=1;
       end
       function xProjection = calculatexProjection(obj)
           xProjection = sum(obj.opticalDensity.*obj.roi.mask,1);
       end
       function yProjection = calculateyProjection(obj)
           yProjection = sum(obj.opticalDensity.*obj.roi.mask,2)';
       end
       function generalizedXS = calculategeneralizedXS(obj)
            generalizedXS = obj.RESONANT_XS*(1/(1+(2*obj.imagingDetuning/6.182)^2)); 
       end
       function opticalDensity = calculateopticalDensity(obj)
           opticalDensity = -log(obj.normalizedImage);%calculate and store optical density
       end
       function xCenterOfMass = calculatexCenterOfMass(obj)
            xCenterOfMass = sum(obj.xProjection.*obj.xCoordinates)/sum(obj.xProjection);
       end
       function yCenterOfMass = calculateyCenterOfMass(obj)
           yCenterOfMass = sum(obj.yProjection.*obj.yCoordinates)/sum(obj.yProjection);
       end
       function xRMSWidth = calculatexRMSWidth(obj)
           xRMSWidth = std(obj.xProjection);
       end
       function yRMSWidth = calculateyRMSWidth(obj)
           yRMSWidth = std(obj.yProjection);
       end
           
   end
   methods (Static=true)
       
       %%Class utility methods
       objList = findall()
       tf = objExists(filename)
       [filename, path] = checkForFilename(file)
   end
end