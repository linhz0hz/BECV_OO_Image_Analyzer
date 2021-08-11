classdef BEC1DImage < AbsorptionImage
    properties(SetAccess = protected)
        xfit
        xfitErr
        yfit
        yfitErr
    end
    properties(Dependent)
        condensateFraction
        nBEC
        nTH
        xnBEC
        xnTH
        ynBEC
        ynTH
        xnTotal
        ynTotal
        xTHWidth
        yTHWidth
        xBECWidth
        yBECWidth
        xPeakLocation
        yPeakLocation
        aspectRatioBEC
        peakDensity
        xTemp
        yTemp
        xBECWidth0
        yBECWidth0
        wx
        wy
        xFitProjection
        yFitProjection
        xThermalProjection
        yThermalProjection
    end
    methods
        
        %%Constructor
        function obj = BEC1DImage(varargin)
            
            %call superclass constructor
            obj=obj@AbsorptionImage(varargin{:},'keepImageData',true);
            
            %set up BEC values
            obj.initializeBECValues();
            
            %clean house
            if ~obj.keepImageData
                obj.imageData.atoms=[];
                obj.imageData.light=[];
                obj.imageData.darkField=[];
            end
        end
        
        %%Get Methods
        function condensateFraction = get.condensateFraction(obj) %hacked
            condensateFraction = obj.xnBEC/obj.xnTotal;
        end
        function nBEC = get.nBEC(obj) %hacked
            nBEC=obj.xnBEC;
        end
        function nTH = get.nTH(obj) %hacked
            nTH=obj.xnTH;
        end
        function xnBEC = get.xnBEC(obj)
            xnBEC = obj.xfit.nbec;
        end
        function ynBEC = get.ynBEC(obj)
            ynBEC = obj.yfit.nbec;
        end
        function xnTH = get.xnTH(obj)
            xnTH = obj.xfit.nth;
        end
        function ynTH = get.ynTH(obj)
            ynTH = obj.yfit.nth;
        end
        function xnTotal = get.xnTotal(obj)
            xnTotal = obj.xnBEC+obj.ynTH;
        end
        function ynTotal = get.ynTotal(obj)
            ynTotal = obj.ynBEC+obj.ynTH;
        end
        function xTHWidth = get.xTHWidth(obj)
            xTHWidth = obj.xfit.thermalwidth;
        end
        function yTHWidth = get.yTHWidth(obj)
            yTHWidth = obj.yfit.thermalwidth;
        end
        function xBECWidth = get.xBECWidth(obj)
            xBECWidth = obj.xfit.becwidth;
        end
        function yBECWidth = get.yBECWidth(obj)
            yBECWidth = obj.yfit.becwidth;
        end
        function xPeakLocation = get.xPeakLocation(obj)
            xPeakLocation = obj.xfit.x0;
        end
        function yPeakLocation = get.yPeakLocation(obj)
            yPeakLocation = obj.yfit.y0;
        end
        function aspectRatioBEC = get.aspectRatioBEC(obj)
            aspectRatioBEC = obj.xBECWidth/obj.yBECWidth;
        end
        function peakDensity = get.peakDensity(obj)
            peakDensity = obj.calculatePeakDensity();
          
        end
        function xTemp = get.xTemp(obj)
            xTemp = obj.calculatexTemp();
        end
        function yTemp = get.yTemp(obj)
            yTemp = obj.calculateyTemp();
        end
        function xBECWidth0=get.xBECWidth0(obj)
            xBECWidth0=obj.calculatexBECWidth0();
        end
        function yBECWidth0=get.yBECWidth0(obj)
            yBECWidth0=obj.calculateyBECWidth0();
        end
        function wx=get.wx(obj)
            wx=obj.calculatewx();
        end
        function wy=get.wy(obj)
            wy=obj.calculatewy();
        end
        function xFitProjection=get.xFitProjection(obj)
            xFitProjection=obj.calculatexFitProjection();
        end
        function yFitProjection=get.yFitProjection(obj)
            yFitProjection=obj.calculateyFitProjection()';
        end
        function xThermalProjection=get.xThermalProjection(obj)
            xThermalProjection=obj.calculatexThermalProjection();
        end
        function yThermalProjection=get.yThermalProjection(obj)
            yThermalProjection=obj.calculateyThermalProjection()';
        end
     
        
        %%Set Methods
        function set.xfit(obj,val)
            obj.xfit = val;
        end
        function set.xfitErr(obj,val)
            obj.xfitErr = val;
        end
        function set.yfit(obj,val)
            obj.yfit = val;
        end
        function set.yfitErr(obj,val)
            obj.yfitErr = val;
        end
        
        %%UI Methods
