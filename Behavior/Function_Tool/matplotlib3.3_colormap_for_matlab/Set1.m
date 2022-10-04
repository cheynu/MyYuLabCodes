function map = Set1(N)
% MatPlotLib 3.3 配色方案
% 输入:
% N   -  定义colormap长度的整数（N>=0）；若为空，则为当前图窗colormap长度
%
% 输出:
% map -  Nx3的RGB颜色矩阵
%
% Copyright  2020   Akun
% https://zhuanlan.zhihu.com/c_1074615528869531648

if nargin<1
	N = size(get(gcf,'colormap'),1);
else
	assert(isscalar(N)&&isreal(N),'First argument must be a real numeric scalar.')
	assert(fix(N)==N&&N>=0,'First argument must be a positive integer.')
end

C = [0.894117647058824,0.121568627450980,0.149019607843137;0.192156862745098,0.498039215686275,0.717647058823529;0.286274509803922,0.682352941176471,0.290196078431373;0.584313725490196,0.305882352941177,0.619607843137255;0.960784313725490,0.498039215686275,0.133333333333333;0.956862745098039,0.925490196078431,0.172549019607843;0.647058823529412,0.337254901960784,0.152941176470588;0.933333333333333,0.517647058823530,0.709803921568628;0.603921568627451,0.600000000000000,0.603921568627451];

map = C(1+mod(0:N-1,size(C,1)),:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 制作：阿昆            %%%
% 公众号：阿昆的科研日常 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%