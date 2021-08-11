function [fitresult, gof, MPposXORY] = SFfit(OD, roi, xory)
% clear all
% load('data11_sat.mat')
% roi=[57.691 150.188 300.57 200.47];
% %roi=[126 126 270 270];
% OD=s;
% xory=1;
xRegion = round(roi(1))+(0:round(roi(3)));
yRegion = round(roi(2))+(0:round(roi(4)));

ODroi=OD(yRegion,xRegion); %
%figure, imshow(OD)
% figure, imshow(ODroi);

%find the position and value of main peak
[val mpY]=max(ODroi,[],1);
[MainPeakAbs mpX]=max(max(ODroi,[],1));
MPY=mpY(mpX);%+round(roi(2))
MPX=mpX;%+round(roi(1))

% find width of main peak - assuming it is symmetric in x and y
% along y
yCut=smooth(ODroi(:,MPX));
yCutHalf=yCut(MPY:end);
widthMPy=find(yCutHalf<= MainPeakAbs/exp(1),1);
%along x
xCut=smooth(ODroi(MPY,:));
xCutHalf=xCut(MPX:end);
widthMPx=find(xCutHalf<= MainPeakAbs/(1.2*exp(1)),1);
widthMP=round(0.5*(widthMPx+widthMPy));

%find a window around the main peak along x and y of with dw
dw=3;
yDataPre=ODroi(:,(round(MPX-dw*widthMP):round(MPX+dw*widthMP)));
xDataPre=ODroi((round(MPY-dw*widthMP):round(MPY+dw*widthMP)),:);
%sum along each window
yData0=sum(yDataPre,2);
xData0=sum(xDataPre,1);
%make x vector centered
[val indx]=max(xData0);
xx=(1:length(xData0))-indx;
[val indy]=max(yData0);
yy=(1:length(yData0))-indy;

%find starting point for MainPeak, given xData0 and yData0
[MP indmpy]=max(yData0);
MainPeaky=MP-(0.5*mean(yData0(round(indmpy-3.1*widthMP):round(indmpy-3.0*widthMP)))+...
    +mean(yData0(round(indmpy+3.0*widthMP):round(indmpy+3.1*widthMP)))); %subtract base offset dues to Gaussian
[MP indmpx]=max(xData0);
MainPeakx=MP-(0.5*mean(xData0(round(indmpx-3.1*widthMP):round(indmpx-3.0*widthMP)))+...
    +mean(xData0(round(indmpx+3.0*widthMP):round(indmpx+3.1*widthMP)))); %subtract base offset dues to Gaussian
MainPeak=(MainPeakx+MainPeaky)/2;

%find distance between peaks in x
dxcut=min((length(xData0)-indmpx),(indmpx-1));
xCutHalf0a=xData0(indmpx:(dxcut+indmpx));
xCutHalf0b=xData0((indmpx-dxcut):(indmpx));
xCutHalf0=xCutHalf0a+flipdim(xCutHalf0b,2);

dx=diff(xCutHalf0);
dav=round(length(xData0)/30); %moving average of this length
for j=(dav+1):length(dx)
    dxav(j)=sum(dx((j-dav):j));
end
[val distancePeaksx]=max(dxav);
SatPeak1x=xCutHalf0(distancePeaksx);

%find distance between peaks in y
dycut=min((length(yData0)-indmpy),(indmpy-1));
yCutHalf0a=yData0(indmpy:(dycut+indmpy));
yCutHalf0b=yData0((indmpy-dycut):indmpy);
yCutHalf0=yCutHalf0a+flipdim(yCutHalf0b,1);

dy=diff(yCutHalf0);
dav=round(length(yData0)/30); %moving average of this length
for j=(dav+1):length(dy)
    dyav(j)=sum(dy((j-dav):j));
end
[val distancePeaksy]=max(dyav);
SatPeak1y=yCutHalf0(distancePeaksy);

% get distance between peaks based on the dimension with the largest peaks
% this is up to a sqrt 2

% select x based on xory
if xory == 0
    %use the larger peak to get distance
    if SatPeak1x>SatPeak1y
        distancePeaks=distancePeaksx; %CHECK
    end
    if SatPeak1x<SatPeak1y
        distancePeaks=round(distancePeaksy/sqrt(2)); %CHECK
    end
    SatPeak1=SatPeak1x; %mean(xCutHalf0a((distancePeaks-3):(distancePeaks+3)));
    %Select Data for fit
    [xData, yData] = prepareCurveData( xx', xData0' );
end

% select x based on xory
if xory == 1
    %use the larger peak to get distance
    if SatPeak1x>SatPeak1y
        distancePeaks=round(distancePeaksx*sqrt(2)); %CHECK
    end
    if SatPeak1x<SatPeak1y
        distancePeaks=distancePeaksy; %CHECK
    end
    SatPeak1=SatPeak1y; %mean(yCutHalf0a((distancePeaks-3):(distancePeaks+3)));
    %Select Data for fit
    [xData, yData] = prepareCurveData( yy', yData0' );
end

% Set up fittype and options.
ft = fittype( 'aMain*exp(-(x-x0)^2/(2*sMain^2))+am1*exp(-(x-x0-aL)^2/(2*sSat^2))+ap1*exp(-(x-x0+aL)^2/(2*sSat^2))+am2*exp(-(x-x0-2*aL)^2/(2*sSat^2))+ap2*exp(-(x-x0+2*aL)^2/(2*sSat^2))+am3*exp(-(x-x0-3*aL)^2/(2*sSat^2))+ap3*exp(-(x-x0+3*aL)^2/(2*sSat^2))+aGauss*exp(-(x-x0)^2/(2*sGauss^2))+bg', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.MaxFunEvals = 1000;
opts.MaxIter = 1000;

distancePeaks=abs(distancePeaks);
MainPeak=abs(MainPeak);
SatPeak1=abs(SatPeak1);
%[aGauss,aL,aMain,am1,am2,am3,ap1,ap2,ap3,bg,sGauss,sMain,sSat,x0]
opts.Lower = [0 distancePeaks/1.1 MainPeak/1.1 SatPeak1/1.1 SatPeak1/8 SatPeak1/10 SatPeak1/1.1 SatPeak1/8 SatPeak1/10 -MainPeak*10 widthMP widthMP/1.5 widthMP/1.5 -10];
opts.StartPoint = [MainPeak/10 distancePeaks MainPeak SatPeak1 SatPeak1/4 SatPeak1/8 SatPeak1 SatPeak1/4 SatPeak1/8 SatPeak1/10 length(xData)/3 widthMP widthMP 0];
opts.Upper = [MainPeak/2 distancePeaks*1.1 MainPeak*1.2 SatPeak1*1.5 SatPeak1 SatPeak1/2 SatPeak1*1.5 SatPeak1 SatPeak1/2 MainPeak/10 length(xData) widthMP*1.5 widthMP*1.5 10];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

%Extract main peak position
if xory==0
    MPposXORY=fitresult.x0+indx+round(roi(1));
end
if xory==1
    MPposXORY=fitresult.x0+indy+round(roi(2));
end

% Plot fit with data.
figure( 'Name', 'untitled fit 2' );
h = plot( fitresult, xData, yData );
legend( h, 'yData vs. yy', 'untitled fit 2', 'Location', 'NorthEast' );
% Label axes
xlabel yy
ylabel yData
grid on
end


