classdef BECImageObject < CloudImageObject
    properties(SetAccess = protected)
        
        %         xxFit
        %         y1Fit
    end
    properties(Dependent)
        xcondensateFraction
        ycondensateFraction
        nBEC
        nTH
        xThermalWidth
        yThermalWidth
        tempTH
        xxFit
        y1Fit
    end
    
    
    methods
        function obj = BECImageObject(varargin)
            obj=obj@CloudImageObject(varargin{:});
            %             obj.xxFit=calculatexxFit();
            %             obj.y1Fit=calculatey1Fit();
        end
        
        
        function xcondensateFraction = get.xcondensateFraction(obj)
            xf=obj.xProjection;
            xdata=(1:length(xf));
            bfit=BECImageObject.becfit(xdata,xf);
            
            
            dxdata=mean(diff(xdata));
            thermal=bfit.nth*gbec(3/2,exp(-(xdata-bfit.x0).^2/(2*bfit.sxth^2)),50);
            bec=bfit.nbec*max(0,1-(xdata-bfit.x0).^2/(bfit.sxbec^2));
            integralThermal=sum(thermal)*dxdata;
            integralBEC=sum(bec)*dxdata;
            xcondensateFraction=integralBEC/(integralThermal+integralBEC);
        end
        function ycondensateFraction = get.ycondensateFraction(obj)
            yf=obj.yProjection;
            ydata=(1:length(yf));
            bfit=BECImageObject.becfit(ydata,yf);
            
            
            dydata=mean(diff(ydata));
            thermal=bfit.nth*gbec(3/2,exp(-(ydata-bfit.x0).^2/(2*bfit.sxth^2)),50);
            bec=bfit.nbec*max(0,1-(ydata-bfit.x0).^2/(bfit.sxbec^2));
            integralThermal=sum(thermal)*dydata;
            integralBEC=sum(bec)*dydata;
            ycondensateFraction=integralBEC/(integralThermal+integralBEC);
        end
        
        function nBEC = get.nBEC(obj) % can pick x or y projection
            nBEC=obj.nC*obj.xcondensateFraction;
        end
        function nTH = get.nTH(obj)
            nTH=obj.nC*(1-obj.xcondensateFraction);
            
        end
        function xThermalWidth = get.xThermalWidth(obj)
            xf=obj.xProjection;
            xdata=(1:length(xf));
            bfit=BECImageObject.becfit(xdata,xf);
            
            xThermalWidth=(bfit.sxth*obj.PIXEL_SIZE/obj.magnification); %in TOF
        end
        function yThermalWidth = get.yThermalWidth(obj)
            yf=obj.yProjection;
            ydata=(1:length(yf));
            bfit=BECImageObject.becfit(ydata,yf);
            
            yThermalWidth=(bfit.sxth*obj.PIXEL_SIZE/obj.magnification); %in TOF
        end
        function tempTH = get.tempTH(obj) %can pick if x or y
            wtrap=2*pi*350; %Hz
            tof=(6+.35)*1e-3;
            tempTH=0.5*obj.MASS*wtrap^2*(obj.xThermalWidth^2/(1+wtrap^2*tof^2))/obj.BOLTZMANN_CONSTANT*10^6; %in uK
            
        end
        
        function h = show2(obj,varargin)
            opticalDensity=obj.opticalDensity(obj.yCoordinates,obj.xCoordinates);
            opticalDensity(opticalDensity<0)=0;
            if nargin>1
                hh=figure(varargin{1});
                subplot(3,3,[4 5 7 8],'Parent',varargin{2});
            else
                hh=figure;
                subplot(3,3,[4 5 7 8]);
            end
            
            imagesc(opticalDensity);
            blu=transpose([1:-1/255:0;1:-1/255:0;ones(1,256)]);
            colormap(blu)
            set(gca,'XTick',1:(length(opticalDensity(1,:))-1)/2:(length(opticalDensity(1,:)-1)))
            set(gca,'XTickLabel',{'-s/2','0','s/2'})
            set(gca,'YTick',1:(length(opticalDensity(:,1))-1)/2:(length(opticalDensity(:,1)-1)))
            set(gca,'YTickLabel',{'-s','0','s/2'})
            
            subplot(3,3,[1 2])
            plot(obj.xxFit,'--r',obj.xCoordinates,obj.xProjection,'b');
            %plot(obj.xxFit,'--r',obj.xCoordinates,obj.xProjection,'b');
            axis tight
            xlabel(''),ylabel(''),legend('off')
            
            subplot(3,3,[6 9]);
            plot(obj.y1Fit,'--r',obj.yCoordinates,obj.yProjection,'b');
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
        
        function xxFit=get.xxFit(obj)
            xf=obj.xProjection;
            xdata=(1:length(xf));
            bxfit=BECImageObject.becfit(xdata,xf);
            xxFit=bxfit;
        end
        
        function y1Fit=get.y1Fit(obj)
            yf=obj.yProjection;
            ydata=(1:length(yf));
            byfit=BECImageObject.becfit(ydata,yf);
            y1Fit=byfit;
        end
        
        
        function set.xxFit(obj,val)
            obj.xxFit=val;
        end
        function set.y1Fit(obj,val)
            obj.y1Fit=val;
        end
    end
    
    methods(Access=protected)
        
        
        
        
        
    end
    
    
    
    methods (Static)
        becfit = becfit(ydata,yf)
    end
    
end