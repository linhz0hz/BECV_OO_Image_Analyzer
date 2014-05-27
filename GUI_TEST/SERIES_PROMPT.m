function SERIES_PROMPT(parentgui,parenthandles)
    gui = createGUI(parentgui);
    
    function gui = createGUI(parentgui)
        pos = get(parentgui.mainWindow,'Position');
        pos(3)=200;
        pos(4)=35*4;
        gui.promptWindow = figure('Position',pos,'Toolbar','none','MenuBar','none','Name','Series Prompt','NumberTitle','off');
        gui.layout = uiextras.VBox('Parent',gui.promptWindow,'Padding',5);
        gui.topbuttonbox = uiextras.HBox('Parent',gui.layout,'Padding',5);
        gui.middlebuttonbox = uiextras.HBox('Parent',gui.layout,'Padding',5);
        gui.bottombuttonbox = uiextras.HBox('Parent',gui.layout,'Padding',5);
        gui.exitbuttonbox = uiextras.HBox('Parent',gui.layout,'Padding',5);
        gui.topbutton = uicontrol('Style','radiobutton','Parent',gui.topbuttonbox,'String','Selected','Callback',@topbuttonCallback);
        gui.middlebutton = uicontrol('Style','radiobutton','Parent',gui.middlebuttonbox,'String','Next','Callback',@middlebuttonCallback);
        gui.middlebuttontextbox = uicontrol('Style','edit','Parent',gui.middlebuttonbox);
        gui.bottombutton = uicontrol('Style','radiobutton','Parent',gui.bottombuttonbox,'String','Previous','Callback',@bottombuttonCallback);
        gui.bottombuttontextbox = uicontrol('Style','edit','Parent',gui.bottombuttonbox);
        gui.okbutton = uicontrol('Style','PushButton','Parent',gui.exitbuttonbox,'String','Accept','Callback',@okbuttonCallback);
        gui.cancelbutton = uicontrol('Style','PushButton','Parent',gui.exitbuttonbox,'String','Cancel','Callback',@cancelbuttonCallback);
        gui.layout.Sizes=[-1 -1 -1 35];
        %     buttons = uibuttongroup('Parent',layout);
    end

    function cancelbuttonCallback(varargin)
        close(gui.promptWindow);
    end
    function okbuttonCallback(varargin)
        set(gui.promptWindow,'Visible','off')
        selectedvalues = get(parentgui.imList,'value');
        switch find([get(gui.topbutton,'Value') get(gui.middlebutton,'Value') get(gui.bottombutton,'Value')])
            case 1
                numFiles = numel(parenthandles.selectedImages);
                filenames = strcat(repmat(parenthandles.dir,numFiles,1), parenthandles.selectedImages);
            case 2
                numFiles = str2num(get(gui.middlebuttontextbox,'String'));
                filenames = strcat(repmat(parenthandles.dir,numFiles,1), parenthandles.imList(selectedvalues(1):(selectedvalues(1)+numFiles-1)))';
            case 3
                numFiles = str2num(get(gui.bottombuttontextbox,'String'));
                filenames = strcat(repmat(parenthandles.dir,numFiles,1), parenthandles.imList(selectedvalues(1):-1:(selectedvalues(1)-numFiles+1)));
        end
        set(gui.promptWindow,'Visible','off')
        fprintf('Building Series...\n')
        SERIES_GUI(filenames,parenthandles,parentgui);
        close(gui.promptWindow);
    end
    function topbuttonCallback(varargin)
        set(gui.middlebutton,'Value',0)
        set(gui.bottombutton,'Value',0)
    end
    function middlebuttonCallback(varargin)
        set(gui.topbutton,'Value',0)
        set(gui.bottombutton,'Value',0)
    end
    function bottombuttonCallback(varargin)
        set(gui.topbutton,'Value',0)
        set(gui.middlebutton,'Value',0)
    end

end