%         function h = show(obj,varargin)
%            opticalDensity=obj.opticalDensity(obj.yCoordinates,obj.xCoordinates);
%            opticalDensity(opticalDensity<0)=0;
%            if nargin>1
%                hh=figure(varargin{1});
%                subplot(3,3,[4 5 7 8],'Parent',varargin{2});
%            else
%                hh=figure;
%                subplot(3,3,[4 5 7 8]);
%            end
%            
%            x1 = round(obj.roi.pos(1));
%            x2 = x1 + round(obj.roi.pos(3));
%            y1 = round(obj.roi.pos(2));
%            y2 = y1 + round(obj.roi.pos(4));
%            
%            imagesc(x1:x2,y1:y2,opticalDensity(y1:y2,x1:x2));
%            blu=transpose([1:-1/255:0;1:-1/255:0;ones(1,256)]);
%            colormap(blu)
%            
%            [x,y]=meshgrid(1:size(obj.opticalDensity,1),1:size(obj.opticalDensity,2));
%            % Jesse
%            evaluatedFit = obj.fit.nbec*max((1-((x-obj.fit.x0)/obj.fit.sxbec).^2-((y-obj.fit.y0)/obj.fit.sybec).^2),0).^(3/2)+...
%                obj.fit.nth/gbec(2,1,3)*gbec(2,exp(-((x-obj.fit.x0)/obj.fit.sxth).^2/2-((y-obj.fit.y0)/obj.fit.syth).^2/2),3).*obj.roi.mask;
%            evaluatedPartialFit = obj.fit.nth/gbec(2,1,3)*gbec(2,exp(-((x-obj.fit.x0)/obj.fit.sxth).^2/2-((y-obj.fit.y0)/obj.fit.syth).^2/2),3).*obj.roi.mask;
%            % Niki
%            
%            %evaluatedFit = obj.fit.nth/(2*pi*obj.fit.sxth*obj.fit.syth*1.202)*gbec(2, exp(-(((x-obj.fit.x0)/obj.fit.sxth).^2  +((y-obj.fit.y0)/obj.fit.syth).^2  )/2),20) + obj.fit.nbec*5/(2*pi*obj.fit.sxbec*obj.fit.sybec)*max((1-((x-obj.fit.x0)/obj.fit.sxbec).^2-((y-obj.fit.y0)/obj.fit.sybec).^2),0).^(3/2);
%            %evaluatedPartialFit = obj.fit.nth/(2*pi*obj.fit.sxth*obj.fit.syth*1.202)*gbec(2, exp(-(((x-obj.fit.x0)/obj.fit.sxth).^2  +((y-obj.fit.y0)/obj.fit.syth).^2  )/2),20);
%            
%            % Jesse
%            xFitProjection = sum(evaluatedFit,1);
%            xPartialFitProjection = sum(evaluatedPartialFit,1);
%            yFitProjection = sum(evaluatedFit,2);
%            yPartialFitProjection = sum(evaluatedPartialFit,2);
%            
%            subplot(3,3,[1 2])
%            plot(obj.xCoordinates(x1:x2),obj.xProjection(x1:x2),'b.',obj.xCoordinates(x1:x2),xFitProjection(x1:x2),'r--',obj.xCoordinates(x1:x2),xPartialFitProjection(x1:x2),'g-.');
%            axis tight
%            xlabel(''),ylabel(''),legend('off')
%            
%            subplot(3,3,[6 9]);
%            plot(obj.yCoordinates(y1:y2),obj.yProjection(y1:y2),'b.',obj.yCoordinates(y1:y2),yFitProjection(y1:y2),'r--',obj.yCoordinates(y1:y2),yPartialFitProjection(y1:y2),'g-.');
%            xlabel(''),ylabel(''),legend('off')
%            view(90,90);
%            axis tight
%            
%            subplot(3,3,3)
%            axis off           
%            text(.5,.5,['nC=' num2str(obj.nC,'%10.3e\n')],...
%             'FontSize',10,'HorizontalAlignment','center')           
%            if nargout
%                 h=hh;
%            end
%         end
       
    end
    methods(Access=protected)
        
        %%Initialization Methods
        function initializeBECValues(obj)
            [obj.xfit, obj.xfitErr] = BEC1DImage.becfit(obj.xProjection);
            [obj.yfit, obj.yfitErr] = BEC1DImage.becfit(obj.yProjection);
        end
        
        %%Calculation methods. Science goes here.
        function nBEC = calculatenBEC(obj)
            xRegion = obj.roi.pos(1)+(1:obj.roi.pos(3));
            yRegion = obj.roi.pos(2)+(1:obj.roi.pos(4));
            nBEC = 2*integral2(@(x,y)(obj.fit.nbec*max((1-((x-obj.fit.x0)/obj.fit.sxbec).^2-((y-obj.fit.y0)/obj.fit.sybec).^2),0).^(3/2)),...
                xRegion(1),xRegion(end),yRegion(1),yRegion(end))*...
                ((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
            %nBEC = 2*integral2(@(x,y)(obj.fit.nbec*5/(2*pi*obj.fit.sxbec*obj.fit.sybec)*max((1-((x-obj.fit.x0)/obj.fit.sxbec).^2-((y-obj.fit.y0)/obj.fit.sybec).^2),0).^(3/2)),...
            %    xRegion(1),xRegion(end),yRegion(1),yRegion(end))*...
            %    ((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
        end
        function nTH = calculatenTH(obj)
            xRegion = obj.roi.pos(1)+(1:obj.roi.pos(3));
            yRegion = obj.roi.pos(2)+(1:obj.roi.pos(4));
            nTH = 2*integral2(@(x,y)(obj.fit.nth/gbec(2,1,3)*gbec(2,exp(-((x-obj.fit.x0)/obj.fit.sxth).^2/2-((y-obj.fit.y0)/obj.fit.syth).^2/2),3)),xRegion(1),xRegion(end),yRegion(1),yRegion(end))*...
                ((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
            %nTH = 2*integral2(@(x,y)(obj.fit.nth/(2*pi*obj.fit.sxth*obj.fit.syth*1.202)*gbec(2, exp(-(((x-obj.fit.x0)/obj.fit.sxth).^2  +((y-obj.fit.y0)/obj.fit.syth).^2  )/2),20)),xRegion(1),xRegion(end),yRegion(1),yRegion(end))*...
            %    ((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
        end
        function nTotal = calculatenTotal(obj)
            nTotal = obj.nBEC+obj.nTH;
        end
        function xTHWidth = calculatexTHWidth(obj)
            xTHWidth = obj.fit.sxth*obj.pixelSize/obj.magnification;
        end
        function yTHWidth = calculateyTHWidth(obj)
             yTHWidth = obj.fit.syth*obj.pixelSize/obj.magnification;
        end
        function xBECWidth = calculatexBECWidth(obj)
            xBECWidth = obj.fit.sxbec*obj.pixelSize/obj.magnification;
        end
        function yBECWidth = calculateyBECWidth(obj)
            yBECWidth = obj.fit.sybec*obj.pixelSize/obj.magnification;
        end
        function xFitProjection = calculatexFitProjection(obj)
            coords=1:length(obj.xProjection);
            xFitProjection = obj.xfit.nth/sqrt(2*pi*obj.xfit.thermalwidth^2)/1.2021...
                *gbec(5/2,exp(-(coords-obj.xfit.x0).^2/(2*obj.xfit.thermalwidth^2)),3)+...
                15/16*obj.xfit.nbec/obj.xfit.becwidth*max(0,1-(coords-obj.xfit.x0).^2/obj.xfit.becwidth^2);
        end
        function yFitProjection = calculateyFitProjection(obj)
            coords=1:length(obj.yProjection);
            yFitProjection = obj.yfit.nth/sqrt(2*pi*obj.yfit.thermalwidth^2)/1.2021...
                *gbec(5/2,exp(-(coords-obj.yfit.x0).^2/(2*obj.yfit.thermalwidth^2)),3)+...
                15/16*obj.yfit.nbec/obj.yfit.becwidth*max(0,1-(coords-obj.yfit.x0).^2/obj.yfit.becwidth^2);
        end
        function xThermalProjection = calculatexThermalProjection(obj)
            coords=1:length(obj.xProjection);
            xThermalProjection = obj.xfit.nth/sqrt(2*pi*obj.xfit.thermalwidth^2)/1.2021...
                *gbec(5/2,exp(-(coords-obj.xfit.x0).^2/(2*obj.xfit.thermalwidth^2)),3);
        end
        function yThermalProjection = calculateyThermalProjection(obj)
            coords=1:length(obj.yProjection);
            yThermalProjection = obj.yfit.nth/sqrt(2*pi*obj.yfit.thermalwidth^2)/1.2021...
                *gbec(5/2,exp(-(coords-obj.yfit.x0).^2/(2*obj.yfit.thermalwidth^2)),3);
        end
        function result = math(obj,expr)
            metaObj = metaclass(obj);
            fieldTokens = {metaObj.PropertyList.Name obj.variables'};
            for i=1:length(fieldTokens)
                expr = strrep(expr,fieldTokens{i},['obj.' fieldTokens{i}]);
            end
            result = eval(expr);
        end
        function peakDensity = calculatePeakDensity(obj)
            %NEED TO SET TOF AND SCATTERING LENGTH AND TOF
            a=100;            
%             peakDensity = obj.MASS^2/(8*pi*a*obj.HBAR^2)*(obj.wx*obj.xBECWidth0)^2*10^6;
            tof=0;
            peakDensity = 1/(8*pi*obj.HBAR^2*a*obj.BOHR_RADIUS*(tof^2))*obj.MASS^2/10^6*...
                ((obj.yBECWidth)^2-(obj.yBECWidth0)^2);
            
        end
        function xTemp = calculatexTemp(obj)
            tof=6e-3; % NEED TO SET THIS IN MS
            xTemp=10^9*(1/obj.BOLTZMANN_CONSTANT)*0.5*obj.MASS*(obj.wx^2/(1+obj.wx^2*(tof)^2)*obj.xTHWidth^2);
        end
        function yTemp = calculateyTemp(obj)
             tof=6e-3; % NEED TO SET THIS IN MS
             yTemp=10^9*1/(obj.BOLTZMANN_CONSTANT)*0.5*obj.MASS*(obj.wy^2/(1+obj.wy^2*(tof)^2)*obj.xTHWidth^2);
        end
        function xBECWidth0 = calculatexBECWidth0(obj)
            a=90;
            wbar=(obj.wx*obj.wx*obj.wy)^(1/3);
            xBECWidth0=sqrt((15*obj.HBAR^2*sqrt(obj.MASS)*(obj.nBEC)*(wbar)^3*obj.BOHR_RADIUS*a)^(2/5)/(2)*(1/(0.5*(obj.MASS)*(obj.wx^2 ))));
        end
        function yBECWidth0 = calculateyBECWidth0(obj)
            a=90;
           % wbar=(obj.wx*obj.wx*obj.wy)^(1/3);
            theta=(22.5)/2*pi/180;
           % wbar=obj.wy*(sin(theta)*cos(theta))^(1/3);
            wbar=(obj.wy^2*(2*pi*13))^(1/3);
            yBECWidth0=sqrt((15*obj.HBAR^2*sqrt(obj.MASS)*(obj.nBEC)*(wbar)^3*(obj.BOHR_RADIUS)*a)^(2/5)/(2)*(1/(0.5*(obj.MASS)*(obj.wy^2 ))));
        end
        function wx=calculatewx(obj)
           % wx=pi*455*sqrt(obj.odt_evapp/1.6);
            wx=2*pi*71*sqrt(obj.lattice1_p/0.7);
           
        end
        function wy=calculatewy(obj)
            %wy=pi*748*sqrt(obj.odt_evapp/1.6);
          % wy=2*pi*124*sqrt(obj.lattice1_p/0.8)  
          wy=2*pi*200*sqrt(obj.lattice1_p/2);  
           % wy=2*pi*129*sqrt(obj.odt_evapp/0.3)
        end
        
    end
    
    methods (Static)
        [fit, gof] = becfit(OD,roi)
        objList = findall()
        [tf,obj] = checkForObject(filename)
    end
end