classdef AbsorptionImage < BECVImage
%AbsorptionImage is an image class that implements ImageObject.
%   Contains data selection routines, etc.
%   Jesse Amato-Grill, MIT 10/13/2014

   properties (SetAccess = immutable)
   end       
   properties(SetAccess = protected)
        cameraID=3; %cameraID
        pixelSize = 16*10^-6; %pixel size
        roi %roi object
        variables %cell array contaning names of variables imported from Cicero
        imagingDetuning=0; %detuning from resonance in imaging light (MHz)
        generalizedXS %resonant xs corrected for imaging detuning
        magnification=1; %magnification in the optical train
        xProjection %projection of image onto xCoordinates
        yProjection %projection of image onto yCoordinates
        isFringeCorrected; % nth order background correction
        fringeCorrector; % handle to a FringeCorrection object (if isFringeCorrected is set to true)
        scaling=1; %first order background correction
        saturationCorrection; %absorption cross-section saturation correction
        binSize=1;  %binning parameter, must be integer
   end
   properties (Dependent, SetAccess = protected)
        xCoordinates %x coordinates of the region of interest
        yCoordinates %y coordinates of the region of interest
        atoms %atom image; 
        light %light image; 
        darkField %dark field image; 
        normalizedImage %(atoms-darkField)/(light-darkField) image;
        opticalDensity %array containing optical densities at each pixel
        nC %discrete summation of optical density
        xCenterOfMass %zeroth moment in x
        yCenterOfMass %zeroth moment in y
        xRMSWidth %first moment in x
        yRMSWidth %first moment in y
        powerPerPixel %average power per pixel in the roi in Watts
   end
   properties (Hidden, SetAccess = public)
       keepImageData=true;%false;
       imageData=[];
       lightCorrected; % stores corrected light image (if isFringeCorrected is set to true)
       originalSize=[];
   end
   methods
       
       %Constructor
       function obj = AbsorptionImage(varargin) %constructor for AbsorptionImages
           
           %Define expected inputs
           inputs = inputParser;
           inputs.CaseSensitive = false;
           inputs.KeepUnmatched = true;
           addOptional(inputs,'source','database',@(x) any(validatestring(x,{'database','file','array'})));
           addOptional(inputs,'sourceArray',@isnumeric);
           addOptional(inputs,'image','',@ischar);
           addOptional(inputs,'roi',[]);
           addOptional(inputs,'keepImageData',false,@islogical);           
           addOptional(inputs,'isFringeCorrected',false,@islogical);
           addOptional(inputs,'fringeCorrector',[]);
           addOptional(inputs,'saturationCorrection',false,@islogical);
           addOptional(inputs,'binSize',1,@(x)x==floor(x));
           %Parse inputs
           parse(inputs,varargin{:});
           
           %enumerate name-value pairs for properties based on inputs
           propertyNames = fields(inputs.Unmatched);
           userProperties = cell(1,length(propertyNames));
           for i = 1:length(propertyNames)
               userProperties{i}={propertyNames{i};inputs.Unmatched.(propertyNames{i})};
           end
           
           %determine data source
           if strcmp(inputs.Results.source, 'database') %user picked the databse   
          
         
               %this image will have a uniqe imageID
               p = addprop(obj,'imageID');
               %p.SetAccess = 'immutable';
               
               if strcmp(inputs.Results.image, '') %use the latest
                   imageID = BECVImage.enumerateImageIDs(1);
                   obj.imageID =imageID{1};
               elseif strcmp(inputs.Results.image, 'select') %show selection dialog
                   list=BECVImage.enumerateImageIDs(100);
                   listStr = cellfun(@num2str,list,'UniformOutput',false);
                   selectedIndex = listdlg('PromptString','Select an Image:',...
                       'SelectionMode','single',...
                       'ListString',listStr);
                   imageID = list(selectedIndex);
                   obj.imageID=imageID{1};
               else %user specified an imageID, check for validity and proceed
                   newestImageID = BECVImage.enumerateImageIDs(1);
                   obj.imageID=str2double(inputs.Results.image);
                   if obj.imageID>newestImageID{1}
                       error('This image does not exist in the database')
                   end
               end
               
               %load values from databse into imageData
               [obj.imageData.atoms,obj.imageData.light,obj.imageData.darkField,imageProperties]...
                   = BECVImage.readDatabase(obj.imageID);
               
           elseif strcmp(inputs.Results.source, 'file') %user picked a file               
               %this is a file, so it has a path and name
               p = addprop(obj,'path');
               %p.SetAccess = 'immutable';
               p = addprop(obj,'filename');
               %p.SetAccess = 'immutable';
               
               %keep the image data so we don't have to reload
               obj.keepImageData=true;
               
               if strcmp(inputs.Results.image, '') %use the latest in the current directory
                   obj.path = [pwd '\*.aia'];
                   fileList = dir(obj.path);
                   [~,x]=sort([fileList(:).datenum],'ascend');
                   obj.filename = fileList(x==1).name;
               elseif strcmp(inputs.Results.image, 'select') %show selection dialog
                   [obj.filename,obj.path]=BECVImage.selectFile();
               else %user specified a filename, check for validity and proceed
                   [obj.filename,obj.path]=AbsorptionImage.checkForFilename(inputs.Results.image);
               end
               
               %load values from file into imageData
               [obj.imageData.atoms,obj.imageData.light,obj.imageData.darkField,imageProperties]...
                   = BECVImage.readAIA([obj.path obj.filename]);
               
           elseif strcmp(inputs.Results.source, 'array') %user picked an array, so get the source array from the cmd line               
               
               obj.imageData.atoms = inputs.Results.sourceArray(:,:,1);
               obj.imageData.light = inputs.Results.sourceArray(:,:,2);
               obj.imageData.darkField = inputs.Results.sourceArray(:,:,3);
               imageProperties = [];
               %keep the image data so we don't have to reload
               obj.keepImageData=true;
           end           
           
           %add image source defined or user defined properties to object;
           %user defined properties override source image properties
           obj.addPropertiesFromList(imageProperties);
           obj.addPropertiesFromList(userProperties);
           
           %bin the images
           obj.binSize=inputs.Results.binSize;
           obj.binImageData();
           
           %initialize the roi
           obj.initializeroi(inputs.Results.roi);
           
           %perform the scaling
           obj.scaleImage();
           
           %perform fringeCorrection
           obj.isFringeCorrected = inputs.Results.isFringeCorrected; 
           if obj.isFringeCorrected
               if isa(inputs.Results.fringeCorrector,'FringeCorrector')
                   obj.fringeCorrector = inputs.Results.fringeCorrector;
               else
                   error('The constructor expects fringeCorrector to be a valid FringeCorrector handle');
               end
               obj.lightCorrected = obj.fringeCorrector.makeCorrectedImage(obj.atoms-obj.darkField,obj.roi);  
           end
           
           %set saturation correction
           obj.saturationCorrection = inputs.Results.saturationCorrection;
           
           %initialize calculated properties             
           obj.initializeAbsorptionValues();
           
           %clean house
           if ~obj.keepImageData
               obj.imageData.atoms=[];
               obj.imageData.light=[];
               obj.imageData.darkField=[];
           end
           delete(inputs) 
       end
              
       %%Set methods. Error checking goes here
       function set.roi(obj, val) %dispalys the image and a drawable rectangle to select region of interest 
           obj.roi=val;
       end 
       function set.opticalDensity(obj,val) %sets the optical density based on raw image data
           obj.opticalDensity=val;
       end
       function set.scaling(obj,val)  
                obj.scaling = val;       
       end
       
       %%Get methods for dependent properties
       function atoms = get.atoms(obj) %
           if ~isempty(obj.imageData.atoms)
               atoms=obj.imageData.atoms;
           else
               atoms=AbsorptionImage.binImage(...
                   reshape(...                   
                   typecast(BECVImage.queryDatabaseProperty(obj.imageID,'atoms'),'int16'),...
                   fliplr(obj.originalSize)),...
                   obj.binSize)';
           end
       end       
       function light = get.light(obj) %
           if ~isempty(obj.imageData.light)
               light=obj.imageData.light;
           else
               light=AbsorptionImage.binImage(...
                   reshape(...                   
                   typecast(BECVImage.queryDatabaseProperty(obj.imageID,'noatoms'),'int16'),...
                   fliplr(obj.originalSize)),...
                   obj.binSize)';
           end
       end
       function darkField = get.darkField(obj) %
           if ~isempty(obj.imageData.darkField)
               darkField=obj.imageData.darkField;
           else
               darkField=AbsorptionImage.binImage(...
                   reshape(...                   
                   typecast(BECVImage.queryDatabaseProperty(obj.imageID,'dark'),'int16'),...
                   fliplr(obj.originalSize)),...
                   obj.binSize)';
           end
       end
       function normalizedImage = get.normalizedImage(obj) %
           normalizedImage = obj.calculateNormalizedImage();
       end
       function opticalDensity = get.opticalDensity(obj)
           opticalDensity = obj.calculateOpticalDensity();
       end
       function nC = get.nC(obj)
           nC = obj.calculatenC();
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
       function powerPerPixel = get.powerPerPixel(obj)
           powerPerPixel = obj.calculatePowerPerPixel();
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
       function addPropertiesFromList(obj,propList)
           for i=1:length(propList)
               if isletter(propList{i}{1}(1))
                   if isprop(obj,propList{i}{1})
                       obj.(propList{i}{1})=propList{i}{2};
                   else
                       addprop(obj,propList{i}{1});
                       obj.(propList{i}{1})=propList{i}{2};
                   end
               end
           end
       end
       function initializeroi(obj,usethisroi)
           if isempty(usethisroi)
               obj.roi = roi('image',obj.normalizedImage);
           else
               obj.roi = usethisroi; 
           end
       end
       function scaleImage(obj)
