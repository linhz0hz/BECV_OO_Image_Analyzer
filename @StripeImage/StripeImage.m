classdef StripeImage < AbsorptionImage   % StripeImage inherits from Absorption Image
    properties(SetAccess = protected)
        fit
        fitErr
        F
        evaluatedFit
    end
    properties(Dependent)
        err
        A
        Aerr
        x0
        x0Err
        y0
        y0Err
        R         
        Rerr      
        c         
        cErr      
        lambda    
        lambdaErr 
        angle     
        angleErr  
        phi       
        phiErr   
        nStripe
        xFitProjection
        yFitProjection
    end
    methods
        
        %% Constructor
        function obj = StripeImage(varargin)
            
            %call superclass constructor
            obj=obj@AbsorptionImage(varargin{:},'keepImageData',true);
            obj.initializeStripeValues();
            % clean house
            if ~obj.keepImageData
                obj.imageData.atoms     = [];
                obj.imageData.light     = [];
                obj.imageData.darkField = [];
            end
        end
        
        %% Get Methods to calculate dependent variables
%         function F = get.F(obj)
%             F = obj.findFit();
%         end   
        function err = get.err(obj)
            err = obj.findErr();
        end   
        function A = get.A(obj)
            A = obj.calculateA();
        end      
        function Aerr = get.Aerr(obj)
            Aerr = obj.calculateAerr();
        end
        function x0 = get.x0(obj)
            x0 = obj.calculateX0();
        end        
        function x0Err = get.x0Err(obj)
            x0Err = obj.calculateX0err();
        end        
        function y0 = get.y0(obj)
            y0 = obj.calculateY0();
        end        
        function y0Err = get.y0Err(obj)
            y0Err = obj.calculateY0err();
        end
        function R = get.R(obj)
            R = obj.calculateR();
        end        
        function Rerr = get.Rerr(obj)
            Rerr = obj.calculateRerr();
        end        
        function c = get.c(obj)
            c = obj.calculateC();
        end        
        function cErr = get.cErr(obj)
            cErr = obj.calculateCerr();
        end        
        function lambda = get.lambda(obj)
            lambda = obj.calculateLambda();
        end        
        function lambdaErr = get.lambdaErr(obj)
            lambdaErr = obj.calculateLambdaErr();
        end
        function angle = get.angle(obj)
            angle = obj.calculateAngle();
        end        
        function angleErr = get.angleErr(obj)
            angleErr = obj.calculateAngleErr();
        end        
        function phi = get.phi(obj)
            phi = obj.calculatePhi();
        end        
        function phiErr = get.phiErr(obj)
            phiErr = obj.calculatephiErr();
        end  
        function nStripe = get.nStripe(obj)
            nStripe = obj.calculateNstripe();
        end
        
        function xFitProjection=get.xFitProjection(obj)
            xFitProjection=obj.calculatexFitProjection();
        end
        function yFitProjection=get.yFitProjection(obj)
            yFitProjection=obj.calculateyFitProjection();
        end
        
        %% UI methods
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
            plot(obj.xCoordinates(x1:x2),obj.xProjection(x1:x2),'b.',obj.xCoordinates(x1:x2),obj.xFitProjection(x1:x2),'r--');
            axis tight
            xlabel(''),ylabel(''),legend('off')
            
            subplot(3,3,[6 9]);
            plot(obj.yCoordinates(y1:y2),obj.yProjection(y1:y2),'b.',obj.yCoordinates(y1:y2),obj.yFitProjection(y1:y2),'r--');
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
        function initializeStripeValues(obj)
            obj.fit = {'1'};
            obj.fitErr = {'2'};
            [obj.F,obj.xProjection,obj.yProjection,~,~,~] = StripeImage.fit_stripes(obj);

            %prepare evaluation grid and evaluate the fit on the grid
            [x,y]=meshgrid(1:size(obj.opticalDensity,2),1:size(obj.opticalDensity,1));
            obj.evaluatedFit = obj.F(x,y);
        end
        function errs = findErr(obj)
            errs = diff(confint(obj.F));
        end        
        function A = calculateA(obj)
            A = obj.F.a;
        end
        function Aerr = calculateAerr(obj)
            Aerr = obj.err(1);
        end
        function x0 = calculateX0(obj)
            x0 = obj.F.x0;
        end
        function x0Err = calculateX0err(obj)
            x0Err = obj.err(2);
        end
        function y0 = calculateY0(obj)
            y0 = obj.F.y0;
        end
        function y0Err = calculateY0err(obj)
            y0Err = obj.err(3);
        end
        function R = calculateR(obj)
            R = obj.F.R;
        end
        function Rerr = calculateRerr(obj)
            Rerr = obj.err(4);
        end
        function c = calculateC(obj)
            c = obj.F.c;
        end
        function cErr = calculateCerr(obj)
            cErr = obj.err(5);
        end
        function lambda = calculateLambda(obj)
            lambda = obj.F.lambda;
        end
        function lambdaErr = calculateLambdaErr(obj)
            lambdaErr = obj.err(6);
        end
        function angle = calculateAngle(obj)
            angle = obj.F.angle;
        end
        function angleErr = calculateAngleErr(obj)
            angleErr = obj.err(7);
        end
        function phi = calculatePhi(obj)
            phi = obj.F.phi;
        end
        function phiErr = calculatePhiErr(obj)
            phiErr = obj.err(8);
        end
        function nStripe = calculateNstripe(obj)
            nStripe = 4 / 3 * pi * ( obj.R )^3;
        end
        function xFitProjection = calculatexFitProjection(obj)
            xFitProjection = sum(obj.evaluatedFit,1);
        end
        function yFitProjection = calculateyFitProjection(obj)
            yFitProjection = sum(obj.evaluatedFit,2);
        end
    end
    methods (Static)
        [fitStripes,xProjection,yProjection,X,Y,Z] = fit_stripes(a,varargin)
    end
end