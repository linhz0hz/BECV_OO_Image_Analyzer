function varargout = selectFile(varargin)
% SELECTFILE Selects file using standard open file UI (UIGETFILE). Can
%   optionally be called with a string argument containing the first
%   directory to open. If no file is selected by the user,...
%   
%   filename = SELECTFILE()
%   filename = SELECTFILE('directory')
%   [filename, path] = SELECTFILE()
%   [filename, path] = SELECTFILE('directory')
%
%   See also UIGETFILE

    initialDirectory=pwd;
    if nargin
        if isdir(varargin{1})
            cd (varargin{1})
        end
    end

    [varargout{1}, varargout{2}] = uigetfile('*.aia','Please Select File to Analyze');
    if varargout{1}==0
        %throw error
    end
    cd (initialDirectory)
    
end