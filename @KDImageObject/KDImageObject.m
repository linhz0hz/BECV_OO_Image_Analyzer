classdef KDImageObject < CloudImageObject
    properties
        transferRatio
    end
    methods
        function obj = KDImageObject(varargin)
            obj=obj@CloudImageObject(varargin{:});
            global roi2
            if isempty(roi2)
                msgbox('Please select a sattelite peak');
                roi2 = roi('image',obj.opticalDensity);
            end
            obj.transferRatio = obj.calculateTransferRatio();
        end
    end
    methods (Access = protected)
        function transferRatio = calculateTransferRatio(obj)
            global roi2
            peaknC=obj.nC;
            oldroi = obj.roi;
            obj.roi=roi2;
            obj.nC = obj.calculatenC();
            transferRatio = 2*obj.nC/(peaknC+2*obj.nC);
            obj.roi = oldroi;
            obj.nC = obj.calculatenC();
        end
    end
    
    
end