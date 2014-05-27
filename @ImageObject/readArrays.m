function [aiaData] = readArrays(atoms,noAtoms,darkField,ciceroNames,ciceroValues)
    
     aiaData={};
     aiaData{1} = {'image1',atoms};
     aiaData{2} = {'image2',noAtoms}
     aiaData{3} = {'image3',darkField};
     
%      Get number of properties retrieved from Cicero:
     ciceroSize = size(ciceroValues);
     ciceroSize = ciceroSize(2);
     
     for i=4:ciceroSize
        aiaData{i} = {ciceroNames(i-3),ciceroValues(i-3)}; 
     end