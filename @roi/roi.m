classdef roi < handle
%%roi is a handle class that stores the position and derived mask of an
%%imellipse or an imrect. It contains an update function. Arguments to
%%constructor are 'type' {'imellipse','imrect'} and an image or a
%%parentAxes on which to draw the roi.
    properties (SetAccess = protected)
        type
        pos=[];
        mask
    end
    properties (Dependent)
        xvec
        yvec
    end
    
    methods
        function obj = roi(varargin)
            obj.update(varargin{:}) 
        end                
        function update(obj,varargin)
            [image,parentAxes] = obj.parseInputs(varargin{:});
            if isempty(parentAxes)
                obj.updateWithImage(image)
            else
                obj.updateWithAxes(parentAxes)
            end
        end        
    end
    methods
        function xvec=get.xvec(obj)
            x1 = round(obj.pos(1));
            x2 = x1 + round(obj.pos(3));
            xvec = x1:x2;
        end
        function yvec=get.yvec(obj)
            y1 = round(obj.pos(2));
            y2 = y1 + round(obj.pos(4));
            yvec = y1:y2;
        end
    end
    methods (Access = protected)
        function [image,parentAxes] = parseInputs(obj,varargin)
            p = inputParser;
            p.CaseSensitive = false;
            p.KeepUnmatched = true;
            defaultType = 'imrect'; %'imrect';
            expectedType = {'imellipse','imrect'};
            addOptional(p,'type',defaultType,@(x) any(validatestring(x,expectedType)));
            addOptional(p,'initialPosition',obj.pos);
            addOptional(p,'parentAxes',[]);
            addOptional(p,'image',[]);
            
            parse(p,varargin{:});
            obj.type = p.Results.type;

            obj.pos = p.Results.initialPosition;
            parentAxes=p.Results.parentAxes;
            image = p.Results.image;
            delete(p);
            
            if isempty(parentAxes) && isempty(image)
                error('roi requires an image or parent axes!')
            end
        end
        function roihandle = draw(obj,axeshandle)
            if ~isempty(obj.pos)
                roihandle = feval(obj.type,axeshandle,obj.pos);
            else
                roihandle = feval(obj.type,axeshandle);
            end
            
            fcn = makeConstrainToRectFcn(obj.type,get(gca,'XLim'),get(gca,'YLim'));
            setPositionConstraintFcn(roihandle,fcn);            
        end
        function updateWithAxes(obj,parentAxes)
            roihandle = obj.draw(parentAxes);
            pause
            obj.pos = getPosition(roihandle);
            obj.mask = roihandle.createMask();
            roihandle.delete();
        end
        function updateWithImage(obj,image)
            f = figure('name','Select Analysis Range and Press Any Key','NumberTitle','off',...
                'WindowStyle','modal');
%             im = imshow(image,[],'Border','tight','InitialMagnification',55*512/size(image,2));
            im = imshow(image,'Border','tight','InitialMagnification',55*512/size(image,2));
            axeshandle = get(im,'Parent');
            roihandle = obj.draw(axeshandle);
            flag=0; 
            while flag==0
                flag=waitforbuttonpress;
            end
            obj.pos = getPosition(roihandle);
            obj.mask = roihandle.createMask();
            close(f)
        end
    end
end