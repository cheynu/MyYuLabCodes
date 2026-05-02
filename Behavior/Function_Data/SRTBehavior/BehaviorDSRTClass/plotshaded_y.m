function plotshaded_y(y,x,fstr, alphavar)
% hbWang, revised from plotshaded
% to plot y as coordinates

if nargin<4
    alphavar = 0.25;
end

if size(y,1)>size(y,2)
    y=y';
end
 
if size(y,1)==1 % just plot one line
    plot(y,x,fstr);
end
 
if size(y,1)==2 %plot shaded area
    px=[x,fliplr(x)]; % make closed patch
    py=[y(1,:), fliplr(y(2,:))];
    hpatch=patch(py,px,1,'FaceColor',fstr,'EdgeColor','none');
end
 
if size(y,1)==3 % also draw mean
    px=[x,fliplr(x)];
    py=[y(1,:), fliplr(y(3,:))];
    hpatch=patch(py,px,1,'FaceColor',fstr,'EdgeColor','none');
    plot(x(2,:),y,fstr);
end
 
alpha(hpatch, alphavar); % make patch transparent