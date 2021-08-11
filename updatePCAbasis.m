function updatePCAbasis(N)
    %UPDATEPCABASIS updates the PCA basis used for fringe canceling
    %   The last N absorption images are loaded and the "light"-shots 
    %   are used to construct a PCA basis set. If N is set to zero, the 
    %   user can load a specific set of images from a dialog form. The
    %   computed PCA basis set is saved to 'Z:\PCA.mat'

% load imageSeriesObject    
tic 
if N==0 
    images = ImageSeriesObject('imageclass','AbsorptionImageObject');
    N = length(images.imageHandles);
else
    images = ImageSeriesObject('imageclass','AbsorptionImageObject','shots',N);
end
toc


% assemble the data matrix
Xmax = length(images.imageHandles{1}.xCoordinates);
Ymax = length(images.imageHandles{1}.yCoordinates);
X = zeros(N,Xmax*Ymax);
tic
for i = 1:N
    X(i,:) = images.imageHandles{i}.light(:) - images.imageHandles{i}.darkField(:);
end
toc


% delete the ImageSeriesObject and the AbsorptionImageObjects
imageHandles = images.imageHandles;
delete(images);
for i = 1:N
    delete(imageHandles{i});
end
cleanupWorkspace('AbsorptionImageObject'); % erase variables in workspace which point to deleted AbsorptionImageObjects


% Do principle component analysis
mu = mean(X); 
tic
[W,~,variance] = princomp(X,'econ'); 
toc


% save the PCA basis
save('Z:\PCAbasis.mat','W','variance','mu'); 

end

