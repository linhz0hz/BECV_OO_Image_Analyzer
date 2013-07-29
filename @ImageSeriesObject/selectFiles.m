function varargout = selectFiles(varargin)
% SELECTFILE Selects file using standard open file UI (UIGETFILE). Can
%   optionally be called with a string argument containing the first
%   directory to open. If no file is selected by the user,...
%   
%   filenames = SELECTFILES()
%   filenames = SELECTFILES('directory')
%   [filenames, paths] = SELECTFILES()
%   [filenames, paths] = SELECTFILES('directory')
%
%   See also UIGETFILE

    initialDirectory=pwd;
    if nargin
        if isdir(varargin{1})
            cd (varargin{1})
        end
    end

    [a, b] = uigetfile('*.aia','Please Select Files to Analyze','MultiSelect','on');
    varargout{1}=a;
    varargout{2}=b;

    if ~iscell(varargout{1})
        c=cell(1);
        c{1}=a;
        varargout{1}=c;
    end
    
    cd (initialDirectory)
    
end