classdef AbsorptionImageObject < ImageObject
%ABSORPTIONIMAGEOBJECT is an image class that implements ImageObject.
%Contains data selection routines, 

   properties (SetAccess = immutable)
       filename %string containing filename
       path %string containing the path
   end       
   properties(SetAccess = protected) 
        roi %roi object
        opticalDensity %array containing optical densities at each pixel
%         thumbnail %.1 scale image stored in RAM
        variables = {}; %cell array contaning names of variables imported from Cicero
        imagingDetuning %detuning from resonance in imaging light (MHz)
        generalizedXS %resonant xs corrected for imaging detuning
        magnification %magnification in the optical train   
        nC %discrete summation of optical density
        xProjection %
        yProjection %
        usingDER
        atomsIn
        noAtomsIn
        darkFieldIn
        ciceroNames
        ciceroValues
        Iscaling
   end
   properties (Dependent, SetAccess = protected)
        xCoordinates %x coordinates of the region of interest
        yCoordinates %y coordinates of the region of interest
        atoms %atom image; 1392*1040 pixels (greyscale 1-4095)
        light %light image; 1392*1040 pixels (greyscale 1-4095)
        darkField %dark field image; 1392*1040 pixels (greyscale 1-4095)
        normalizedImage %(atoms-dark field)/(light-dark field) image;
        
   end
   properties (Hidden, SetAccess = protected)
       
   end
   methods
       
       %Constructor
       function obj = AbsorptionImageObject(varargin) %constructor for AbsorptionImageObjects
           
           %Define expected inputs
           p = inputParser;
           p.CaseSensitive = false;
           addOptional(p,'file','');
           addOptional(p,'magnification',2,@isnumeric);
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
           
           delete(p)
           
           %check for flag from subclass constructor
           if ~objAlreadyExists
               if usingDER == 0
               [filename,path]=AbsorptionImageObject.checkForFilename(file);
               else
               filename = '';
               path = '';
               end
               %avoid reprocessing data if it exists in memory
               if ~AbsorptionImageObject.objExists(filename)
                    obj.filename = filename;
                    obj.path = path;
                    obj.imagingDetuning=imagingDetuning;
                    obj.magnification=magnification;
                    obj.usingDER = usingDER;
                   
                    obj.atomsIn = atomsIn;
                    obj.noAtomsIn = noAtomsIn;
                    obj.darkFieldIn = darkFieldIn;
                   
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
       function set.Iscaling(obj,val)
          
                obj.Iscaling = val;
           
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
       function Iscaling = get.Iscaling(obj)
           Iscaling = obj.Iscaling;
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
%              if ~obj.imagingDetuning && isprop(obj,'F2IMGMHz')
%                 obj.imagingDetuning = obj.F2IMGMHz;
%              end
           obj.initializeAbsorptionValues();
           if ~keepImageData
                delete(p); %get rid of the temporary imageData field
           end
       end
       function initializeroi(obj,usethisroi)
           if isempty(usethisroi)
               obj.roi = roi('image',obj.normalizedImage);
           else
               obj.roi = usethisroi; 
           end
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
           opticalDensity = obj.opticalDensity;
           nC = (obj.PIXEL_SIZE/obj.magnification)^2/obj.generalizedXS*...
                sum(sum(opticalDensity.*obj.roi.mask));
       end
       function normalizedImage = calculateNormalizedImage(obj)
           atoms=obj.atoms;
           darkField=obj.darkField;
           light=obj.light;
           atoms=atoms-darkField;
           light=light-darkField;
           %scaling=mean(mean(atoms(950:1040,300:400)))/mean(mean(light(950:1040,300:400)));%used to be 900:100,600:800
          scaling=mean(mean(atoms(10:110,500:700)))/mean(mean(light(10:110,500:700)));%used to be 900:100,600:800
          %scaling=1;
          obj.Iscaling = scaling;
           light(light==0)=Inf;
           normalizedImage = atoms./(scaling*light);
           normalizedImage(normalizedImage<=0)=1;
       end
       function xProjection = calculatexProjection(obj)
           xProjection = sum(obj.opticalDensity.*obj.roi.mask,1);
       end
       function yProjection = calculateyProjection(obj)
           yProjection = sum(obj.opticalDensity.*obj.roi.mask,2)';
       end
       function generalizedXS = calculategeneralizedXS(obj)
           %generalizedXS = obj.RESONANT_XS/(1+(2*obj.imagingDetuning*10^6/obj.LINE_WIDTH)^2);
           %new effective generalizedXS
%            generalizedXS = obj.RESONANT_XS*(1/(1+(2*obj.imagingDetuning/6.23)^2)+.00215);
            generalizedXS = obj.RESONANT_XS*(1/(1+(2*obj.imagingDetuning/6.182)^2)); 
       end
       function opticalDensity = calculateopticalDensity(obj)
           opticalDensity = -log(obj.normalizedImage);%calculate and store optical density
       end
       %function magnification = calculateMagnification(obj)
       %end
   end
   methods (Static=true)
       
       %%Class utility methods
       objList = findall()
       tf = objExists(filename)
       [filename, path] = checkForFilename(file)
   end
end