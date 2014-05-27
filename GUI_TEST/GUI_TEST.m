function GUI_TEST()
    %%Declare Shared variables
    handles = createHandles();
    gui = createGUI(handles);
    fileScanner = timer('ExecutionMode','fixedDelay',...
        'BusyMode','drop',...
        'Period',1,...
        'TimerFcn',@(~,~)updateImageList());
    
    %%Update GUI
    updateGUI();
%     waitfor(handles.currentImage);
    start(fileScanner);   
    
    %%Helper subfunctions
    function handles = createHandles()
        handles.dir = 'Z:\';
%         handles.dirList = listDirs('Z:\');
        handles.imList = listAIAs('Z:\');
        handles.currentImage = [];
        handles.selectedImages=[];
        handles.lastroi = [];
    end

    %%Layout function
    function gui = createGUI(handles)
        gui.mainWindow=figure('Position',[500,500,800,500],'Toolbar','none','MenuBar','none','Name','BEC V Data GUI','NumberTitle','off');
        gui.layout = uiextras.HBox('Parent',gui.mainWindow,'Padding',5);
        gui.leftPane = uiextras.VBox('Parent',gui.layout);
        gui.rightPane = uiextras.VBox('Parent',gui.layout);
        gui.layout.Sizes = [150,-1];
        gui.pathPane = uiextras.HBox('Parent',gui.leftPane,'Position',[10 10 1 1]);
        gui.pathBox = uicontrol('Style','popupmenu','String',handles.dir,'Parent',gui.pathPane);
        gui.dirButton = uicontrol('Style','pushbutton','String','...','Callback',@updateDir,'Parent',gui.pathPane);
        gui.pathPane.Sizes = [-1 24];
        gui.imList = uicontrol('Style','listbox','Parent',gui.leftPane,'Max',2,'Min',0,'Callback',@imListCallback);
        gui.seriesButton = uicontrol('Style','pushbutton','String','Create Series','Parent',gui.leftPane,'Callback',@seriesButtonCallback);
        gui.leftPane.Sizes = [24 -1 24];
        gui.viewPane = uiextras.TabPanel('Parent',gui.rightPane,'Callback',@tabCallback);     
        gui.tab1 = uiextras.Panel('Parent',gui.viewPane,'Title','No Image Selected','BorderType','none');
        gui.tab2 = uiextras.Panel('Parent',gui.viewPane,'Title','No Image Selected','BorderType','none');
        gui.tab3 = uiextras.Panel('Parent',gui.viewPane,'Title','No Image Selected','BorderType','none');
        gui.tab4 = uiextras.Panel('Parent',gui.viewPane,'Title','No Image Selected','BorderType','none');
        gui.tab5 = uiextras.Panel('Parent',gui.viewPane,'Title','No Image Selected','BorderType','none');
        gui.viewPane.TabNames = {'OD','Norm','Atoms','Light','DF'};
        gui.viewPane.SelectedChild = 1;
        
        set(gui.mainWindow,'DeleteFcn',@(~,~)onExit())
    end

    %%Update functions
    function updateGUI()
        set(gui.pathBox,'String',handles.dir)
        set(gui.imList,'String',handles.imList);
    end
    function updateCurrentTab()
        tabNum = gui.viewPane.SelectedChild;
        switch tabNum
            case 1
                %do nothing
            case 2
                drawNorm()
            case 3
                drawAtoms()
            case 4
                drawLight()
            case 5
                drawDF()
        end
    end
    function updateImageList()
        oldFirst = handles.imList(1);
        oldLength = length(handles.imList);
        if length(handles.imList) ~= length(dir([handles.dir '*.aia']))
            handles.imList = listAIAs(handles.dir);
            newFirst= handles.imList(1);
            newLength = length(handles.imList);
            imListChanged = ~strcmp(oldFirst,newFirst);
            updateGUI();
            
            if ~isempty(handles.currentImage) && get(gui.imList,'value')==1 && imListChanged
                pause(1)
                imListCallback();
            elseif ~isempty(handles.currentImage) && imListChanged
                set(gui.imList,'value',get(gui.imList,'value')+newLength-oldLength);
            end
        end
    end

    %Drawing functions
    function drawOD()
        handles.currentImage.uishow(gui.mainWindow,gui.tab1);
        handles.lastroi = handles.currentImage.roi;
%         gui.viewPane.selectedChild = 1;
    end
    function drawNorm()
        axes('Parent',gui.tab2)
        colormap(gray)
        imshow(handles.currentImage.normalizedImage);
    end
    function drawAtoms()
        axes('Parent',gui.tab3)
        colormap(gray)
        imagesc(handles.currentImage.atoms);
    end
    function drawLight()
        axes('Parent',gui.tab4)
        colormap(gray)
        imagesc(handles.currentImage.light);    
    end
    function drawDF()
        axes('Parent',gui.tab5)
        colormap(gray)
        imagesc(handles.currentImage.darkField);
    end
    
    %%Callback subfunctions
    function updateDir(varargin)
        newdir = uigetdir();
        if newdir ~= 0
            if newdir(end)~='\'
                newdir=[newdir '\'];
            end
            handles.dir = newdir;
            handles.imList = listAIAs(handles.dir);
            updateGUI();
        end
    end
    function list = listAIAs(currentDir)
        storageList = dir([currentDir '*.aia']);
%         [~,x]=sort([storageList(:).datenum],'descend');
        list = fliplr({storageList.name});
    end
    function list = listDirs(currentDir)
%         storageList = dir([currentDir '..']);           
%         [~,x]=sort([storageList(:).datenum],'descend');
%         storageList = storageList(x);
%         y=[storageList(:).isdir];
%         storageList = {storageList(y).name};
%         storageList(ismember(storageList,{'.','..'}))=[];
        list=handles.dir;      
    end
    function imListCallback(varargin)
        handles.selectedImages =  handles.imList(get(gui.imList,'value'));
        handles.currentImage = CloudImageObject('file',strcat(handles.dir,handles.selectedImages{1}),'roi',handles.lastroi);
        drawOD();
        set(gui.tab1,'Title',handles.currentImage.filename);
        set(gui.tab2,'Title',handles.currentImage.filename);
        set(gui.tab3,'Title',handles.currentImage.filename);
        set(gui.tab4,'Title',handles.currentImage.filename);
        set(gui.tab5,'Title',handles.currentImage.filename);
        updateCurrentTab();
    end
    function tabCallback(varargin)
        tabNum = varargin{2}.SelectedChild;
        switch tabNum
            case 1
                blu=transpose([1:-1/255:0;1:-1/255:0;ones(1,256)]);
                colormap(blu)
            case 2
                drawNorm()
            case 3
                drawAtoms()
            case 4
                drawLight()
            case 5
                drawDF()
        end   

    end
    function seriesButtonCallback(varargin)
        SERIES_PROMPT(gui,handles);
    end
    function onExit()
        stop(fileScanner);
        delete(fileScanner);
    end

end

