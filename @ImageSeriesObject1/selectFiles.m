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

    [varargout{1}, varargout{2}] = uigetfile('*.aia','Please Select Files to Analyze','MultiSelect','on');
    if ~iscell(varargout{1})
        varargout{1}={varargout{1}};
    end
    
    cd (initialDirectory)
    
end