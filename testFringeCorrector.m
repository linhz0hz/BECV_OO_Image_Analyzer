imageID = 8594;
imageIDs = 50;

imageID = 8507; % image width fringes
imageIDs = 8514:8564; % images used for constructing PCA basis

im = AbsorptionImage('image',int2str(imageID));

atoms = double(im.atoms - im.darkField);
light = double(im.light - im.darkField);
ROI = im.roi;

fc = FringeCorrector(imageIDs,'DBImageIDs');
lightCorrected = fc.makeCorrectedImage(atoms,2);

OD = -log(double(atoms)./double(light));
ODcorrected = -log(double(atoms)./double(lightCorrected));

figure,imagesc(OD); title('Fringe correction OFF');
figure,imagesc(ODcorrected); title('Fringe correction ON');

