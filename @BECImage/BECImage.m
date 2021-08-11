classdef BECImage < AbsorptionImage
    properties(SetAccess = protected)
        fit
        fitErr
    end
    properties(Dependent)
        condensateFraction
        nBEC
        nTH
        nTotal
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
        visibility
    end
    methods
        
        %%Constructor
        function obj = BECImage(varargin)
            
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
        
        %% Get Methods
        function condensateFraction = get.condensateFraction(obj)
            condensateFraction = obj.nBEC/obj.nTotal;
%                 condensateFraction = 101;
        end
        function nBEC = get.nBEC(obj)
            nBEC = obj.calculatenBEC();
        end
        function nTH = get.nTH(obj)
            nTH = obj.calculatenTH();
        end
        function nTotal = get.nTotal(obj)
            nTotal = obj.nBEC+obj.nTH;
        end
        function xTHWidth = get.xTHWidth(obj)
            xTHWidth = obj.calculatexTHWidth();
        end
        function yTHWidth = get.yTHWidth(obj)
            yTHWidth = obj.calculateyTHWidth();
        end
        function xBECWidth = get.xBECWidth(obj)
            xBECWidth = obj.calculatexBECWidth();
        end
        function yBECWidth = get.yBECWidth(obj)
            yBECWidth = obj.calculateyBECWidth();
        end
        function xPeakLocation = get.xPeakLocation(obj)
            xPeakLocation = obj.fit.x0;
        end
        function yPeakLocation = get.yPeakLocation(obj)
            yPeakLocation = obj.fit.y0;
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
            yFitProjection=obj.calculateyFitProjection();
        end
        function xThermalProjection=get.xThermalProjection(obj)
            xThermalProjection=obj.calculatexThermalProjection();
        end
        function yThermalProjection=get.yThermalProjection(obj)
            yThermalProjection=obj.calculateyThermalProjection();
        end
        function visibility = get.visibility(obj)
            OD=obj.opticalDensity;
            xc=round(obj.xPeakLocation);
            yc=round(obj.yPeakLocation);
            d2hbarkx=round(4.329*obj.TOF+52.8); %in pixels
            d2hbarky=round(d2hbarkx*sqrt(2)); %in pixels
            dother=round(1.457*obj.TOF+0.2349);
            %dmin=round(d2hbarky/sqrt(2));
            dminx=round(d2hbarkx/sqrt(2));
            dminy=round(d2hbarky/sqrt(2));
            delta=10; %sum 2*delta pixels in x and in y
            
            pR=sum(sum(OD((yc-dother)-delta:(yc-dother)+delta,(xc+d2hbarkx)-delta:(xc+d2hbarkx)+delta)));
            pL=sum(sum(OD((yc+dother)-delta:(yc+dother)+delta,(xc-d2hbarkx)-delta:(xc-d2hbarkx)+delta)));
            pT=sum(sum(OD((yc+d2hbarky)-delta:(yc+d2hbarky)+delta,(xc+dother)-delta:(xc+dother)+delta)));
            pB=sum(sum(OD((yc-d2hbarky)-delta:(yc-d2hbarky)+delta,(xc-dother)-delta:(xc-dother)+delta)));
            
            %             mTR=sum(sum(OD((yc+dmin)-delta:(yc+dmin)+delta,(xc+dmin)-delta:(xc+dmin)+delta)));
            %             mTL=sum(sum(OD((yc+dmin)-delta:(yc+dmin)+delta,(xc-dmin)-delta:(xc-dmin)+delta)));
            %             mBL=sum(sum(OD((yc-dmin)-delta:(yc-dmin)+delta,(xc-dmin)-delta:(xc-dmin)+delta)));
            %             mBR=sum(sum(OD((yc-dmin)-delta:(yc-dmin)+delta,(xc+dmin)-delta:(xc+dmin)+delta)));
            %
            mBR=sum(sum(OD((yc+dminy)-delta:(yc+dminy)+delta,(xc+dminx)-delta:(xc+dminx)+delta)));
            mBL=sum(sum(OD((yc+dminy)-delta:(yc+dminy)+delta,(xc-dminx)-delta:(xc-dminx)+delta)));
            mTL=sum(sum(OD((yc-dminy)-delta:(yc-dminy)+delta,(xc-dminx)-delta:(xc-dminx)+delta)));
            mTR=sum(sum(OD((yc-dminy)-delta:(yc-dminy)+delta,(xc+dminx)-delta:(xc+dminx)+delta)));
            
            pc=sum(sum(OD(yc-delta:yc+delta, xc-delta:xc+delta)));
            
            p=pR+pL+pT+pB+0*pc;
            m=mTR+mTL+mBL+mBR;
            visibility=(p-m)/(p+m);
        end
        
        %%Set Methods
        function set.fit(obj,val)
            obj.fit = val;
        end
        function set.fitErr(obj,val)
            obj.fitErr = val;
        end
        
        %% UI Methods
        function h = show(obj,varargin)
            opticalDensity=obj.opticalDensity(obj.yCoordinates,obj.xCoordinates);
            opticalDensity(opticalDensity<0)=0;
            if nargin>1
                hh=figure(varargin{1});
                subplot(3,3,[4 5 7 8],'Parent',varargin{2});
            else
                hh=figure;
                subplot(3,3,[4 5 7 8]);
            end
            
            x1 = round(obj.roi.pos(1));
            x2 = x1 + round(obj.roi.pos(3));
            y1 = round(obj.roi.pos(2));
            y2 = y1 + round(obj.roi.pos(4));
            
            imagesc(x1:x2,y1:y2,opticalDensity(y1:y2,x1:x2));
            blu=transpose([1:-1/255:0;1:-1/255:0;ones(1,256)]);
            colormap(blu)
            
            subplot(3,3,[1 2])
            plot(obj.xCoordinates(x1:x2),obj.xProjection(x1:x2),'b.',obj.xCoordinates(x1:x2),obj.xFitProjection(x1:x2),'r--',obj.xCoordinates(x1:x2),obj.xThermalProjection(x1:x2),'g-.');
            axis tight
            xlabel(''),ylabel(''),legend('off')
            
            subplot(3,3,[6 9]);
            plot(obj.yCoordinates(y1:y2),obj.yProjection(y1:y2),'b.',obj.yCoordinates(y1:y2),obj.yFitProjection(y1:y2),'r--',obj.yCoordinates(y1:y2),obj.yThermalProjection(y1:y2),'g-.');
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
        
    end
    methods(Access=protected)
        
        %%Initialization Methods
        function initializeBECValues(obj)
            [obj.fit, obj.fitErr] = BECImage.becfit2(obj.opticalDensity, obj.roi.pos);
        end
        
        %%Calculation methods. Science goes here.
        function nBEC = calculatenBEC(obj)
            nBEC = 2*obj.fit.nTotal*obj.fit.cf*((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
            %             nBEC = 2*obj.fit.nTotal*obj.fit.cf*((obj.pixelSize/obj.magnification)^2);
        end
        function nTH = calculatenTH(obj)
            nTH = 2*obj.fit.nTotal*(1-obj.fit.cf)*((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
            %             nTH = 2*obj.fit.nTotal*(1-obj.fit.cf)*((obj.pixelSize/obj.magnification)^2);
        end
        function nTotal = calculatenTotal(obj)
            nTotal = obj.fit.ntotal*((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
            %             nTotal = obj.fit.ntotal*((obj.pixelSize/obj.magnification)^2);
        end
        function xTHWidth = calculatexTHWidth(obj)
            xTHWidth = obj.fit.sx*obj.pixelSize/obj.magnification;
        end
        function yTHWidth = calculateyTHWidth(obj)
            yTHWidth = obj.fit.sy*obj.pixelSize/obj.magnification;
        end
        function xBECWidth = calculatexBECWidth(obj)
            xBECWidth = obj.fit.rx*obj.pixelSize/obj.magnification;
        end
        function yBECWidth = calculateyBECWidth(obj)
            yBECWidth = obj.fit.ry*obj.pixelSize/obj.magnification;
        end
        function evaluatedFit = calculateEvaluatedFit(obj)
            
            %prepare evaluation grid
            [x,y]=meshgrid(1:size(obj.opticalDensity,2),1:size(obj.opticalDensity,1));
            
            %evaluate the fit on the grid
            evaluatedFit = obj.fit.nTotal*(1-obj.fit.cf)/(2*pi*obj.fit.sx*obj.fit.sy)/1.202*...
                gbec(2,exp(-((x-obj.fit.x0).^2/obj.fit.sx^2+(y-obj.fit.y0).^2/obj.fit.sy^2)/2),3)...
                +obj.fit.nTotal*obj.fit.cf*5/(2*pi*obj.fit.rx*obj.fit.ry)...
                *max((1-(x-obj.fit.x0).^2/obj.fit.rx^2-(y-obj.fit.y0).^2/obj.fit.ry^2),0).^(3/2);
        end
        function evaluatedBECFit = calculateEvaluatedBECFit(obj)
            
            %prepare evaluation grid
            [x,y]=meshgrid(1:size(obj.opticalDensity,2),1:size(obj.opticalDensity,1));
            
            %evaluate the fit on the grid
            evaluatedBECFit = obj.fit.nTotal*obj.fit.cf*5/(2*pi*obj.fit.rx*obj.fit.ry)...
                *max((1-(x-obj.fit.x0).^2/obj.fit.rx^2-(y-obj.fit.y0).^2/obj.fit.ry^2),0).^(3/2);
            
        end
        function evaluatedThermalFit = calculateEvaluatedThermalFit(obj)
            
            %prepare evaluation grid
            [x,y]=meshgrid(1:size(obj.opticalDensity,2),1:size(obj.opticalDensity,1));
            
            %evaluate the fit on the grid
            evaluatedThermalFit = obj.fit.nTotal*(1-obj.fit.cf)/(2*pi*obj.fit.sx*obj.fit.sy)/1.202*...
                gbec(2,exp(-((x-obj.fit.x0).^2/obj.fit.sx^2+(y-obj.fit.y0).^2/obj.fit.sy^2)/2),3);
            
        end
        function xFitProjection = calculatexFitProjection(obj)
            
            xFitProjection = sum(obj.calculateEvaluatedFit,1);
            
        end
        function yFitProjection = calculateyFitProjection(obj)
            
            yFitProjection = sum(obj.calculateEvaluatedFit,2);
            
        end
        function xThermalProjection = calculatexThermalProjection(obj)
            
            xThermalProjection = sum(obj.calculateEvaluatedThermalFit,1);
            
        end
        function yThermalProjection = calculateyThermalProjection(obj)
            
            yThermalProjection = sum(obj.calculateEvaluatedThermalFit,2);
            
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
        [fit , gof] = becfit2(OD,roi)
        [fit, gof] = becfit(OD,roi)
        objList = findall()
        [tf,obj] = checkForObject(filename)
    end
end