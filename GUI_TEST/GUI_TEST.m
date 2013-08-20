function GUI_TEST()
    %%Declare Shared variables
    handles = createHandles();
    gui = createGUI(handles);
    
    %%Update GUI
    updateGUI();
    
    %%Helper subfunctions
    function handles = createHandles()
        handles.dir = 'D:\DATA\CURRENT';
        handles.imList = listAIAs('D:\DATA\CURRENT');
    end
    function gui = createGUI(handles)
        gui.mainWindow=figure('Position',[500,500,800,500],'Toolbar','none','MenuBar','none','Name','BEC V Data GUI','NumberTitle','off');
        layout = uiextras.HBox('Parent',gui.mainWindow,'Padding',5);
        leftPane = uiextras.VBox('Parent',layout);
        rightPane = uiextras.VBox('Parent',layout);
        layout.Sizes = [150,-1];
        pathPane = uiextras.HBox('Parent',leftPane,'Position',[10 10 1 1]);
        gui.pathBox = uicontrol('Style','popupmenu','String',handles.dir,'Parent',pathPane);
        gui.dirButton = uicontrol('Style','pushbutton','String','...','Callback',@updateDir,'Parent',pathPane);
        pathPane.Sizes = [-1 24];
        gui.imList = uicontrol('Style','listbox','Parent',leftPane,'Max',2,'Min',0,'Callback',@imListCallback);
        gui.seriesButton = uicontrol('Style','pushbutton','String','Create Series','Parent',leftPane);
        leftPane.Sizes = [24 -1 24];
        viewPane = uiextras.TabPanel('Parent',rightPane);
        gui.defaultAxes = axes('Parent',viewPane);
        gui.nextAxes = axes('Parent',viewPane);
        
    end
    function updateGUI()
        set(gui.pathBox,'String',handles.dir)
        set(gui.imList,'String',handles.imList);
    end
    function displayImage(imName)
        image = CloudImageObject('file',imName{:});
        set(gui.mainWindow,'CurrentAxes',gui.defaultAxes)
        image.show()
    end
    %%Callback subfunctions
    function updateDir(varargin)
        newdir = uigetdir();
        if newdir ~= 0
            handles.dir = newdir;
            handles.imList = listAIAs(handles.dir);
            updateGUI();
        end
    end    
    function list = listAIAs(currentDir)
        storageList = dir([currentDir '\*.aia']);
        [~,x]=sort([storageList(:).datenum],'descend');
        list = {storageList(x).name}';
    end
    function imListCallback(varargin)       
        displayImage(strcat(handles.dir, '\', handles.imList(get(gui.imList,'value'))));
    end
        
    function onExit()
    end

end

