imageID = 8507; % image width fringes
imageIDs = 8514:8564; % images used for constructing PCA basis

%imageID = 8675;
%imageIDs = 8626:8676;

%imageID = 8734;
%imageIDs = (8734-50):8734;

%imageID = 8569;
%imageIDs = 8519:8569;

%imageID = 8786;
%imageIDs = (8786-49):8786;

%imageID = 8786;
%imageIDs = 50;

%imageID = 9047;
%imageIDs = 50;

%imageID = 10521;
%imageIDs = (imageID-49):imageID;

imageID = 10721;
imageIDs = (imageID-49):imageID;

%fc = FringeCorrector(imageIDs,'DBImageIDs');

im = BECImage('image',int2str(imageID),'isFringeCorrected',false,'fringeCorrector',fc,'magnification',10);
ROI = im.roi;
imCorrected = BECImage('image',int2str(imageID),'isFringeCorrected',true,'fringeCorrector',fc,'roi',ROI,'magnification',10);

im.show(); title('Fringe correction OFF');
imCorrected.show(); title('Fringe correction ON');