classdef (Abstract) BECVImage  < dynamicprops
%IMAGEOBJECT is an abstract handle class that implements dynamicprops. It
%   is the superclass for all types of image data. Contains as  properties
%   constants, images, and experiment variables. Contains data selection
%   functions and blueprints for basic image processing functions.
%   Jesse Amato-Grill, MIT 10/13/2014

    properties (Constant)
        BOLTZMANN_CONSTANT = 1.3806503*10^(-23); %Boltzmann's Constant
        MASS = 1.1623772*10^(-26); %mass of 7-Li
        WAVELENGTH = 671*10^(-9); %wavelength of ground state transition in 7-Li
        RESONANT_XS = 3/(2*pi)* (671*10^(-9))^2; %resonant scattering cross section, wavelength dependent
        LINE_WIDTH = 5.9e6; %natural linewidth of 7-Li in Hz
        BOHR_MAGNETON = 9.274e-14; %Bohr magneton in SI
        PLANCK_CONSTANT = 6.626e-34; %Planck's Constant
        HBAR = 6.626e-34/(2*pi); %hbar
        BOHR_RADIUS=5.29*10^(-11); %Bohr Radius
    end 
    properties (Hidden, Access=protected)
        timestamp = now
    end
    properties (SetAccess = immutable, Abstract = true)
    end
    properties(SetAccess = protected, Abstract = true)
        cameraID %contains camera ID
        magnification; %optical magnification
        roi %binary roi mask tme same size as the image
        variables % cell array containing the names of imported variables
        pixelSize % the size of the camera pixels in meters
    end
    properties (Dependent, SetAccess = protected, Abstract=true)
        xCoordinates %vector of the image's horizontal coordinates
        yCoordinates %vector of the image's vertical coordinates        
    end
    methods (Access = protected, Abstract=true)
%          loadFromFile(obj,filename) %routine which initializes the properties of the object from aia file
%          loadFromDatabase(obj,runID) %routine which initializes the properties of the object from database
    end
    methods (Access = public, Abstract = true)
         h = show(obj,varargin) %function which displays graphical data about the object
    end
    methods (Access=public)
        function equals = eq(obj1,obj2) %equals function for ImageObjects
            equals = false;
            if obj1.filename == obj2.filename &&...
                obj1.path == obj2.path
                equals = true;
            end
        end 
    end
    methods (Access = protected, Static = true)
         [filename, filepath] = selectFile(varargin) %UI to select a file
         [image1, image2, image3, props] = readAIA(filename) %extracts images and properties from AIA files
         [image1, image2, image3, props] = readDatabase(runID) %queries database for images and properties
         data = queryDatabaseProperty(imageID,property) %queries database for specific property
         idlist = enumerateImageIDs(n)
         result = parseMath(inputString)
    end
end