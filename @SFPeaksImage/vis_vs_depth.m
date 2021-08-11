clear all
aaa=SFPeaksImage('image','11299','fingeCanceling','true');
dx= round(1*aaa.fitx.sSat) %width
dy= round(1*aaa.fity.sSat);  %height

xp1=round(aaa.MPposX - aaa.fitx.aL);
xp2=round(aaa.MPposX + aaa.fitx.aL);
yp1=round(aaa.MPposY - aaa.fity.aL);
yp2=round(aaa.MPposY + aaa.fity.aL);

xpos1=round(aaa.MPposX - aaa.fity.aL/2);  %middle points
ypos1=round(aaa.MPposY - aaa.fity.aL/sqrt(2));
xpos2=round(aaa.MPposX + aaa.fity.aL/2);
ypos2=round(aaa.MPposY + aaa.fity.aL/sqrt(2));

for j=11299:(11299+29)
    i=j-11299+1;
    %     a(i)=SFPeaksImage('image',num2str(j),'fingeCanceling','true','roi',aaa.roi,...
    %         'xsSat',aaa.fitx.sSat,'ysSat',aaa.fity.sSat,'xMPposX',aaa.MPposX,'yMPposY',aaa.MPposY,...
    %         'xaL',aaa.fitx.aL,'yaL',aaa.fity.aL).Visibility2;
    a=AbsorptionImage('image',num2str(j),'fingeCanceling','true','roi',aaa.roi);
    SatRegionSum1=sum(sum( a.opticalDensity(((xp1-dx):(xp1+dx)),((aaa.MPposY-dy):(aaa.MPposY+dy)))));
            SatRegionSum2=sum(sum( a.opticalDensity(((xp2-dx):(xp2+dx)),((aaa.MPposY-dy):(aaa.MPposY+dy)))));
            SatRegionSum3=sum(sum( a.opticalDensity(((aaa.MPposX-dx):(aaa.MPposX+dx)),((yp1-dy):(yp1+dy)))));
            SatRegionSum4=sum(sum( a.opticalDensity(((aaa.MPposX-dx):(aaa.MPposX+dx)),((yp2-dy):(yp2+dy)))));
            SatRegion=SatRegionSum1+SatRegionSum2+SatRegionSum3+SatRegionSum4;
    MinRegionSum1=sum(sum( a.opticalDensity(((xpos1-dx):(xpos1+dx)),((ypos1-dy):(ypos1+dy)))));
    MinRegionSum2=sum(sum( a.opticalDensity(((xpos1-dx):(xpos1+dx)),((ypos2-dy):(ypos2+dy)))));
    MinRegionSum3=sum(sum( a.opticalDensity(((xpos2-dx):(xpos2+dx)),((ypos1-dy):(ypos1+dy)))));
    MinRegionSum4=sum(sum( a.opticalDensity(((xpos2-dx):(xpos2+dx)),((ypos2-dy):(ypos2+dy)))));
    MinRegion=MinRegionSum1+MinRegionSum2+MinRegionSum3+MinRegionSum4;
    Visibility2(i)= (SatRegion-MinRegion)/(SatRegion+MinRegion);
end
vall=(5:33);
figure, plot(vall,Visibility(1:29),'bo'),grid on
