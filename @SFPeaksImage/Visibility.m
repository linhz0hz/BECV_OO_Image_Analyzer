clear all
load('data11_sat.mat')
roi=[57.691 150.188 300.57 200.47];
%roi=[126 126 270 270];
OD=s;
opticalDensity=OD;
xory=1;
[fitx, gof, MPposX]=SFfit(OD,roi,0);
[fity, gof, MPposY]=SFfit(OD,roi,1);

SatIntegral=( fitx.ap1+ fitx.am1)* fitx.sSat*sqrt(2*pi)+...
    ( fity.ap1+ fity.am1)* fity.sSat*sqrt(2*pi);

%define coordinates of squares [top left corner]: [x,y,width,height]
dx= 2*fitx.sSat; %width
dy= 2*fity.sSat;  %height
xpos1=MPposX - fity.aL/2;  %middle points
ypos1=MPposY - fity.aL/sqrt(2);
xpos2=MPposX + fity.aL/2;
ypos2=MPposY + fity.aL/sqrt(2);
topleft=[xpos1-dx/2, ypos1-dy/2, dx, dy];
bottomleft=[xpos1-dx/2, ypos2-dy/2, dx, dy];
topright=[xpos2-dx/2,ypos1-dy/2,dx,dy];
bottomright=[xpos2-dx/2,ypos2-dy/2,dx,dy];

MinRegionSum1=sum(sum( opticalDensity(((xpos1-dx):(xpos1+dx)),((ypos1-dy):(ypos1+dy)))));
MinRegionSum2=sum(sum( opticalDensity(((xpos1-dx):(xpos1+dx)),((ypos2-dy):(ypos2+dy)))));
MinRegionSum3=sum(sum( opticalDensity(((xpos2-dx):(xpos2+dx)),((ypos1-dy):(ypos1+dy)))));
MinRegionSum4=sum(sum( opticalDensity(((xpos2-dx):(xpos2+dx)),((ypos2-dy):(ypos2+dy)))));
MinRegion=MinRegionSum1+MinRegionSum2+MinRegionSum3+MinRegionSum4;
Vis= (SatIntegral-MinRegion)/(SatIntegral+MinRegion)


figure
imshow(OD)
hold on
rectangle('Position',topleft,'LineWidth',2,'EdgeColor','white')
rectangle('Position',bottomleft,'LineWidth',2,'EdgeColor','white')
rectangle('Position',topright,'LineWidth',2,'EdgeColor','white')
rectangle('Position',bottomright,'LineWidth',2,'EdgeColor','white')
