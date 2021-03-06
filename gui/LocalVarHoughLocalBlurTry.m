%% k-means + hsv correction + bwlabel based rectangle
dir1 = 'data/frames';
dir2 = 'data/eyeregions_all';
nFrames = 900;
gap = 12;
load(sprintf('%s/img%04d.mat',dir1,290));
%img = squeeze(stack(1, :, :, :));
img = imresize(frame,0.25);
imSizeOrig = size(img);
% img = img(gap:imSizeOrig(1)-gap,gap:imSizeOrig(2)-gap,:);
tSize = size(img);
dataSize = [tSize(1)*tSize(2),tSize(3)];
rowmat = repmat([1:tSize(1)]',[1,tSize(2)]);
colmat = repmat([1:tSize(2)],[tSize(1),1]);
h2 = strel('disk',3);
hh = fspecial('sobel');
data = zeros(dataSize);
datahsv = zeros(dataSize);
img2 = img;
k = 2;
% estimated radii range of eye
radii = 15:1:40;
radiiGap = 6;
fc = 0;
blankImg = uint8(255*ones(255,255));
thresh = 2.5;
varSize = 9;
fun1 = @(x) (std(x));

grp = 1;
imgCnt = 1;
prevcf = 0;
h1 = fspecial('gaussian',[15 15],3);
se = strel('disk',9);
for cf = 290:nFrames
    load(sprintf('%s/img%04d.mat',dir1,cf));
    %img = squeeze(stack(cf, :, :, :));
    imgo = frame;
    imSize = size(frame);
    img = imresize(frame,0.25);
    %     img = img(gap:imSizeOrig(1)-gap,gap:imSizeOrig(2)-gap,:);
    img = colfilt(double(img(:,:,1)),[9 9],'sliding',fun1);
    %     im = rgb2gray(img);
    tSize = size(img);
    e = edge(img, 'canny');
    h = circle_hough(e, radii, 'same', 'normalise');
    peak = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 1,'Threshold',thresh);
    
    if ~isempty(peak)
        [x, y] = circlepoints(peak(3)+radiiGap); % take more location
        currX = x+peak(1);
        currY = y+peak(2);
        
        flag = (min(currY)>=1) + (max(currY)<=tSize(1)) + (min(currX)>=1) + (max(currX)<=tSize(2));
        if flag==4
            sizeScaleY = imSize(1)/tSize(1);
            sizeScaleX = imSize(2)/tSize(2);
            currY = round(currY*sizeScaleY);
            currX = round(currX*sizeScaleX);
            currY(currY>imSize(1)) = imSize(1);
            currX(currX>imSize(2)) = imSize(2);
            Ym = min(currY);
            YM = max(currY);
            Xm = min(currX);
            XM = max(currX);
%             imco = imgo(Ym:YM,Xm:XM,:);
            imco2 = imgo;
            [~,indx] = sort(x);
            for cc = 1:length(x)
                if x(indx(cc))<0
                    if y(indx(cc))<0
                        imco2(1:currY(indx(cc)),1:currX(indx(cc)),:) = 0;
                    else
                        imco2(currY(indx(cc)):end,1:currX(indx(cc)),:) = 0;
                    end
                else
                    if y(indx(cc))<0
                        imco2(1:currY(indx(cc)),currX(indx(cc)):end,:) = 0;
                    else
                        imco2(currY(indx(cc)):end,currX(indx(cc)):end,:) = 0;
                    end
                end
            end
            imco = imco2(Ym:YM,Xm:XM,:);
            img2 = rgb2lab(uint8(imco));
            img2 = imfilter(img2(:,:,2),h1);
            maskX = img2>0.5*max(img2(:));
            maskX = imopen(maskX,se);
            imco = double(imco).*repmat(maskX,[1 1 3]);
            %imco2 = colfilt(imco(:,:,1)/sum(sum(imco(:,:,1))),[9 9],'sliding',fun1);
            %tVar = 10000000*mean(imco2(:));
            fc = fc + 1;
            if fc == 1
                prevcf = cf-1;
            end
            
            if abs(cf-prevcf)>3
                imgCnt = 1;
                grp = grp + 1;
            end
            prevcf = cf;
            imwrite(uint8(imco), sprintf('%s/Grp%03d_img%06d.png',dir2,grp,imgCnt));
%             imwrite(uint8(imco),sprintf('%s/Grp%03d_img%06d_var%s.png',dir2,grp,imgCnt,num2str(tVar)));
%           imwrite(uint8(imco),sprintf('%s/img%06d_var%s.png',dir2,cf,num2str(tVar)));
            imgCnt = imgCnt + 1;
            
            fc = fc + 1;
        end
    end
    cf
    %     pause(0.01);
end
