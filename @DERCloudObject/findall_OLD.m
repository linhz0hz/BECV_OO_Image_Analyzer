function objList = findall()
    bigObjList=evalin('base','who');
    objList={};
    for i=1:length(bigObjList)
        if strcmpi(class(evalin('base',bigObjList{i})),'CloudImageObject')
            bigObjList{i};
            objList{length(objList)+1}=evalin('base',bigObjList{i});
        end
    end