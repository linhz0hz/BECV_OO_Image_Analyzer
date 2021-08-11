function list = enumerateImageIDs(n)
    conn = database('BECVDatabase','matlab','w0lfg4ng','Vendor','MySQL','Server','192.168.1.227');
    
    sqlQuery = ['SELECT imageID FROM images ORDER BY imageID DESC LIMIT ' num2str(n)];
    curs = exec(conn,sqlQuery);
    %print(curs)
    curs = fetch(curs);
    list = curs.Data;
end