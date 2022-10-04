function map = BrBG(N)
% MatPlotLib 3.3 配色方案
% 输入:
% N   -  定义colormap长度的整数（N>=0）；若为空，则为当前图窗colormap长度
%
% 输出:
% map -  Nx3的RGB颜色矩阵
%
% Copyright  2020   Akun
% https://zhuanlan.zhihu.com/c_1074615528869531648

if nargin<1 || isempty(N)
	N = size(get(gcf,'colormap'),1);
else
	assert(isscalar(N)&&isreal(N),'First argument must be a real numeric scalar.')
end

C = [0.329411764705882,0.188235294117647,0.0196078431372549;0.337254901960784,0.192156862745098,0.0196078431372549;0.345098039215686,0.196078431372549,0.0196078431372549;0.352941176470588,0.200000000000000,0.0196078431372549;0.364705882352941,0.207843137254902,0.0196078431372549;0.368627450980392,0.211764705882353,0.0196078431372549;0.388235294117647,0.223529411764706,0.0235294117647059;0.396078431372549,0.227450980392157,0.0235294117647059;0.403921568627451,0.231372549019608,0.0235294117647059;0.411764705882353,0.235294117647059,0.0235294117647059;0.423529411764706,0.243137254901961,0.0274509803921569;0.431372549019608,0.247058823529412,0.0274509803921569;0.443137254901961,0.254901960784314,0.0274509803921569;0.447058823529412,0.258823529411765,0.0274509803921569;0.466666666666667,0.266666666666667,0.0313725490196078;0.474509803921569,0.270588235294118,0.0313725490196078;0.482352941176471,0.278431372549020,0.0313725490196078;0.490196078431373,0.282352941176471,0.0313725490196078;0.498039215686275,0.286274509803922,0.0313725490196078;0.509803921568627,0.294117647058824,0.0352941176470588;0.525490196078431,0.301960784313725,0.0352941176470588;0.529411764705882,0.305882352941177,0.0352941176470588;0.541176470588235,0.313725490196078,0.0352941176470588;0.552941176470588,0.317647058823529,0.0392156862745098;0.560784313725490,0.325490196078431,0.0470588235294118;0.568627450980392,0.333333333333333,0.0509803921568627;0.580392156862745,0.345098039215686,0.0588235294117647;0.584313725490196,0.349019607843137,0.0627450980392157;0.600000000000000,0.364705882352941,0.0705882352941177;0.607843137254902,0.372549019607843,0.0784313725490196;0.615686274509804,0.380392156862745,0.0823529411764706;0.623529411764706,0.384313725490196,0.0901960784313726;0.631372549019608,0.392156862745098,0.0941176470588235;0.639215686274510,0.400000000000000,0.0980392156862745;0.654901960784314,0.415686274509804,0.109803921568627;0.658823529411765,0.419607843137255,0.109803921568627;0.670588235294118,0.431372549019608,0.121568627450980;0.678431372549020,0.439215686274510,0.125490196078431;0.686274509803922,0.443137254901961,0.133333333333333;0.694117647058824,0.450980392156863,0.137254901960784;0.701960784313725,0.458823529411765,0.141176470588235;0.709803921568628,0.466666666666667,0.149019607843137;0.725490196078431,0.482352941176471,0.156862745098039;0.733333333333333,0.490196078431373,0.164705882352941;0.741176470588235,0.498039215686275,0.168627450980392;0.749019607843137,0.505882352941176,0.176470588235294;0.752941176470588,0.513725490196078,0.188235294117647;0.756862745098039,0.525490196078431,0.200000000000000;0.764705882352941,0.537254901960784,0.215686274509804;0.768627450980392,0.545098039215686,0.223529411764706;0.776470588235294,0.564705882352941,0.247058823529412;0.780392156862745,0.572549019607843,0.258823529411765;0.788235294117647,0.584313725490196,0.274509803921569;0.792156862745098,0.592156862745098,0.286274509803922;0.796078431372549,0.603921568627451,0.298039215686275;0.800000000000000,0.615686274509804,0.309803921568627;0.811764705882353,0.635294117647059,0.333333333333333;0.811764705882353,0.639215686274510,0.337254901960784;0.819607843137255,0.654901960784314,0.360784313725490;0.827450980392157,0.662745098039216,0.372549019607843;0.831372549019608,0.674509803921569,0.384313725490196;0.835294117647059,0.682352941176471,0.396078431372549;0.839215686274510,0.694117647058824,0.407843137254902;0.847058823529412,0.701960784313725,0.419607843137255;0.854901960784314,0.725490196078431,0.447058823529412;0.858823529411765,0.733333333333333,0.458823529411765;0.866666666666667,0.745098039215686,0.470588235294118;0.870588235294118,0.752941176470588,0.482352941176471;0.874509803921569,0.760784313725490,0.494117647058824;0.878431372549020,0.768627450980392,0.505882352941176;0.886274509803922,0.776470588235294,0.521568627450980;0.886274509803922,0.780392156862745,0.525490196078431;0.890196078431373,0.792156862745098,0.549019607843137;0.894117647058824,0.796078431372549,0.556862745098039;0.898039215686275,0.803921568627451,0.568627450980392;0.901960784313726,0.807843137254902,0.580392156862745;0.905882352941177,0.815686274509804,0.592156862745098;0.909803921568627,0.819607843137255,0.600000000000000;0.917647058823529,0.831372549019608,0.623529411764706;0.917647058823529,0.835294117647059,0.627450980392157;0.925490196078431,0.843137254901961,0.643137254901961;0.925490196078431,0.850980392156863,0.654901960784314;0.929411764705882,0.854901960784314,0.666666666666667;0.933333333333333,0.862745098039216,0.678431372549020;0.937254901960784,0.866666666666667,0.690196078431373;0.941176470588235,0.874509803921569,0.698039215686275;0.949019607843137,0.886274509803922,0.721568627450980;0.952941176470588,0.890196078431373,0.729411764705882;0.956862745098039,0.898039215686275,0.741176470588235;0.960784313725490,0.901960784313726,0.752941176470588;0.964705882352941,0.909803921568627,0.764705882352941;0.960784313725490,0.909803921568627,0.768627450980392;0.960784313725490,0.913725490196078,0.780392156862745;0.960784313725490,0.913725490196078,0.784313725490196;0.960784313725490,0.917647058823529,0.800000000000000;0.960784313725490,0.921568627450980,0.807843137254902;0.960784313725490,0.921568627450980,0.815686274509804;0.960784313725490,0.925490196078431,0.827450980392157;0.960784313725490,0.925490196078431,0.831372549019608;0.960784313725490,0.929411764705882,0.839215686274510;0.960784313725490,0.933333333333333,0.854901960784314;0.960784313725490,0.933333333333333,0.858823529411765;0.960784313725490,0.937254901960784,0.870588235294118;0.960784313725490,0.937254901960784,0.878431372549020;0.960784313725490,0.941176470588235,0.886274509803922;0.960784313725490,0.941176470588235,0.894117647058824;0.960784313725490,0.945098039215686,0.905882352941177;0.960784313725490,0.945098039215686,0.909803921568627;0.960784313725490,0.949019607843137,0.925490196078431;0.960784313725490,0.952941176470588,0.933333333333333;0.960784313725490,0.952941176470588,0.941176470588235;0.960784313725490,0.956862745098039,0.949019607843137;0.960784313725490,0.956862745098039,0.956862745098039;0.956862745098039,0.956862745098039,0.956862745098039;0.945098039215686,0.952941176470588,0.952941176470588;0.941176470588235,0.952941176470588,0.952941176470588;0.925490196078431,0.952941176470588,0.949019607843137;0.921568627450980,0.949019607843137,0.945098039215686;0.913725490196078,0.949019607843137,0.941176470588235;0.901960784313726,0.945098039215686,0.941176470588235;0.898039215686275,0.945098039215686,0.937254901960784;0.890196078431373,0.941176470588235,0.937254901960784;0.878431372549020,0.941176470588235,0.929411764705882;0.874509803921569,0.937254901960784,0.929411764705882;0.862745098039216,0.937254901960784,0.925490196078431;0.854901960784314,0.933333333333333,0.921568627450980;0.850980392156863,0.933333333333333,0.921568627450980;0.835294117647059,0.929411764705882,0.917647058823529;0.831372549019608,0.929411764705882,0.917647058823529;0.827450980392157,0.929411764705882,0.913725490196078;0.815686274509804,0.925490196078431,0.909803921568627;0.807843137254902,0.921568627450980,0.905882352941177;0.800000000000000,0.921568627450980,0.901960784313726;0.792156862745098,0.917647058823529,0.901960784313726;0.784313725490196,0.917647058823529,0.898039215686275;0.780392156862745,0.917647058823529,0.898039215686275;0.756862745098039,0.905882352941177,0.886274509803922;0.752941176470588,0.905882352941177,0.882352941176471;0.733333333333333,0.898039215686275,0.874509803921569;0.725490196078431,0.894117647058824,0.866666666666667;0.713725490196078,0.890196078431373,0.862745098039216;0.694117647058824,0.882352941176471,0.854901960784314;0.690196078431373,0.878431372549020,0.850980392156863;0.678431372549020,0.874509803921569,0.847058823529412;0.658823529411765,0.866666666666667,0.835294117647059;0.650980392156863,0.862745098039216,0.831372549019608;0.635294117647059,0.858823529411765,0.823529411764706;0.627450980392157,0.854901960784314,0.819607843137255;0.615686274509804,0.847058823529412,0.811764705882353;0.592156862745098,0.839215686274510,0.803921568627451;0.588235294117647,0.839215686274510,0.800000000000000;0.580392156862745,0.835294117647059,0.796078431372549;0.560784313725490,0.827450980392157,0.784313725490196;0.549019607843137,0.823529411764706,0.780392156862745;0.537254901960784,0.815686274509804,0.772549019607843;0.525490196078431,0.811764705882353,0.768627450980392;0.517647058823530,0.807843137254902,0.764705882352941;0.505882352941176,0.803921568627451,0.756862745098039;0.482352941176471,0.788235294117647,0.745098039215686;0.478431372549020,0.784313725490196,0.741176470588235;0.458823529411765,0.772549019607843,0.729411764705882;0.447058823529412,0.764705882352941,0.721568627450980;0.435294117647059,0.756862745098039,0.713725490196078;0.415686274509804,0.745098039215686,0.701960784313725;0.411764705882353,0.741176470588235,0.698039215686275;0.403921568627451,0.733333333333333,0.690196078431373;0.380392156862745,0.713725490196078,0.674509803921569;0.368627450980392,0.705882352941177,0.666666666666667;0.356862745098039,0.698039215686275,0.658823529411765;0.345098039215686,0.690196078431373,0.650980392156863;0.333333333333333,0.682352941176471,0.643137254901961;0.309803921568627,0.666666666666667,0.627450980392157;0.301960784313725,0.658823529411765,0.623529411764706;0.298039215686275,0.654901960784314,0.619607843137255;0.274509803921569,0.639215686274510,0.603921568627451;0.262745098039216,0.631372549019608,0.596078431372549;0.250980392156863,0.623529411764706,0.588235294117647;0.235294117647059,0.611764705882353,0.576470588235294;0.227450980392157,0.607843137254902,0.572549019607843;0.207843137254902,0.592156862745098,0.560784313725490;0.196078431372549,0.584313725490196,0.552941176470588;0.192156862745098,0.580392156862745,0.549019607843137;0.180392156862745,0.568627450980392,0.537254901960784;0.172549019607843,0.560784313725490,0.529411764705882;0.164705882352941,0.552941176470588,0.521568627450980;0.152941176470588,0.541176470588235,0.509803921568627;0.149019607843137,0.537254901960784,0.505882352941176;0.141176470588235,0.529411764705882,0.498039215686275;0.125490196078431,0.513725490196078,0.482352941176471;0.117647058823529,0.505882352941176,0.474509803921569;0.109803921568627,0.498039215686275,0.466666666666667;0.101960784313725,0.494117647058824,0.462745098039216;0.0941176470588235,0.486274509803922,0.454901960784314;0.0784313725490196,0.470588235294118,0.439215686274510;0.0745098039215686,0.466666666666667,0.435294117647059;0.0705882352941177,0.462745098039216,0.431372549019608;0.0549019607843137,0.447058823529412,0.415686274509804;0.0470588235294118,0.439215686274510,0.407843137254902;0.0392156862745098,0.431372549019608,0.400000000000000;0.0274509803921569,0.419607843137255,0.388235294117647;0.0235294117647059,0.415686274509804,0.384313725490196;0.00784313725490196,0.400000000000000,0.368627450980392;0,0.396078431372549,0.364705882352941;0,0.392156862745098,0.360784313725490;0,0.380392156862745,0.349019607843137;0,0.376470588235294,0.341176470588235;0,0.368627450980392,0.333333333333333;0,0.356862745098039,0.321568627450980;0,0.352941176470588,0.317647058823529;0,0.349019607843137,0.313725490196078;0,0.337254901960784,0.298039215686275;0,0.329411764705882,0.294117647058824;0,0.325490196078431,0.286274509803922;0,0.317647058823529,0.278431372549020;0,0.309803921568627,0.270588235294118;0,0.298039215686275,0.258823529411765;0,0.290196078431373,0.250980392156863;0,0.290196078431373,0.250980392156863];

num = size(C,1);
vec = linspace(0,num+1,N+2);
map = interp1(1:num,C,vec(2:end-1),'linear','extrap'); %...插值
map = max(0,min(1,map));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 制作：阿昆            %%%
% 公众号：阿昆的科研日常 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%