function result = parseMath(inputString)
    if ischar(inputString)
        varList = symvar(inputString);
        for i = 1:length(varList)
            if ~isprop(varList{i})
                error([varList{i} 'is not a property of the image'])
            end
            result = eval(inputString);
        end
    else
        error('Input is not string')
    end
end