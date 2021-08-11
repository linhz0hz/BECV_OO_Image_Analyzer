function objList = findall(varargin)
    if isempty(varargin)
        bigObjList=evalin('base','who');
        objList={};
        for i=1:length(bigObjList)
            if strcmpi(class(evalin('base',bigObjList{i})),'BECImageObject')
                objList{length(objList)+1}=evalin('base',bigObjList{i});
            end
        end
    else
        objList = {};
        bigObjList = BECImageObject.findall();
        if ~isempty(bigObjList)
            for j=1:length(bigObjList)
                i=1;
                objHasProp=true;
                while i<=length(varargin) && objHasProp
                    if ~isprop(bigObjList{j},varargin{i})
                        objHasProp=false;
                    end
                    i=i+1;
                end
                if objHasProp
                    objList{length(objList)+1}=bigObjList{j};
                end
            end
        end
    end
end