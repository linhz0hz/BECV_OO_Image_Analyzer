function [atoms,noatoms,dark,properties]=readDatabase(imageID)
    
    conn = database('BECVDatabase','matlab','w0lfg4ng','Vendor','MySQL','Server','192.168.1.227');
    
    sqlQuery = strcat('SELECT * FROM images WHERE imageID = ',num2str(imageID));
    curs = exec(conn,sqlQuery);
    curs = fetch(curs);
    data = curs.Data;
    atoms = typecast(data{5},'int16');
    noatoms = typecast(data{6},'int16');
    dark = typecast(data{7},'int16');
    retrievedRunID = data{2};
    
    sqlQuery = strcat('SELECT * FROM cameras WHERE cameraID = ',num2str(data{4}));
    curs = exec(conn,sqlQuery);
    curs = fetch(curs);
    data = curs.Data;
%     width = data{3};
%     height = data{4};
    width = data{4};
    height = data{3};

    pixelSize=data{6};

    
    atoms = reshape(atoms,[height width])';
    noatoms = reshape(noatoms,[height width])';
    dark = reshape(dark,[height width])';
    
    sqlQuery = strcat('SELECT column_name from information_schema.columns where table_name = ''ciceroOut''');
    curs = exec(conn,sqlQuery);
    curs = fetch(curs);
    varNames = curs.Data;
    varNames{end+1}='pixelSize';
    
    sqlQuery = strcat('SELECT * FROM ciceroOut WHERE runID = ',num2str(retrievedRunID));
    curs = exec(conn,sqlQuery);
    curs = fetch(curs);
    varValues = curs.Data;
    varValues{end+1}=pixelSize*10^-6;
      
    properties = cell(length(varNames),1);
    for i=1:length(varNames)
        properties{i}={varNames{i};varValues{i}};
    end
end