classdef (Abstract) ImageObject  < dynamicprops
%IMAGEOBJECT is an abstract handle class that implements dynamicprops. It
%   is the superclass for all types of image data. Contains as  properties
%   constants, images, and experiment variables. Contains data selection
%   functions and blueprints for basic image processing functions.


    properties (Constant)
        BOLTZMANN_CONSTANT = 1.3806503*10^(-23); %Boltzmann's Constant
        MASS = 1.1623772*10^(-26); %mass
        WAVELENGTH = 671*10^(-9); %illumination wavelength
        RESONANT_XS = 3/(2*pi)* (671*10^(-9))^2; %resonant scattering cross section, wavelength dependent
        CAMERA_GAIN = 13.3; %camera gain
        PIXEL_SIZE = 6.45*10^(-6); %unmagnified camera pixel size in meters
        LINE_WIDTH = 5.9e6; %natural linewidth in Hz
    end 
    properties (Hidden, Access=protected)
        timestamp = now
        lastroiPosition %last known local roi position, if any
    end
    properties (SetAccess = immutable, Abstract = true)
        filename %string containing filename
        path %string containing the path
    end
    properties(SetAccess = protected, Abstract = true)
        imagingDetuning %detuning from resonance in imaging light (MHz)
        magnification %optical magnification
        roiMask %binary roi mask tme same size as the image
        variables % cell array containing the names of variables imported from Cicero
%         thumbnail % .1 scale image stored in RAM
    end
    properties (Dependent, SetAccess = protected, Abstract=true)
        xCoordinates %vector of the image's horizontal coordinates
        yCoordinates %vector of the image's vertical coordinates        
    end
    methods (Access = protected, Abstract=true)
         loadFromFile(obj,filename) %routine which initializes the properties of the object
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
         imageData = readAIA(filename) %extracts images and properties from AIA files
    end
end