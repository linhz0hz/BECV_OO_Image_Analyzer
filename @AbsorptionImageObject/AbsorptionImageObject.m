classdef AbsorptionImageObject < ImageObject
%ABSORPTIONIMAGEOBJECT 

   properties (SetAccess = immutable)
       filename %string containing filename
       path %string containing the path
       imagingDetuning %detuning from resonance in imaging light (MHz)
       SCATTERING_XS %resonant xs corrected for imaging detuning
       MAGNIFICATION %magnification in the optical train
   end
   properties(SetAccess = protected) 
        regionOfInterest %struct containing vectors of x and y pixels ('.x' and '.y')
        opticalDensity %array containing optical densities at each pixel
        thumbnail %.1 scale image stored in RAM
        variables = {}; %cell array contaning names of variables imported from Cicero
   end
   properties (Dependent, SetAccess = protected)
        xCoordinates %x coordinates of the region of interest
        yCoordinates %y coordinates of the region of interest
        atoms %atom image; 1392*1040 pixels (greyscale 1-4095)
        light %light image; 1392*1040 pixels (greyscale 1-4095)
        darkField %dark field image; 1392*1040 pixels (greyscale 1-4095)
        normalizedImage %(atoms-dark field)/(light-dark field) image;
   end
   methods
       function obj = AbsorptionImageObject(varargin) %constructor for AbsorptionImageObjects
           
           %Define expected inputs
           p = inputParser;
           p.CaseSensitive = false;
           addOptional(p,'file','');
           addOptional(p,'magnification',.25,@isnumeric);
           addOptional(p,'resetROI',true,@islogical);
           addOptional(p,'objAlreadyExists',false,@islogical);
           addOptional(p,'keepImageData',false,@islogical);
           addOptional(p,'imagingDetuning',0,@isnumeric);
           
           %Parse inputs
           parse(p,varargin{:});
           magnification=p.Results.magnification;
           file = p.Results.file;
           resetROI=p.Results.resetROI;
           objAlreadyExists=p.Results.objAlreadyExists;
           keepImageData = p.Results.keepImageData;
           imagingDetuning = p.Results.imagingDetuning;                     
           delete(p)
           
           %avoid reprocessing data if it exists in memory
           if ~objAlreadyExists
               if strcmp(file,'')
                   [obj.filename, obj.path]=AbsorptionImageObject.selectFile();
               else
                   [dir, name, ext] = fileparts(file);
                   if strcmpi(ext,'.aia')
                        if strcmp(dir,'')
                            obj.path=pwd;
                        else
                            obj.path=[dir '\'];
                        end
                        obj.filename=[name ext];                    
                   else
                        error('File is not a .aia');
                   end
               end
               obj.imagingDetuning=imagingDetuning;
               obj.MAGNIFICATION=magnification;
               obj.SCATTERING_XS=obj.RESONANT_XS/(1+(2*imagingDetuning*10^6/obj.LINE_WIDTH)^2);               
               loadFromFile(obj,[obj.path obj.filename],keepImageData,resetROI);
           else
               %obj already exists, do nothing
           end
               
       end
       function h = show(obj, varargin) %displays whole normalized image
           h = imagesc(obj.normalizedImage);
       end
       function adjustRegionOfInterest(obj) %allows the user to pick a new region of interest
           obj.regionOfInterest = getRegionOfInterest(obj.normalizedImage);
       end
       function set.regionOfInterest(obj, val) %dispalys the image and a drawable rectangle to select region of interest 
           if isempty(val)
               val=getRegionOfInterest(obj.normalizedImage);
           end
           obj.regionOfInterest=val;
       end 
       function set.opticalDensity(obj,val) %sets the optical density based on raw image data
           obj.opticalDensity=val;
       end
       function xCoordinates = get.xCoordinates(obj) %
           xCoordinates=1:size(obj.opticalDensity,2);
       end
       function yCoordinates = get.yCoordinates(obj) %
           yCoordinates=1:size(obj.opticalDensity,1);
       end
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
           atoms=obj.atoms;
           darkField=obj.darkField;
           light=obj.light;
           atoms=atoms-darkField;
           light=light-darkField;
           scaling=mean(mean(atoms(10:90,450:750)))/mean(mean(light(10:90,450:750)));
           %%scaling=1;
           light(light==0)=Inf;
           normalizedImage = atoms./(scaling*light);
           normalizedImage(normalizedImage<=0)=1;
       end
   end
   methods (Access = protected)
       function loadFromFile(obj,filename,keepImageData,resetROI) %routine which initializes the properties of the object
           p = addprop(obj,'imageData');    %adds a temporary field that conatins raw image data
           obj.imageData = ImageObject.readAIA(filename);   %get image data from file           
           if length(obj.imageData)>3           %add properties based on cicero list variables
               for i=4:length(obj.imageData)
                   propMeta = addprop(obj,obj.imageData{i}{1});
                   obj.variables {length(obj.variables)+1} = obj.imageData{i}{1};
                   obj.(obj.imageData{i}{1})=obj.imageData{i}{2};
                   %propMeta.SetAccess='protected';                   
               end
           end
           normalizedImage = obj.normalizedImage;   %calculate the normalized image
           obj.thumbnail=imresize(normalizedImage,.1);
           obj.opticalDensity = -log(normalizedImage);%calculate and store optical density
           if resetROI
                obj.regionOfInterest = getRegionOfInterest(normalizedImage); %set the region of interest
           else
               global regionOfInterest_global
               obj.regionOfInterest = regionOfInterest_global;
           end
           if ~keepImageData
                delete(p); %get rid of the temporary imageData field
           end
       end
   end
   methods (Static=true)
       objList = findall()
   end
end