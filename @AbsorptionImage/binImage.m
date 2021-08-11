function binned=binImage(image,a)
    [xSize,ySize]=size(image);
    xend=xSize-mod(xSize,a);
    yend=ySize-mod(ySize,a);
    binned=imresize(image(1:xend,1:yend),[xend/a,yend/a],'box');
    binned=int32(binned)*a^2;
end