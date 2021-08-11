function [data]=queryDatabaseProperty(imageID,property)
    
    conn = database('BECVDatabase','matlab','w0lfg4ng','Vendor','MySQL','Server','192.168.1.227');
    
    sqlQuery = ['SELECT ' property ' FROM images JOIN ciceroOut ON images.runID_fk = ciceroOut.runID JOIN cameras ON images.cameraID_fk = cameras.cameraID where imageID = ' num2str(imageID)];
    curs = exec(conn,sqlQuery);
    curs = fetch(curs);
    data = curs.Data{1};
end