%           tempMask = mod(obj.roi.mask+1,2);
          nMaskPixels=max(floor(10/obj.binSize),1);
          x1 = round(obj.roi.pos(1));
          x2 = x1 + round(obj.roi.pos(3));
          y1 = round(obj.roi.pos(2));
          y2 = y1 + round(obj.roi.pos(4));
          tempSubMask = ones(y2-y1+1,x2-x1+1);
          tempSubMask = ~padarray(tempSubMask,[nMaskPixels,nMaskPixels]);
          tempMask = zeros(size(obj.imageData.atoms));
          tempMask(y1-nMaskPixels:y2+nMaskPixels,...
              x1-nMaskPixels:x2+nMaskPixels) = tempSubMask;
          
          
          %tempMask = obj.roi.mask;
%          tempMask = zeros(size(obj.imageData.atoms));
%           tempMask(100:200,200:300)=1;


%tempMask = ~obj.roi.mask;
        %tempMask = ~obj.roi.mask;
          % old scaling
          obj.scaling=sum(sum(obj.atoms(tempMask==1)-obj.darkField(tempMask==1))/sum(sum(obj.light(tempMask==1)-obj.darkField(tempMask==1))));
         
        
          % new scaling
          %tempMask = ~obj.roi.mask;
          %ratio = double(obj.atoms(tempMask==1)-obj.darkField(tempMask==1)) ./ double(obj.light(tempMask==1)-obj.darkField(tempMask==1)); 
          %obj.scaling = mean(ratio(:));
         
          
          
