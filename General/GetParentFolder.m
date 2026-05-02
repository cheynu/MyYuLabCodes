%==========================================================================================================================
% Gets the folder one level up.  If startingFolder is a filename with an extension it gets the containing folder and the child folder is null.
% Returns null for both if the folder does not exist, and it's not a filename either.
function [parentFolder, childFolder] = GetParentFolder(startingFolder)
parentFolder = []; % Initialize
childFolder = []; 
try
	if isfolder(startingFolder)
		[parentFolder, childFolder, ext] = fileparts(startingFolder);
		% Need to append extension for rare cases where deepest folder has a dot in the name.
		childFolder = [childFolder, ext];
	elseif isfile(startingFolder)
		% It's a filename, not a folder.  Need to change otherwise childFolder will be returned as the base file name.
		[parentFolder, childFolder, ext] = fileparts(startingFolder);
		childFolder = []; % No child folder since it's a filename, not a folder name.
	end
catch ME
	message = sprintf('Error in GetParentFolder():\n%s', ME.message);
	uiwait(msgbox(message));
end
return; % from GetParentFolder
end