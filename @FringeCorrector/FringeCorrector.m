classdef FringeCorrector < handle
    %   FringeCorrector is a class which implement fringe correction based
    %   on principle component analysis (PCA)
    %   
    %   The core of this class consists of the following two routines:
    %
    %   initialize() calculates the PCA basis
    %
    %   makeCorrectedImage(atomsImage,ROI) calculates a corrected
    %   lightImage (shot without atoms) for a given atomsImage (shot with
    %   atoms)
    %
    %   The remaining code is data processing.
    %
    %   Paul Niklas Jepsen, MIT 05/20/2015
    
    properties (Hidden = true, Access = private)
        rawImages % stores the images in memory (only stored temporarily if the constructor is not called using explicitly with raw images) (already darkfield corrected)
    end
    properties (Access = private)
        coefficients % the PCA coefficients (coef(i,:) are the coeffecients for the ith basisImage and basisImages == coef * rawImages)
        meanImage % the mean PCA image
        basisImages % the PCA basis
    end
    properties (SetAccess = private, GetAccess = public)
        number % number of images in the PCA basis
        width % width of the images
        height % height of the images
        imageObjects = {} % stores the images, if not constructed from rawImages
        basisID = 0
        imageIDs = []
        cameraID = 0
        source; % specifies were the images (which are used to construct the PCA basis) are coming from
        scaling;
        atomsImage
        localROI
    end
    properties (Dependent)
        isFromDB
    end
    
   
    methods (Access = public)
               
        function obj = FringeCorrector(par,src) % constructor 
          
            % src specifies the source of the image (which are used to create the PCA basis) and par specifies the images
            % 
            % src = 'rawImages'    : par must be an array of images (3D array)
            % src = 'imageObjects' : par must be an array of AbsorptionImage objects
            % src = 'DBImageIDs'   : the images are stored in our database and par must be an array of imageIDs
            % src = "DBBasisID     : a previous PCA basis is stored in the database and par must be its basisID
            
            if nargin < 2
                obj.source = 'DBBasisID';
            else
                obj.source = src;
            end
            
            if strcmp(obj.source,'DBBasisID') 
                if nargin == 0 
                    [obj.imageIDs,obj.basisID] = FringeCorrector.readFromDB();
                else
                    [obj.imageIDs,obj.basisID] = FringeCorrector.readFromDB(par);
                end
            end
            
            if strcmp(obj.source,'DBImageIDs')
                if length(par) == 1
                    obj.imageIDs = FringeCorrector.findLargestImageIDs(par);
                else
                    obj.imageIDs = unique(par);
                end
            end
            
            if strcmp(obj.source,'DBBasisID') || strcmp(obj.source,'DBImageIDs')
                obj.number = length(obj.imageIDs)-1;
            end
            
            
            if strcmp(obj.source,'imageObjects')
                obj.imageObjects = par;
                obj.number = length(obj.imageObjects)-1;
                [exist,IDs] = obj.checkImageObjectsForImageIDs();
                if exist
                    obj.imageIDs = IDs;
                    obj.imageObjects = {};
                    obj.source = 'DBImageIDs';
                end
            end
                
            
            if strcmp(obj.source,'DBBasisID') || strcmp(obj.source,'DBImageIDs')
                
                obj.loadFromDB();
                
            end
            
            if strcmp(obj.source,'imageObjects')
                
                obj.loadFromImageObjects();
                
            end
             
            if strcmp(obj.source,'rawImages')
                [obj.number,obj.height,obj.width] = size(par);
                obj.number = obj.number - 1; % the PCA basis contains one element less
                obj.rawImages = par(:,:);
            end
            
            obj.initialize();
            
            if ~strcmp(obj.source,'rawImages') % erase local variable to save space (if possible)
                obj.rawImages = [];
            end
        end
        
        function images = getImages(obj) % returns an array of images used to construct the PCA basis 
            images = zeros(obj.number+1,obj.height,obj.width);
            switch obj.source
                case 'rawImages'
                    images(:,:) = obj.rawImages;
                case {'DBBasisID','DBImageIDs','imageObjects'} 
                    for i = 1:obj.number+1
                        images(i,:,:) = obj.getImage(i);
                    end
            end
        end
        function image  = getImage(obj,i) % returns the i-th image used to construct the PCA basis 
            image = zeros(obj.height,obj.width);
            switch obj.source
                case 'rawImages'
                    image(:) = obj.rawImages(i,:);
                case {'DBBasisID','DBImageIDs'} 
                    [light,darkfield,~,~] = FringeCorrector.readLightImageFromDB(obj.imageIDs(i));
                    image = light - darkfield;
                case 'imageObjects'
                    light = obj.imageObjects{i}.light;
                    darkfield = obj.imageObjects{i}.darkField;
                    image = light - darkfield;                    
            end
        end
        function images = getBasisImages(obj) % returns an array of the PCA basis images  
            images = zeros(obj.number,obj.height,obj.width);
            images(:,:) = obj.basisImages;
        end
        function image  = getBasisImage(obj,i) % returns the i-th image of the PCA basis 
            image = zeros(obj.height,obj.width);
            image(:) = obj.basisImages(i,:);
        end   
        function coefs  = getCoefficients(obj) % returns the basis transformation matrix (from original set of images to PCA basis) 
            coefs = obj.coefficients;
        end
        function coef   = getCoefficient(obj,i) % returns the coefficients to create the i-th PCA basis image from original set of images 
            coef = obj.coefficients(i,:);
        end
        function image  = getMeanImage(obj) % returns the mean image of the original set of images 
            image = zeros(obj.height,obj.width);
            image(:) = obj.meanImage;
        end
        
        function lightImage = makeCorrectedImage(obj,atomsImage,ROI) % calculates the corrected lightImage (shot without atoms) based on an atomsImage (shot with atoms) 
            % atomsImage has to be darkfield corrected already
            % ROI is an optional parameter for a region of interest (ROI object)
            if nargin < 3
                ROI = roi('image',atomsImage); % query roi
            end
            atomsImage = double(atomsImage);
            lightImage = zeros(obj.height,obj.width); % initilize variable
            lightImage(:) = obj.meanImage' + obj.basisImages'*(obj.basisImages*(atomsImage(:)-obj.meanImage')); % project into PCA subspace            
            lightImage = (atomsImage(:)'*(~ROI.mask(:))) / (lightImage(:)'*(~ROI.mask(:))) * lightImage; % scale image
        end
        function overlap = calculateOverlap(obj,lightImage) % calculates the overlap of a lightImage (shot without atoms) with the PCA basis to check if the PCA basis needs to be updated 
            A = (lightImage(:)-obj.meanImage'); % center around mean
            A = A / sqrt(A'*A); % normalize
            overlap = (A'*obj.basisImages')*(obj.basisImages*A); % calculate overlap with PCA subspace
        end
        
        function basisID = saveToDB(obj) % saves this fringeCorrector object to our database and returns a basisID 
            
            switch obj.source
                case 'DBImageIDs'
                    basisID = FringeCorrector.writeToDB(obj.imageIDs);
                case 'DBBasisID'
                    basisID = obj.basisID;
                otherwise
                    basisID = 0;
            end
                
        end
        
    end
    
    methods
    
        function isFromDB = get.isFromDB(obj) % checks if the images (which are used to construct the PCA basis) are stored in our database 
            isFromDB = strcmp(obj.source,'DBImageIDs') || strcmp(obj.source,'DBBasisID');
        end
    
    end
    
    methods (Access = private)
        
        function initialize(obj) % calculates the PCA basis and stores it to local variables 
            
            disp('Compute the PCA basis set...');
            
            tic
            
            obj.meanImage = mean(obj.rawImages); % calculate mean image (rawImages are already darkfield corrected)
            [basis,coef,~] = princomp(obj.rawImages,'econ'); % principle component analysis
            obj.basisImages = basis'; % save the PCA basis
            obj.coefficients = [inv(coef(1:end-1,:)) zeros(obj.number,1)]; % save the coefficients
        
            toc
            
            disp(' ');
            
        end
        
        function loadFromDB(obj) % loads the images (which will be used to construct the PCA basis) from our database and stores them in a local variable 
            
            disp('Loading images from database...');
            
            tic
            
            for i = 1:obj.number+1
                [light,darkfield,imageWidth,imageHeight,camID] = FringeCorrector.readLightImageFromDB(obj.imageIDs(i));
                if i == 1
                    obj.width = imageWidth;
                    obj.height = imageHeight;
                    obj.rawImages = zeros(obj.number+1,obj.width*obj.height);
                    obj.cameraID = camID;
                else
                    if obj.cameraID ~= camID
                       disp('The images have different sizes and cannot be from the same camera!');
                    end
                end
                obj.rawImages(i,:) = light(:) - darkfield(:);
            end   
            
            toc
            
            disp(' ');
            
        end
        
        function loadFromImageObjects(obj) % loads the images (which will be used to construct the PCA basis) from a set of AbsorptionImage objects and stores them in a local variable 
                
            disp('Loading images from Image objects...');
            
            tic
            
            for i = 1:obj.number+1
                light = obj.imageObjects{i}.light;
                darkfield = obj.imageObjects{i}.darkField;
                imageWidth = length(obj.imageObjects{i}.xCoordinates);
                imageHeight = length(obj.imageObjects{i}.yCoordinates);
                if i == 1
                    obj.width = imageWidth;
                    obj.height = imageHeight;
                    obj.rawImages = zeros(obj.number+1,obj.width*obj.height);
                else
                    if obj.width ~= imageWidth || obj.height ~= imageHeight
                        disp('The images have different sizes and cannot be from the same camera!');
                    end
                end
                obj.rawImages(i,:) = light(:) - darkfield(:);
            end     
            
            toc
            
            disp(' ');
            
        end
         
        function [exist,IDs] = checkImageObjectsForImageIDs(obj) % checks if a set of AbsorptionImage objects are stored in our database (i.e. if the have an imageID stored in them)
            IDs = zeros(obj.number+1,1);
            for i = 1:obj.number+1
                if isprop(obj.imageObjects{i},'imageID')
                    IDs(i) = obj.imageObjects{i}.imageID;
                else
                    IDs(i) = -1;
                end
            end
            exist = ~any(IDs==-1);
        end
        
    end
    
    methods (Static = true, Access = private)
        
        function [imageIDs,basisID] = readFromDB(basisID) % loads a list of imageIDs (which were used to create a PCA basis) from our database, which belong to a previously created PCA basis with a given basisID 
            
            if nargin == 0 % if no basisID is specified it defaults to the largest basisID in the database
                basisID = FringeCorrector.findLargestBasisID();
            end
            
            connection = database('BECVDatabase','root','w0lfg4ng','Vendor','MySQL','Server','192.168.1.227');
            curser = exec(connection,['SELECT * FROM pca WHERE basisID = ', int2str(basisID)]);
            curser = fetch(curser);
            data = curser.Data;
            %close(connection);
            
            if length(data) == 1 % checks if basisID is not found
                imageIDs = [];
            else
                imageIDcolumn = 3;
                imageIDs = unique([data{:,imageIDcolumn}]);
            end
            
        end
        
        function basisID = writeToDB(imageIDs) % saves a list of imageIDs to our database (which were used to create a PCA basis) and returns an associated basisID
            
            basisID = FringeCorrector.findLargestBasisID() + 1;
            
            connection = database('BECVDatabase','root','w0lfg4ng','Vendor','MySQL','Server','192.168.1.227');
            for i = imageIDs
                exec(connection,['INSERT INTO pca (basisID,imageID_fk) VALUES (',int2str(basisID),',',int2str(i),')']);
            end
            %close(connection); 
            
        end
        
        function basisID = findLargestBasisID() % returns the basisID of the latest basis saved in our database 
            
            connection = database('BECVDatabase','root','w0lfg4ng','Vendor','MySQL','Server','192.168.1.227');
            curser = exec(connection,'SELECT basisID FROM pca ORDER BY basisID DESC LIMIT 1');
            curser = fetch(curser);
            data = curser.Data;
            %close(connection);
            
            basisID = data{1};
            
        end
        
        function [light,darkfield,imageWidth,imageHeight, cameraID] = readLightImageFromDB(imageID) % reads a lightImage (shot without atoms) with a given imageID from our database 
            
            connection = database('BECVDatabase','root','w0lfg4ng','Vendor','MySQL','Server','192.168.1.227');
            
            sqlQuery = ['SELECT noAtoms,dark,cameraID_fk FROM images WHERE imageID = ',num2str(imageID)];
            curs = exec(connection,sqlQuery);
            curs = fetch(curs);
            data = curs.Data;
            light = typecast(data{1},'int16');
            darkfield = typecast(data{2},'int16');
            cameraID = data{3};
            
            sqlQuery = ['SELECT cameraWidth,cameraHeight FROM cameras WHERE cameraID = ',num2str(cameraID)];
            curs = exec(connection,sqlQuery);
            curs = fetch(curs);
            data = curs.Data;
            imageWidth = data{1};
            imageHeight = data{2};
            
            %close(connection);
            
            light = reshape(light,[imageHeight imageWidth])';
            darkfield = reshape(darkfield,[imageHeight imageWidth])';
            
        end
            
        function imageIDs = findLargestImageIDs(N) % finds the imageID of the latest image in our database 
            
            if nargin == 0
                N = 1;
            end
            
            connection = database('BECVDatabase','root','w0lfg4ng','Vendor','MySQL','Server','192.168.1.227');
            curser = exec(connection,['SELECT imageID FROM images ORDER BY imageID DESC LIMIT ',int2str(N)]);
            curser = fetch(curser);
            data = curser.Data;
            %close(connection);
            
            imageIDs = [data{:}]';
            
        end
        
    end
    
end