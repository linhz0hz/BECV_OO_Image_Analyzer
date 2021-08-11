classdef SFPeaksImage < AbsorptionImage
    properties(SetAccess = protected)
        fitx
        fitErrx
        fity
        fitErry
        MPposX
        MPposY
    end
    properties(Dependent)
        widthSFPeak
        widthGaussBG
        distanceSatx
        distanceSaty
        Visibility
        condensateFraction
        Visibility2
    end
    methods
        
        %%Constructor
        function obj = SFPeaksImage(varargin)
             
            %call superclass constructor
            obj=obj@AbsorptionImage(varargin{:},'keepImageData',true);
            
            %set up BEC values
            obj.initializeSFPeaksValues();
            
            %clean house
            if ~obj.keepImageData
                obj.imageData.atoms=[];
                obj.imageData.light=[];
                obj.imageData.darkField=[];
            end
           
            
        end
        
        %%Get Methods
        function widthSFPeak = get.widthSFPeak(obj)
            widthSFPeak = (obj.fity.sSat+obj.fitx.sSat)/2;
        end
        function widthGaussBG = get.widthGaussBG(obj)
            widthGaussBG = obj.calculatewidthGaussBG;
        end
        function distanceSatx = get.distanceSatx(obj)
            distanceSatx = obj.calculatedistanceSatx;
        end
        function  distanceSaty = get.distanceSaty(obj)
            distanceSaty = obj.calculatedistanceSaty;
        end
        function Visibility = get.Visibility(obj)
            Visibility = obj.calculateVisibility;
        end
        function Visibility2 = get.Visibility2(obj)
            Visibility2 = obj.calculateVisibility2;
        end
        function  condensateFraction = get.condensateFraction(obj)
            condensateFraction = obj.calculatecondensateFraction;
        end
        
        
        %%Set Methods
        function set.fitx(obj,val)
            obj.fitx = val;
        end
        function set.fitErrx(obj,val)
            obj.fitErrx = val;
        end
        function set.fity(obj,val)
            obj.fity = val;
        end
        function set.fitErry(obj,val)
            obj.fitErry = val;
        end
        function set.MPposX(obj,val)
            obj.MPposX = val;
        end
        function set.MPposY(obj,val)
            obj.MPposY = val;
        end
        
        
        
    end
    methods(Access=protected)
        
        %%Initialization Methods
        function initializeSFPeaksValues(obj)
            
            [obj.fitx, obj.fitErrx, obj.MPposX] = SFPeaksImage.SFfit(obj.opticalDensity, obj.roi.pos, 0);
            [obj.fity, obj.fitErry, obj.MPposY] = SFPeaksImage.SFfit(obj.opticalDensity, obj.roi.pos, 1);
        end
        
        
        %%Calculation methods. Science goes here.
        
        function widthSFPeak = calculatewidthSFPeak(obj)
            widthSFPeak= (obj.fity.sSat+obj.fitx.sSat)/2*obj.pixelSize/obj.magnification;
        end
        function widthGaussGB = calculatewidthGaussGB(obj)
            widthGaussGB=(obj.fity.sGauss+obj.fitxGauss)/2*obj.pixelSize/obj.magnification;
        end
        function distanceSatx=calculatedistaceSatx(obj)
            distanceSatx=obj.fitx.aL;
        end
        function distanceSaty=calculatedistaceSaty(obj)
            distanceSaty=obj.fity.aL;
        end
        function Visibility=calculateVisibility(obj)
            SatIntegral=( obj.fitx.ap1+ obj.fitx.am1)* obj.fitx.sSat*sqrt(2*pi)+...
                ( obj.fity.ap1+ obj.fity.am1)* obj.fity.sSat*sqrt(2*pi);
            
            %define coordinates of squares [top left corner]: [x,y,width,height]
            dx= round(2*obj.fitx.sSat); %width
            dy= round(2*obj.fity.sSat);  %height
            xpos1=round(obj.MPposX - obj.fity.aL/2);  %middle points
            ypos1=round(obj.MPposY - obj.fity.aL/sqrt(2));
            xpos2=round(obj.MPposX + obj.fity.aL/2);
            ypos2=round(obj.MPposY + obj.fity.aL/sqrt(2));
            topleft=[xpos1-dx/2, ypos1-dy/2, dx, dy];
            bottomleft=[xpos1-dx/2, ypos2-dy/2, dx, dy];
            topright=[xpos2-dx/2,ypos1-dy/2,dx,dy];
            bottomright=[xpos2-dx/2,ypos2-dy/2,dx,dy];
            
            MinRegionSum1=sum(sum( obj.opticalDensity(((xpos1-dx):(xpos1+dx)),((ypos1-dy):(ypos1+dy)))));
            MinRegionSum2=sum(sum( obj.opticalDensity(((xpos1-dx):(xpos1+dx)),((ypos2-dy):(ypos2+dy)))));
            MinRegionSum3=sum(sum( obj.opticalDensity(((xpos2-dx):(xpos2+dx)),((ypos1-dy):(ypos1+dy)))));
            MinRegionSum4=sum(sum( obj.opticalDensity(((xpos2-dx):(xpos2+dx)),((ypos2-dy):(ypos2+dy)))));
            MinRegion=MinRegionSum1+MinRegionSum2+MinRegionSum3+MinRegionSum4;
            Visibility= (SatIntegral-MinRegion)/(SatIntegral+MinRegion);
            
            
