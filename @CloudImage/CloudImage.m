classdef CloudImage < AbsorptionImage
    properties(SetAccess = protected)
        nX%Integrated area of Gaussian fit in x projection
        nY%Integrated area of Gaussian fit in y projection
        xFit %Fit objected containing Gaussian fit in x projection
        yFit %Fit object containing Gaussian fit in y projection
        xFitGOF
        yFitGOF
        fitOffset='none';
        nFit2D
        Fit2D
        Fit2DErr
        Fit2D_SG
        Fit2DErr_SG
        ReturnFraction
        Na_SG
        Nc_SG
        Nt_SG
        NaNorm_SG
        NcNorm_SG
        ya_SG
        yc_SG
        Ndiff_SG
    end
    properties(Dependent)
        xWidth %
        yWidth %
        xFitErr %
        yFitErr %
        xMetricWidth %
        yMetricWidth %
        xPeakHeight %
        yPeakHeight %
        xPeakLocation %
        yPeakLocation %
        avOD %
        peakOD %
        phaseSpaceDensity %
        averageDensity %
        peakDensity %
        aspectRatio %
        collisionFactor %
        evapT %
        evapn %
        eta %
        collisionRate %
        good2bad %
        threeBody %
        evapPSD %
        yWidthLattice
        xWidthLattice
        yPosition2Dfit
        xPosition2Dfit
        yWidth2Dfit
        xWidth2Dfit
    end
    methods
        
        %%Constructor
        function obj = CloudImage(varargin)
            
            %            %define inputs
            %            inputs = inputParser;
            %            inputs.CaseSensitive = false;
            %            inputs.KeepUnmatched = true;
            %            addOptional(inputs,'fitOffset','none',@ischar);
            %
            %            %parse inputs, including those from DER
            %            parse(inputs,varargin{:});
            %            unmatchedNames = fields(inputs.Unmatched);
            %            superclassInputs = cell(length(unmatchedNames)*2,1);
            %            for i = 1:length(unmatchedNames)
            %                superclassInputs{2*i-1} = unmatchedNames{i};
            %                superclassInputs{2*i} = inputs.Unmatched.(unmatchedNames{i});
            %            end
            %
            %call superclass constructor
            obj=obj@AbsorptionImage(varargin{:},'keepImageData',true);
            
            %initialize cloud values
            %            obj.fitOffset = inputs.Results.fitOffset;
            obj.initializeCloudValues();
            
            %clean house
            if ~obj.keepImageData
                obj.imageData.atoms=[];
                obj.imageData.light=[];
                obj.imageData.darkField=[];
            end
            %            delete(inputs)
        end
        
        %%set methods. error checking goes here
        function set.xFit(obj,val)
            obj.xFit=val;
        end
        function set.yFit(obj,val)
            obj.yFit=val;
        end
        function set.Fit2D(obj,val)
            obj.Fit2D=val;
        end
        %%get methods for dependent properties
        function avOD = get.avOD(obj)
            
            avODRangeX=max(round(obj.xFit.b-obj.xFit.c),1):...
                min(round(obj.xFit.b+obj.xFit.c),obj.xCoordinates(end));
            avODRangeY=max(round(obj.yFit.b-abs(obj.yFit.c)),1):...
                min(round(obj.yFit.b+abs(obj.yFit.c)),obj.yCoordinates(end));
            avOD=sum(sum(obj.opticalDensity(avODRangeY,avODRangeX)))...
                /(length(avODRangeX)*length(avODRangeY));
        end
        function peakOD = get.peakOD(obj)
            
            avODRangeX=max(round(obj.xFit.b-obj.xFit.c),1):...
                min(round(obj.xFit.b+obj.xFit.c),obj.xCoordinates(end));
            avODRangeY=max(round(obj.yFit.b-abs(obj.yFit.c)),1):...
                min(round(obj.yFit.b+abs(obj.yFit.c)),obj.yCoordinates(end));
            peakOD=max(max(obj.opticalDensity(avODRangeY,avODRangeX)));
        end
        function phaseSpaceDensity = get.phaseSpaceDensity(obj)
            phaseSpaceDensity = obj.peakOD/(obj.xMetricWidth^2*obj.yMetricWidth)^(1/2);
        end
        function collisionFactor = get.collisionFactor(obj)
            collisionFactor = obj.peakOD/(obj.xWidth*obj.yWidth)^(1/4)/obj.generalizedXS*obj.RESONANT_XS;
        end
        function averageDensity = get.averageDensity(obj)
            averageDensity = obj.nC *0.198748/(4/3*pi*(obj.xMetricWidth^2 * obj.yMetricWidth)) * 10^-6;
        end
        function peakDensity = get.peakDensity(obj)
            avODRangeX=max(round(obj.xFit.b-obj.xFit.c),1):...
                min(round(obj.xFit.b+obj.xFit.c),obj.xCoordinates(end));
            avODRangeY=max(round(obj.yFit.b-abs(obj.yFit.c)),1):...
                min(round(obj.yFit.b+abs(obj.yFit.c)),obj.yCoordinates(end));
            nToAverage = max([round(length(avODRangeX)*length(avODRangeY)*.001) 5]);
            %            orderedDensities = padarray(sort(reshape(obj.opticalDensity(avODRangeY,avODRangeX),[],1),'descend'),nToAverage);
            orderedDensities = sort(reshape(obj.opticalDensity,[],1),'descend');
            peakDensity = 1/obj.generalizedXS*...
                mean(orderedDensities(1:nToAverage))/(obj.xMetricWidth)/10^6/sqrt(2*pi);
        end
        function xWidth = get.xWidth(obj)
            xWidth = max(min(abs(obj.xFit.c),1000),1);
        end
        function yWidth = get.yWidth(obj)
            yWidth = max(min(abs(obj.yFit.c),1000),1);
        end
        function xFitErr = get.xFitErr(obj)
            xFitErr = obj.xFitGOF.rsquare;
        end
        function yFitErr = get.yFitErr(obj)
            yFitErr = obj.yFitGOF.rsquare;
        end
        function xMetricWidth = get.xMetricWidth(obj)
            xMetricWidth=obj.xWidth*obj.pixelSize/obj.magnification;
        end
        function yMetricWidth = get.yMetricWidth(obj)
            yMetricWidth=obj.yWidth*obj.pixelSize/obj.magnification;
        end
        function xWidthLattice = get.xWidthLattice(obj)
            xWidthLattice = obj.xMetricWidth/(1064/2*1e-9);
        end
        function yWidthLattice = get.yWidthLattice(obj)
            yWidthLattice = obj.yMetricWidth/(1064/2*1e-9);
        end       
        function yPosition2Dfit = get.yPosition2Dfit(obj)
            yPosition2Dfit=obj.Fit2D.y0;
        end
        function xPosition2Dfit = get.xPosition2Dfit(obj)
            xPosition2Dfit=obj.Fit2D.x0;
        end
        function yWidth2Dfit = get.yWidth2Dfit(obj)
            yWidth2Dfit=obj.Fit2D.sy;
        end
        function xWidth2Dfit = get.xWidth2Dfit(obj)
            xWidth2Dfit=obj.Fit2D.sx;
        end
        
        function xPeakHeight= get.xPeakHeight(obj)
            xPeakHeight = obj.xFit.a;
        end
        function yPeakHeight= get.yPeakHeight(obj)
            yPeakHeight = obj.yFit.a;
        end
        function xPeakLocation= get.xPeakLocation(obj)
            xPeakLocation = obj.xFit.b;
        end
        function yPeakLocation= get.yPeakLocation(obj)
            yPeakLocation = obj.yFit.b;
        end
        function aspectRatio = get.aspectRatio(obj)
            aspectRatio = obj.xWidth/obj.yWidth;
        end
        function evapT = get.evapT(obj)
            TOF = 15e-3;%(obj.TOF+.05)*10^-3;%2*10^-3;
            BGrad =10e-2;%obj.evap_bfinal*10^-2;%obj.MTOpenBgrad*10^-2;
            
            a=2*(1.48/BGrad)^2;
            b=obj.BOLTZMANN_CONSTANT*TOF^2/obj.MASS;
            c=-1/2*obj.yMetricWidth^2; %extra factor of 1/2 comes from rms width of linear potential in 3d
            
            evapT=(-b+sqrt(b^2-4*a*c))/(2 *a)*10^6;
            
        end
        function evapn = get.evapn(obj)
            BGrad = 10e-2;%obj.evap_bfinal*10^-2;%obj.MTOpenBgrad*10^-2;
            evapn=obj.averageDensity*(obj.yMetricWidth/(((1.48*obj.evapT)/10^6)/(BGrad)))^3;
        end
        function eta=get.eta(obj)
            %fcut=obj.rfend;
            %eta=obj.PLANCK_CONSTANT*(fcut-803.5)*10^6/(obj.BOLTZMANN_CONSTANT*obj.evapT/10^6);
            eta=0;
        end
        function collisionRate=get.collisionRate(obj)
            T = obj.evapT/10^6;
            v = 77.78*sqrt(T)*10^2;
            sigmapoly = [4.2653e+16  -3.9842e+15   1.5398e+14  -3.1893e+12   3.8463e+10  -2.7752e+08   1.2201e+06  -3.3528e+03   5.0438e+00];
            sigma = polyval(sigmapoly,T);
            collisionRate = obj.evapn*10^-13*sigma*v;
        end
        function threeBody = get.threeBody(obj)
            threeBody = 3*0.5e-28*obj.evapn^2;
        end
        function good2bad = get.good2bad(obj)
            n = obj.evapn;
            gammaRandy = 2*1.05e-14*n +3*0.5e-28*n^2;
            good2bad = obj.collisionRate/gammaRandy;
        end
        function evapPSD = get.evapPSD(obj)
            evapPSD = obj.evapn* 2.8733e-13 / sqrt(obj.evapT)^3;
        end
        
        %%UI routines/methods
        function h = uishow(obj,varargin)
            opticalDensity=obj.opticalDensity(obj.yCoordinates,obj.xCoordinates);
            opticalDensity(opticalDensity<0)=0;
            if nargin>1
                hh=figure(varargin{1});
                layout = uiextras.VBox('Parent',varargin{2},'Padding',0,'Spacing',0);
            else
                hh=figure('MenuBar', 'none', ...
                    'Toolbar', 'none', ...
                    'NumberTitle', 'off');
                layout = uiextras.VBox('Parent',hh);
            end
            top = uiextras.HBox('Parent',layout,'Padding',25,'Spacing',55);
            middle = uiextras.HBox('Parent',layout,'Padding',25,'Spacing',55);
            bottom = uiextras.Panel('Parent',layout','BorderType','none');
            layout.Sizes=[-1 -3 60];
            
            tableProps={obj.variables{:} ...
                'nC' ...
                'nX' ...
                'nY' ...
                'xMetricWidth' ...
                'yMetricWidth' ...
                'peakDensity' ...
                'averageDensity'...
                };
            
            for i=1:length(tableProps)
                tableData{i} = obj.(tableProps{i});
            end
            
            
            uitable(...
                'Parent',bottom,...
                'BackgroundColor',[0.9412 0.9412 0.9412],...
                'Data',tableData,...
                'ColumnName',tableProps,...
                'RowName',[],...
                'SelectionHighlight','off'...
                );
            
            
            viewAxes = axes('Parent',middle,'ActivePositionProperty', 'Position');
            imagesc(opticalDensity);
            blu=transpose([1:-1/255:0;1:-1/255:0;ones(1,256)]);
            colormap(blu)
            set(gca,'XTick',1:(length(opticalDensity(1,:))-1)/2:(length(opticalDensity(1,:)-1)))
            set(gca,'XTickLabel',{'-s/2','0','s/2'})
            set(gca,'YTick',1:(length(opticalDensity(:,1))-1)/2:(length(opticalDensity(:,1)-1)))
            set(gca,'YTickLabel',{'-s','0','s/2'})
            axis tight
            
            axes('Parent',top,'ActivePositionProperty', 'Position')
            plot(obj.xFit,'--r',obj.xCoordinates,obj.xProjection,'b');
            %             imagesc(rand(100,100))
            axis tight
            xlabel(''),ylabel(''),legend('off')
            
            axes('Parent',top,'ActivePositionProperty', 'Position')
            axis off
            text(.5,.8,['nC = ' num2str(obj.nC,'%10.3e\n')],...
                'FontSize',10,'HorizontalAlignment','center')
            text(.5,.5,['nX = ' num2str(obj.nX,'%10.3e\n')],...
                'FontSize',10,'HorizontalAlignment','center')
            text(.5,.2,['nY = ' num2str(obj.nY,'%10.3e\n')],...
                'FontSize',10,'HorizontalAlignment','center')
            
            axes('Parent',middle,'ActivePositionProperty', 'Position')
            plot(obj.yFit,'--r',obj.yCoordinates,obj.yProjection,'b');
            %             imagesc(rand(100,100))
            xlabel(''),ylabel(''),legend('off')
            view(90,90);
            axis tight
            
            middle.Sizes = [-3 -1];
            top.Sizes = [-3 -1];
            
            contextmenu = uicontextmenu;
            item1 = uimenu(contextmenu,'Label','Adjust roi','Callback',@contextupdateroi);
            set(get(viewAxes,'Children'),'uicontextmenu',contextmenu);
            
            if nargout
                h=hh;
            end
            
            
            %context menu callbacks
            function contextupdateroi(varargin)
                obj.adjustroi(gca)
                obj.uishow(hh,get(layout,'Parent'))
            end
        end
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
            
            imagesc(opticalDensity);
            blu=transpose([1:-1/255:0;1:-1/255:0;ones(1,256)]);
            colormap(blu)
            set(gca,'XTick',1:(length(opticalDensity(1,:))-1)/2:(length(opticalDensity(1,:)-1)))
            set(gca,'XTickLabel',{'-s/2','0','s/2'})
            set(gca,'YTick',1:(length(opticalDensity(:,1))-1)/2:(length(opticalDensity(:,1)-1)))
            set(gca,'YTickLabel',{'-s','0','s/2'})
            
            subplot(3,3,[1 2])
            plot(obj.xFit,'--r',obj.xCoordinates,obj.xProjection,'b');
            axis tight
            xlabel(''),ylabel(''),legend('off')
            
            subplot(3,3,[6 9]);
            plot(obj.yFit,'--r',obj.yCoordinates,obj.yProjection,'b');
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
        function h = showFits(obj)
            hh = figure;
            hold on
            plot(obj.xCoordinates,obj.xProjection,'b');
            plot(obj.yCoordinates,obj.yProjection,'g');
            plot(obj.xFit,'--r');
            plot(obj.yFit,'--r');
            legend('X projection', 'Y projection');
            xlabel('pixel')
            ylabel('projected OD')
            hold off
            if nargout
                h=hh;
            end
        end
        function adjustroi(obj,varargin) %allows the user to pick a new region of interest
            if nargin>1
                obj.roi.update('parentAxes',varargin{1})
            else
                obj.roi.update('image',obj.opticalDensity())
            end
            obj.initializeAbsorptionValues();
            obj.initializeCloudValues();
            %decide where to adjust the roi
            %decide what the initial position is
        end
        function result = math(obj,expr)
            metaObj = metaclass(obj);
            fieldTokens = {metaObj.PropertyList.Name obj.variables'};
            for i=1:length(fieldTokens)
                expr = strrep(expr,fieldTokens{i},['obj.' fieldTokens{i}]);
            end
            result = eval(expr);
        end
    end
    methods (Access = protected)
        
        %%object initialization routines
        function initializeCloudValues(obj)
            [obj.xFit,obj.xFitGOF] = calculatexFit(obj);
            [obj.yFit,obj.yFitGOF] = calculateyFit(obj);
            obj.nX = calculatenX(obj);
            obj.nY = calculatenY(obj);
              [obj.Fit2D, obj.Fit2DErr] = calculateFit2D(obj);
              obj.nFit2D=calculatenFit2D(obj);
               [obj.Fit2D_SG, obj.Fit2DErr_SG] = calculateFit2D_SG(obj);
              obj.ReturnFraction=calculateReturnFraction(obj);
              obj.Nc_SG=calculateNc_SG(obj);
              obj.Na_SG=calculateNa_SG(obj);
              obj.Nt_SG=calculateNt_SG(obj);
              obj.NcNorm_SG=calculateNcNorm_SG(obj);
              obj.NaNorm_SG=calculateNaNorm_SG(obj);
              obj.Ndiff_SG=calculateNdiff_SG(obj);
              obj.ya_SG=calculateya_SG(obj);
              obj.yc_SG=calculateyc_SG(obj);
             
        end
        function setNumberOfAtoms(obj)
            nX=abs(sqrt(2*pi)*obj.xFit.a*obj.xFit.c*...
                (obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
            nY=abs(sqrt(2*pi)*obj.yFit.a*abs(obj.yFit.c)*...
                (obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
            obj.nX=nX;
            obj.nY=nY;
           
        end
        
        %%calculation methods. any science goes here.
        function [xFit,xFitGOF] = calculatexFit(obj)
%            [xFit, xFitGOF]=CloudImage.fitOffsetGaussian(...
%               obj.xCoordinates,obj.xProjection,'offset',obj.fitOffset,'removeSaturation',false,'bConstraint',254.5,'cConstraint',4.9);
             [xFit, xFitGOF]=CloudImage.fitOffsetGaussian(...
                 obj.xCoordinates,obj.xProjection,'offset',obj.fitOffset,'removeSaturation',false);

        end
        function [yFit,yFitGOF] = calculateyFit(obj)
%            [yFit,yFitGOF]=CloudImage.fitOffsetGaussian(...
%               obj.yCoordinates,obj.yProjection,'offset',obj.fitOffset,'removeSaturation',false,'bConstraint',259.7,'cConstraint',4.7);
             [yFit,yFitGOF]=CloudImage.fitOffsetGaussian(...
                 obj.yCoordinates,obj.yProjection,'offset',obj.fitOffset,'removeSaturation',false);

        end
        function nX = calculatenX(obj)
            nX=abs(sqrt(2*pi)*obj.xFit.a*obj.xFit.c*...
                (obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
        end
        function nY = calculatenY(obj)
            nY=abs(sqrt(2*pi)*obj.yFit.a*abs(obj.yFit.c)*...
                (obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
        end
        function [Fit2D, Fit2DErr] = calculateFit2D(obj)
            [Fit2D, Fit2DErr] = CloudImage.gaussianfit2D(obj.opticalDensity, obj.roi.pos);
        end
        function nFit2D = calculatenFit2D(obj)
            nFit2D=obj.Fit2D.nTotal*((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
        end
        
        function [Fit2D_SG, Fit2DErr_SG] = calculateFit2D_SG(obj)
            [Fit2D_SG, Fit2DErr_SG] = CloudImage.gaussianfit2D_SternGerlach(obj.opticalDensity, obj.roi.pos);
        end
        %nTotal1 == Nc, nTotal2 = Na
       
        function Nc_SG = calculateNc_SG(obj) 
            Nc_SG= 0.7997*1.4052*1.0559*1.2775*2.8515*obj.Fit2D_SG.nTotal1*((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
        end
        function Na_SG = calculateNa_SG(obj) 
            Na_SG= 0.8444*1.1*1.0725*1.1420*1.2557*3.0731*obj.Fit2D_SG.nTotal2*((obj.pixelSize/obj.magnification)^2/obj.generalizedXS);
        end
        function Nt_SG = calculateNt_SG(obj)
            Nt_SG=(obj.Nc_SG+obj.Na_SG);
        end
        function NcNorm_SG = calculateNcNorm_SG(obj) %normalized, hard-coded multiplier to match high field 5-16-2021
%             NcNorm_SG= 1.0559*1.2775*2.8515*obj.Fit2D_SG.nTotal1/( 1.0559*1.2775*2.8515*obj.Fit2D_SG.nTotal1+1.1420*1.2557*3.0731*obj.Fit2D_SG.nTotal2);
              NcNorm_SG = obj.Nc_SG./obj.Nt_SG;  
        end
        function NaNorm_SG = calculateNaNorm_SG(obj) %normalized, hard-coded multiplier to match high field 5-16-2021
%             NaNorm_SG=1.1420*1.2557*3.0731*obj.Fit2D_SG.nTotal2/( 1.0559*1.2775*2.8515*obj.Fit2D_SG.nTotal1+1.1420*1.2557*3.0731*obj.Fit2D_SG.nTotal2);
              NaNorm_SG = obj.Na_SG./obj.Nt_SG;  
        end
        function Ndiff_SG = calculateNdiff_SG(obj) %normalized, hard-coded multiplier to match high field 5-16-2021
              Ndiff_SG = obj.Na_SG - obj.Nc_SG;  
        end
         function ReturnFraction = calculateReturnFraction(obj)
%              ReturnFraction = (obj.Na_SG - obj.Nc_SG)./obj.Nt_SG;
            ReturnFraction=( 0.8444*1.1*1.0725*1.1420*1.2557*3.0731*obj.Fit2D_SG.nTotal2- 0.7997*1.4052*1.0559*1.2775*2.8515*obj.Fit2D_SG.nTotal1)/...
                 ( 0.8444*1.1*1.0725*1.1420*1.2557*3.0731*obj.Fit2D_SG.nTotal2+ 0.7997*1.4052*1.0559*1.2775*2.8515*obj.Fit2D_SG.nTotal1);

        end
        function ya_SG = calculateya_SG(obj) 
            ya_SG=obj.Fit2D_SG.y02;
        end
        function yc_SG = calculateyc_SG(obj) 
            yc_SG=obj.Fit2D_SG.y01;
        end
    end
    methods (Access = public)
        function [Fit2D, Fit2DErr] = calculateFit2Dtwo(obj)
            [Fit2D, Fit2DErr] = CloudImage.gaussianfit2Dtwo(obj.opticalDensity, obj.roi.pos);
        end
    end
    methods (Static)
        
        %%class utility methods
        [fitObj,gofObj] = fitOffsetGaussian( x, y, varargin)
        objList = findall(varargin)
        [tf,obj] = checkForObject(filename)
        [fitObj2,gofObj2] = gaussianfit2D( x, y, varargin)
        [fitObj2,gofObj2] = gaussianfit2Dtwo(x,y,varargin)
        [fitObjSG,gofObjSG] = gaussianfit2D_SternGerlach( x, y, varargin)
    end
end

%%Depreciated functions
%        function setPhotonsPerAtom(obj)
%            ppaRangeX=max(round(obj.xFit.b-obj.xFit.c),1):...
%                min(round(obj.xFit.b+obj.xFit.c),obj.xCoordinates(end));
%            ppaRangeY=max(round(obj.yFit.b-obj.yFit.c),1):...
%                min(round(obj.yFit.b+obj.yFit.c),obj.yCoordinates(end));
%            adjustedOpticalDensity=obj.opticalDensity;
%            adjustedOpticalDensity(adjustedOpticalDensity==0)=1;
%            obj.photonsPerAtom=abs(obj.light(ppaRangeY,ppaRangeX)./...
%                adjustedOpticalDensity(ppaRangeY,ppaRangeX)...
%                *obj.CAMERA_GAIN*obj.generalizedXS/...
%                (obj.pixelSize/obj.magnification)^2);
%            meanppa=mean(mean(obj.photonsPerAtom));
%            stdppa=std(std(obj.photonsPerAtom));
%            cutoffppa=(meanppa+2*stdppa);
%            obj.photonsPerAtom(obj.photonsPerAtom>cutoffppa)=0;
%        end