%         obj.scaling = sum(sum(double(obj.atoms(tempMask==1)-obj.darkField(tempMask==1)))) / sum(sum(double(obj.light(tempMask==1)-obj.darkField(tempMask==1))));

%     obj.scaling=1;
       end
       function binImageData(obj)
           obj.originalSize=size(obj.imageData.atoms);
           a=obj.binSize;           
           obj.imageData.atoms=AbsorptionImage.binImage(obj.imageData.atoms,a);
           obj.imageData.light=AbsorptionImage.binImage(obj.imageData.light,a);
           obj.imageData.darkField=AbsorptionImage.binImage(obj.imageData.darkField,a);           
           obj.pixelSize=obj.pixelSize*a;
       end
       function initializeAbsorptionValues(obj)
           obj.generalizedXS=obj.calculategeneralizedXS();
           [obj.xProjection, obj.yProjection] = obj.calculateProjections();        
       end       
       
       %%Calculation methods. Any science goes here.
       function nC = calculatenC(obj)
           nC = (obj.pixelSize/obj.magnification)^2*sum(obj.xProjection)/obj.generalizedXS;
            %if nC<0
            %    nC=0;
            %end
       end
       function normalizedImage = calculateNormalizedImage(obj)
           
           %definitions
           atoms=obj.atoms;
           darkField=obj.darkField;
           light=obj.light;
           atoms=double(atoms-darkField);
           
           if obj.isFringeCorrected
               light=obj.lightCorrected;               
           else
               light=obj.scaling*double(light-darkField);
           end
           
           %remove saturated pixels
           light(light==0)=Inf;
           
           %compute
           normalizedImage = atoms./light;
           
           %set pixels which will give imaginary logs to 1
           normalizedImage(normalizedImage<=.00)=1;
       
       
       end
       function [xProjection, yProjection] = calculateProjections(obj)
           opticalDensity = obj.opticalDensity;
           yProjection = sum(opticalDensity.*obj.roi.mask,2)';
           xProjection = sum(opticalDensity.*obj.roi.mask,1);
       end
       function generalizedXS = calculategeneralizedXS(obj)
           %measured transition linewidth in MHz
           gamma = 6.182;
           
           %saturation intensity in SI units
           saturationIntensity = 25.5;
           
           if obj.saturationCorrection
                generalizedXS = obj.RESONANT_XS*(1/(1+(2*obj.imagingDetuning/gamma)^2))*(1./(1+obj.calculatePowerPerPixel()/saturationIntensity));
           else
               generalizedXS = obj.RESONANT_XS*(1/(1+(2*obj.imagingDetuning/gamma)^2));
           end
       end
       function opticalDensity = calculateOpticalDensity(obj)
           % absorption imaging
           opticalDensity = -log(obj.normalizedImage);
           
           % phase-contrast imaging
           % x = 12 / 5.9; % delta/Gamma
           % opticalDensity = -asin(obj.normalizedImage-1) * (1+(2*x)^2) / x;
       end
       function xCenterOfMass = calculatexCenterOfMass(obj)
            xCenterOfMass = sum(obj.xProjection.*obj.xCoordinates)/sum(obj.xProjection);
       end
       function yCenterOfMass = calculateyCenterOfMass(obj)
           yCenterOfMass = sum(obj.yProjection.*obj.yCoordinates)/sum(obj.yProjection);
       end
       function xRMSWidth = calculatexRMSWidth(obj)
           xRMSWidth=sqrt(sum((obj.xCoordinates-obj.xCenterOfMass).^2.*obj.xProjection)/sum(obj.xProjection));
       end
       function yRMSWidth = calculateyRMSWidth(obj)
           yRMSWidth=sqrt(sum((obj.yCoordinates-obj.yCenterOfMass).^2.*obj.yProjection)/sum(obj.yProjection));
       end
       function powerPerPixel = calculatePowerPerPixel(obj)
           %Quantum efficiency of camera
           CCDEfficiency = .95*25*3;
           
           %hc/lambda in SI
           energyPerPhoton = 2.96e-19;
           
           %imagingTime in s
           imagingTime = 60e-6;
           
           %intensity (W/pixel^2) to power to photon flux * imaging time* quantum efficiency
           CCDConversionFactor= 1/energyPerPhoton*imagingTime*CCDEfficiency;
           
           %get light distribution
           
           %compute
%            powerPerPixel = double(obj.light-obj.darkField)/CCDConversionFactor/(obj.pixelSize/obj.magnification)^2;
           powerPerPixel = double(obj.light-obj.darkField)*obj.scaling/imagingTime/CCDEfficiency*energyPerPhoton/(obj.pixelSize/obj.magnification)^2;
           powerPerPixel = mean(mean(powerPerPixel(obj.roi.yvec,obj.roi.xvec)));
           
       end
           
   end
   methods (Static=true)
       
       %%Class utility methods
       objList = findall()
       tf = objExists(filename)
       [filename, path] = checkForFilename(file)
       binned = binImage(image,a)
   end
end