%                         figure
%                         imshow(OD)
            %             hold on
            %             rectangle('Position',topleft,'LineWidth',2,'EdgeColor','white')
            %             rectangle('Position',bottomleft,'LineWidth',2,'EdgeColor','white')
            %             rectangle('Position',topright,'LineWidth',2,'EdgeColor','white')
            %             rectangle('Position',bottomright,'LineWidth',2,'EdgeColor','white')
            %
        end
        
         function Visibility2=calculateVisibility2(obj)
           dx= round(1*obj.xsSat) %width
            dy= round(1*obj.ysSat);  %height
            
             xp1=round(obj.xMPposX - obj.xaL);
             xp2=round(obj.xMPposX + obj.xaL);
              yp1=round(obj.yMPposY - obj.yaL);
               yp2=round(obj.yMPposY + obj.yaL);
            
            SatRegionSum1=sum(sum( obj.opticalDensity(((xp1-dx):(xp1+dx)),((obj.yMPposY-dy):(obj.yMPposY+dy)))));
            SatRegionSum2=sum(sum( obj.opticalDensity(((xp2-dx):(xp2+dx)),((obj.yMPposY-dy):(obj.yMPposY+dy)))));
            SatRegionSum3=sum(sum( obj.opticalDensity(((obj.xMPposX-dx):(obj.xMPposX+dx)),((yp1-dy):(yp1+dy)))));
            SatRegionSum4=sum(sum( obj.opticalDensity(((obj.xMPposX-dx):(obj.xMPposX+dx)),((yp2-dy):(yp2+dy)))));
            SatRegion=SatRegionSum1+SatRegionSum2+SatRegionSum3+SatRegionSum4;
            
            %define coordinates of squares [top left corner]: [x,y,width,height]
            
            xpos1=round(obj.xMPposX - obj.yaL/2);  %middle points
            ypos1=round(obj.yMPposY - obj.yaL/sqrt(2));
            xpos2=round(obj.xMPposX + obj.yaL/2);
            ypos2=round(obj.yMPposY + obj.yaL/sqrt(2));
%             topleft=[xpos1-dx/2, ypos1-dy/2, dx, dy];
%             bottomleft=[xpos1-dx/2, ypos2-dy/2, dx, dy];
%             topright=[xpos2-dx/2,ypos1-dy/2,dx,dy];
%             bottomright=[xpos2-dx/2,ypos2-dy/2,dx,dy];
%                         
            MinRegionSum1=sum(sum( obj.opticalDensity(((xpos1-dx):(xpos1+dx)),((ypos1-dy):(ypos1+dy)))));
            MinRegionSum2=sum(sum( obj.opticalDensity(((xpos1-dx):(xpos1+dx)),((ypos2-dy):(ypos2+dy)))));
            MinRegionSum3=sum(sum( obj.opticalDensity(((xpos2-dx):(xpos2+dx)),((ypos1-dy):(ypos1+dy)))));
            MinRegionSum4=sum(sum( obj.opticalDensity(((xpos2-dx):(xpos2+dx)),((ypos2-dy):(ypos2+dy)))));
            MinRegion=MinRegionSum1+MinRegionSum2+MinRegionSum3+MinRegionSum4;
            Visibility2= (SatRegion-MinRegion)/(SatRegion+MinRegion);
         end
        function condensateFraction=calculatecondensateFraction(obj)
            PeakIntegral=(obj.fitx.ap1+obj.fitx.am1)*obj.fitx.sSat+...
                (obj.fity.ap1+obj.fity.am1)*obj.fity.sSat+...
                0.2*(obj.fitx.aMain*obj.fitx.sSat+obj.fity.aMain*obj.fity.sSat);
            GaussIntegral=0.5*(obj.fitx.aGauss*obj.fitx.sGauss+obj.fity.aGauss*obj.fity.sGauss);
            condensateFraction=PeakIntegral/(GaussIntegral+PeakIntegral);
        end
        
       
    end
    
    methods (Static)
        [fitx, gofx, MPposX] = SFfit(opticalDensity,roi,xory) %xory=0 for x and 1 for y
        
        objList = findall()
        [tf,obj] = checkForObject(filename)
    end
end