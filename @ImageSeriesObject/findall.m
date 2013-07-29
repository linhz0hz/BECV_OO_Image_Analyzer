function objList = findall(varargin)
    if isempty(varargin)
        bigObjList=evalin('base','who');
        objList={};
        for i=1:length(bigObjList)
            if strcmpi(class(evalin('base',bigObjList{i})),'ImageSeriesObject')
                objList{length(objList)+1}=evalin('base',bigObjList{i});
            end
        end
    end