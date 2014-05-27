function SERIES_GUI(originalFiles,parenthandles,parentgui)
    
    handles = createHandles(originalFiles);
    
    gui = createGUI(handles);
    
    updateGUI()
    
    function handles = createHandles(originalFiles)
        handles.series = ImageSeriesObject('files',originalFiles,'roi',parenthandles.lastroi);
        handles.imList = handles.series.getProp('filename');
        handles.currentImage = handles.series.imageHandles{1};
        handles.newTabNumber = 2;
        handles.numberOfTabs=2;
        handles.plots={};
        handles.propList = buildNumericPropList(handles.series);
    end
    function gui = createGUI(handles)
        gui.mainWindow = figure('Position',get(parentgui.mainWindow,'Position'),'Toolbar','none','MenuBar','none','Name','Image Series','NumberTitle','off');
        gui.layout = uiextras.HBox('Parent',gui.mainWindow,'Padding',5);
        gui.leftPane = uiextras.VBox('Parent',gui.layout);
        gui.rightPane = uiextras.VBox('Parent',gui.layout);
        gui.layout.Sizes = [150,-1];
        gui.imList = uicontrol('Style','listbox','Parent',gui.leftPane,'Max',2,'Min',0,'Callback',@imListCallback);
        gui.buttonBox = uiextras.HBox('Parent',gui.leftPane);
        gui.leftPane.Sizes = [-1 24];
        gui.addButton = uicontrol('Style','pushbutton','String','Add','Parent',gui.buttonBox,'Callback',@addButtonCallback);
        gui.removeButton = uicontrol('Style','pushbutton','String','Remove','Parent',gui.buttonBox,'Callback',@removeButtonCallback);
        gui.viewPane = uiextras.TabPanel('Parent',gui.rightPane,'Callback',@tabCallback);     
        gui.tabHandles{1} = uiextras.Panel('Parent',gui.viewPane,'Title','No Image Selected','BorderType','none');
        gui.tabHandles{2} = uiextras.Panel('Parent',gui.viewPane,'BorderType','none');
        gui.viewPane.SelectedChild = 1;
        gui.viewPane.TabNames = {'Image','Plot...'};
    end
    
    %Update Fuctions
    function updateGUI()
        updateimList()
        updateTabs()
    end
    function updateimList()
        handles.imList = handles.series.getProp('filename');
        set(gui.imList,'String',handles.imList);
    end
    function updateTabs()
        drawOD();
        set(gui.tabHandles{1},'Title',handles.currentImage.filename);
    end
    function updatePlots()
        
    end
    
    %Drawing Functions
    function drawOD()
        handles.currentImage.uishow(gui.mainWindow,gui.tabHandles{1});
    end
    function drawPlotChoices(tabNum)
        choicePane = uiextras.VBox('Parent',gui.tabHandles{tabNum},'Padding',0);
        buttonPane = uiextras.HBox('Parent',choicePane,'Padding',5);
        xVarPane = uiextras.BoxPanel('Parent',buttonPane,'Title','Choose an x variable');
        yVarPane = uiextras.BoxPanel('Parent',buttonPane,'Title','Choose a y variable');
        pVarPane = uiextras.BoxPanel('Parent',buttonPane,'Title','Choose a parameter');
        okPane = uiextras.HBox('Parent',choicePane,'Padding',0);
        choicePane.Sizes = [-1 24];
        plotButton = uicontrol('Style','pushbutton','String','Plot','Parent',okPane,'Callback',@plotButtonCallback);
        xVar = uiextras.VButtonGroup('Parent',xVarPane,'ButtonStyle','radio','Padding',10,'Spacing',0,'Buttons',handles.propList','SelectionChangeFcn',@pickxVar);
        yVar = uiextras.VButtonGroup('Parent',yVarPane,'ButtonStyle','radio','Padding',10,'Spacing',0,'Buttons',handles.propList','SelectionChangeFcn',@pickyVar);
        pVar = uiextras.VButtonGroup('Parent',pVarPane,'ButtonStyle','radio','Padding',10,'Spacing',0,'Buttons',handles.series.imageVariables','SelectionChangeFcn',@pickpVar);
        
        %internal callbacks
        function pickxVar(src,evt)
        end
        function pickyVar(src,evt)
        end
        function pickpVar(src,evt)
        end
        function plotButtonCallback(varargin)
            xvar = handles.propList(xVar.SelectedChild);
            yvar = handles.propList(yVar.SelectedChild);
            pvar = handles.propList(pVar.SelectedChild);
            delete(choicePane);
            if isempty(pvar)
                handles.series.uiplot(xvar{:},yvar{:},'parent',gui.tabHandles{handles.numberOfTabs},'figure',gui.mainWindow)
            else
            end
            gui.tabHandles{handles.numberOfTabs+1} = uiextras.Panel('Parent',gui.viewPane,'BorderType','none');
            handles.numberOfTabs = handles.numberOfTabs+1;
            handles.newTabNumber=handles.numberOfTabs;
            gui.viewPane.TabNames = horzcat(gui.viewPane.TabNames(1:(end-2)),{[yvar(1) ' vs ' xvar(1)],'Plot...'});
            set(gui.viewPane, 'SelectedChild',handles.numberOfTabs-1)                        
        end
        
    end
    
    %Callback Functions
    function addButtonCallback(varargin)
        handles.series.addImages();
        updateGUI()
    end
    function removeButtonCallback(varargin)
        handles.series.removeImages(get(gui.imList,'Value'));
        set(gui.imList,'Value',1)
        handles.currentImage=handles.series.imageHandles{1};
        updateGUI()
    end
    function tabCallback(varargin)
        tabNum = varargin{2}.SelectedChild;
        if tabNum == handles.newTabNumber
            %display plot choices this tab
            drawPlotChoices(tabNum)
            %replace plot choices with plot
            %add a new plot choice tab
        end
    end
    function imListCallback(varargin)
        handles.selectedImages = get(gui.imList,'value');
        handles.currentImage = handles.series.imageHandles{handles.selectedImages(1)};
        updateGUI()
    end
    
    %helper functions
    function propList = buildNumericPropList(series)
         propList = properties('CloudImageObject');
         keep = zeros(1,length(propList));         
         for i=1:length(propList)
             if isnumeric(series.imageHandles{1}.(propList{i})) && isscalar(series.imageHandles{1}.(propList{i}))
                 mc = findprop(series.imageHandles{1},propList{i});
                 if mc.Constant==0
                    keep(i) = 1;
                 end
             end
         end         
         propList(keep==0)=[];
         propList = vertcat(propList,series.imageVariables');
         propList = sort(propList);
    end
end