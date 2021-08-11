function cleanupWorkspace(classToClear)
    %CLEANUPWORKSPACE clears all variables in the workspace which point to
    %   a deleted handle of the class classToClear
    
workspaceVariables = evalin('base','whos'); % make a list of all variables in the workspace

for i = 1:length(workspaceVariables)
    % check if the variable is the right class and if it points to a deleted handle
    if strcmp(workspaceVariables(i).class,classToClear) && ~evalin('base',['isvalid(', workspaceVariables(i).name, ')'])
        evalin('base',['clear ', workspaceVariables(i).name]); % clear it from workspace
    end
end
    
end

