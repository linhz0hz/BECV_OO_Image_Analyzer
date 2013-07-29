%%experimental constants%%
BoltzmannConstant=1.3806503*10^(-23); %in SI
Mass=1.1623772*10^(-26); %in kg
Wavelength=671*10^(-9); %in m
imagingDetuning=0; %mHz
ScatteringXS=3/(2*pi)*Wavelength^2/(1+4*imagingDetuning^2/5.9^2); %in m^2
Magnification=.25;
PixelSize=6.45*10^(-6)/Magnification;       %in meters
CameraGain=13.3;    %photons per count, including quantum efficiency
TOFoffset=0;        %time to add to cicero TOF list variable in useconds
TOFscale=10^(-3);   %scale of TOF in Cicero
tic

TOFSeries=ImageSeriesObject();

dataCount = length(TOFSeries.imageHandles);

flightTime = zeros(1, dataCount);
widthX = zeros(1, dataCount);
widthY = zeros(1, dataCount);
nC = zeros(1, dataCount);
nX = zeros(1, dataCount);
nY = zeros(1, dataCount);
for i=1:dataCount
    flightTime(i)=TOFSeries.imageHandles{i}.TOF*TOFscale;
    widthX(i)=TOFSeries.imageHandles{i}.xWidth*PixelSize;
    widthY(i)=TOFSeries.imageHandles{i}.yWidth*PixelSize;
    nC(i)=TOFSeries.imageHandles{i}.nC;
    nX(i)=TOFSeries.imageHandles{i}.nX;
    nY(i)=TOFSeries.imageHandles{i}.nY;
end

temperatureX=[];
temperatureY=[];
temperatureXErr=[];
temperatureYErr=[];
averagenX=[];
averagenXErr=[];
averagenY=[];
averagenYErr=[];
averagenC=[];
averagenCErr=[];

fprintf(1,'\nCalculating Temperatures...\n');

widthXSquared = widthX.^2;
widthYSquared = widthY.^2;
flightTimeSquared = flightTime.^2;

%%
figure, plot(flightTime, nX, 'rx');
xlabel(['time (' metricPrefix(TOFscale) 's)']);
ylabel('n');
set(gcf,'WindowStyle','docked');
title('nCount');
hold on;
plot(flightTime,nY,'bo');
hold on;
plot(flightTime,nC,'g*');
legend('X','Y','Total');
grid on
hold off;

temperatureXFit=LinearModel.fit(flightTimeSquared',widthXSquared');
figure, plot(temperatureXFit);
xlabel(['time^2 (' metricPrefix(TOFscale) 's^2)']);
ylabel('width^2');
title('TOF XFit');
grid on

temperatureYFit=LinearModel.fit(flightTimeSquared',widthYSquared');
figure, plot(temperatureYFit);
xlabel(['time^2 (' metricPrefix(TOFscale) 's^2)']);
ylabel('width^2');
title('TOF YFit');
grid on

temperatureX=temperatureXFit.Coefficients{2,1}*...
    Mass/BoltzmannConstant*10^3;%*3*pi/8; %in mK;
temperatureY=temperatureYFit.Coefficients{2,1}*...
    Mass/BoltzmannConstant*10^3;%*3*pi/8; %in mK;
temperatureXErr=(temperatureXFit.Coefficients{2,2}*...
    Mass/BoltzmannConstant*10^3);%*3*pi/8);%/(2*temperatureX(i)); %in mK, del(t)=del(t^2)/2t
temperatureYErr=(temperatureYFit.Coefficients{2,2}*...
    Mass/BoltzmannConstant*10^3);%*3*pi/8);%/(2*temperatureY(i)); %in mK

averagenX=mean(nX);
averagenXErr=std(nX);
averagenY=mean(nY);
averagenYErr=std(nY);
averagenC=mean(nC);
averagenCErr=std(nC);

fprintf(1,['Tx = ',num2str(temperatureX),' ',setstr(177),' ',...
    num2str(temperatureXErr),' mK\n']);
fprintf(1,['Ty = ',num2str(temperatureY),' ',setstr(177),' ',...
    num2str(temperatureYErr),' mK\n']);
fprintf(1,['nX = ',num2str(averagenX/1e9),' ',setstr(177),' ',...
    num2str(averagenXErr/1e9),' * 10^9 atoms\n']);
fprintf(1,['nY = ',num2str(averagenY/1e9),' ',setstr(177),' ',...
    num2str(averagenYErr/1e9),' * 10^9 atoms\n']);
fprintf(1,['nC = ',num2str(averagenC/1e9),' ',setstr(177),' ',...
    num2str(averagenCErr/1e9),' * 10^9 atoms\n']);

% %%Performance Statistics%%
% fprintf(1,'Analysis Completed in ');
% fprintf(1,num2str(toc(AnalysisTime)));
% fprintf(1,' seconds.\n');