function map = magma(N)
% MatPlotLib 3.3 ��ɫ����
% ����:
% N   -  ����colormap���ȵ�������N>=0������Ϊ�գ���Ϊ��ǰͼ��colormap����
%
% ���:
% map -  Nx3��RGB��ɫ����
%
% Copyright  2020   Akun
% https://zhuanlan.zhihu.com/c_1074615528869531648

if nargin<1 || isempty(N)
	N = size(get(gcf,'colormap'),1);
else
	assert(isscalar(N)&&isreal(N),'First argument must be a real numeric scalar.')
end

C = [0,0,0.0117647058823529;0,0,0.0156862745098039;0,0,0.0235294117647059;0.00392156862745098,0,0.0274509803921569;0.00392156862745098,0.00392156862745098,0.0352941176470588;0.00784313725490196,0.00784313725490196,0.0509803921568627;0.00784313725490196,0.00784313725490196,0.0588235294117647;0.0117647058823529,0.0117647058823529,0.0666666666666667;0.0156862745098039,0.0117647058823529,0.0745098039215686;0.0156862745098039,0.0156862745098039,0.0823529411764706;0.0196078431372549,0.0156862745098039,0.0901960784313726;0.0235294117647059,0.0196078431372549,0.0980392156862745;0.0313725490196078,0.0235294117647059,0.113725490196078;0.0352941176470588,0.0274509803921569,0.121568627450980;0.0392156862745098,0.0274509803921569,0.133333333333333;0.0431372549019608,0.0313725490196078,0.141176470588235;0.0470588235294118,0.0352941176470588,0.149019607843137;0.0509803921568627,0.0392156862745098,0.156862745098039;0.0549019607843137,0.0392156862745098,0.168627450980392;0.0627450980392157,0.0470588235294118,0.184313725490196;0.0666666666666667,0.0470588235294118,0.192156862745098;0.0705882352941177,0.0509803921568627,0.200000000000000;0.0784313725490196,0.0509803921568627,0.207843137254902;0.0823529411764706,0.0549019607843137,0.219607843137255;0.0862745098039216,0.0549019607843137,0.227450980392157;0.0901960784313726,0.0588235294117647,0.239215686274510;0.101960784313725,0.0627450980392157,0.254901960784314;0.105882352941176,0.0627450980392157,0.266666666666667;0.109803921568627,0.0627450980392157,0.274509803921569;0.117647058823529,0.0627450980392157,0.286274509803922;0.121568627450980,0.0666666666666667,0.294117647058824;0.125490196078431,0.0666666666666667,0.301960784313725;0.133333333333333,0.0666666666666667,0.317647058823529;0.145098039215686,0.0666666666666667,0.333333333333333;0.149019607843137,0.0666666666666667,0.341176470588235;0.156862745098039,0.0666666666666667,0.349019607843137;0.164705882352941,0.0666666666666667,0.360784313725490;0.168627450980392,0.0666666666666667,0.368627450980392;0.180392156862745,0.0627450980392157,0.380392156862745;0.188235294117647,0.0627450980392157,0.396078431372549;0.196078431372549,0.0627450980392157,0.403921568627451;0.203921568627451,0.0627450980392157,0.407843137254902;0.207843137254902,0.0588235294117647,0.415686274509804;0.215686274509804,0.0588235294117647,0.423529411764706;0.223529411764706,0.0588235294117647,0.431372549019608;0.231372549019608,0.0588235294117647,0.439215686274510;0.243137254901961,0.0588235294117647,0.447058823529412;0.250980392156863,0.0588235294117647,0.450980392156863;0.258823529411765,0.0588235294117647,0.454901960784314;0.262745098039216,0.0588235294117647,0.458823529411765;0.270588235294118,0.0588235294117647,0.462745098039216;0.278431372549020,0.0588235294117647,0.466666666666667;0.286274509803922,0.0627450980392157,0.470588235294118;0.294117647058824,0.0627450980392157,0.474509803921569;0.301960784313725,0.0666666666666667,0.478431372549020;0.309803921568627,0.0666666666666667,0.482352941176471;0.313725490196078,0.0705882352941177,0.482352941176471;0.321568627450980,0.0705882352941177,0.486274509803922;0.325490196078431,0.0745098039215686,0.486274509803922;0.341176470588235,0.0784313725490196,0.490196078431373;0.345098039215686,0.0823529411764706,0.494117647058824;0.352941176470588,0.0823529411764706,0.494117647058824;0.356862745098039,0.0862745098039216,0.494117647058824;0.364705882352941,0.0901960784313726,0.494117647058824;0.368627450980392,0.0901960784313726,0.498039215686275;0.376470588235294,0.0941176470588235,0.498039215686275;0.388235294117647,0.0980392156862745,0.498039215686275;0.396078431372549,0.101960784313725,0.501960784313726;0.400000000000000,0.101960784313725,0.501960784313726;0.407843137254902,0.105882352941176,0.501960784313726;0.411764705882353,0.109803921568627,0.501960784313726;0.419607843137255,0.109803921568627,0.501960784313726;0.423529411764706,0.113725490196078,0.501960784313726;0.435294117647059,0.117647058823529,0.505882352941176;0.443137254901961,0.121568627450980,0.505882352941176;0.450980392156863,0.121568627450980,0.505882352941176;0.454901960784314,0.125490196078431,0.505882352941176;0.462745098039216,0.129411764705882,0.505882352941176;0.466666666666667,0.129411764705882,0.505882352941176;0.474509803921569,0.133333333333333,0.505882352941176;0.486274509803922,0.137254901960784,0.505882352941176;0.494117647058824,0.141176470588235,0.505882352941176;0.498039215686275,0.141176470588235,0.505882352941176;0.505882352941176,0.145098039215686,0.505882352941176;0.509803921568627,0.145098039215686,0.505882352941176;0.517647058823530,0.149019607843137,0.505882352941176;0.525490196078431,0.149019607843137,0.505882352941176;0.537254901960784,0.156862745098039,0.505882352941176;0.541176470588235,0.156862745098039,0.505882352941176;0.549019607843137,0.160784313725490,0.501960784313726;0.552941176470588,0.160784313725490,0.501960784313726;0.560784313725490,0.164705882352941,0.501960784313726;0.568627450980392,0.164705882352941,0.501960784313726;0.576470588235294,0.168627450980392,0.501960784313726;0.584313725490196,0.172549019607843,0.501960784313726;0.592156862745098,0.172549019607843,0.498039215686275;0.600000000000000,0.176470588235294,0.498039215686275;0.603921568627451,0.176470588235294,0.498039215686275;0.611764705882353,0.180392156862745,0.498039215686275;0.619607843137255,0.180392156862745,0.494117647058824;0.627450980392157,0.184313725490196,0.494117647058824;0.639215686274510,0.188235294117647,0.494117647058824;0.643137254901961,0.188235294117647,0.490196078431373;0.650980392156863,0.192156862745098,0.490196078431373;0.654901960784314,0.192156862745098,0.490196078431373;0.662745098039216,0.196078431372549,0.486274509803922;0.670588235294118,0.200000000000000,0.482352941176471;0.682352941176471,0.203921568627451,0.482352941176471;0.690196078431373,0.203921568627451,0.482352941176471;0.694117647058824,0.207843137254902,0.478431372549020;0.701960784313725,0.207843137254902,0.478431372549020;0.709803921568628,0.211764705882353,0.474509803921569;0.713725490196078,0.211764705882353,0.474509803921569;0.721568627450980,0.215686274509804,0.470588235294118;0.733333333333333,0.219607843137255,0.466666666666667;0.741176470588235,0.223529411764706,0.466666666666667;0.745098039215686,0.223529411764706,0.462745098039216;0.752941176470588,0.227450980392157,0.458823529411765;0.760784313725490,0.227450980392157,0.458823529411765;0.764705882352941,0.231372549019608,0.454901960784314;0.772549019607843,0.235294117647059,0.450980392156863;0.784313725490196,0.239215686274510,0.447058823529412;0.792156862745098,0.243137254901961,0.447058823529412;0.796078431372549,0.243137254901961,0.443137254901961;0.803921568627451,0.247058823529412,0.439215686274510;0.807843137254902,0.250980392156863,0.439215686274510;0.815686274509804,0.254901960784314,0.435294117647059;0.827450980392157,0.258823529411765,0.427450980392157;0.831372549019608,0.262745098039216,0.427450980392157;0.839215686274510,0.266666666666667,0.423529411764706;0.843137254901961,0.270588235294118,0.419607843137255;0.850980392156863,0.274509803921569,0.415686274509804;0.854901960784314,0.278431372549020,0.411764705882353;0.862745098039216,0.282352941176471,0.411764705882353;0.870588235294118,0.290196078431373,0.403921568627451;0.878431372549020,0.294117647058824,0.400000000000000;0.882352941176471,0.298039215686275,0.400000000000000;0.886274509803922,0.301960784313725,0.396078431372549;0.894117647058824,0.305882352941177,0.392156862745098;0.898039215686275,0.313725490196078,0.388235294117647;0.901960784313726,0.317647058823529,0.384313725490196;0.909803921568627,0.329411764705882,0.380392156862745;0.917647058823529,0.333333333333333,0.376470588235294;0.921568627450980,0.337254901960784,0.376470588235294;0.925490196078431,0.345098039215686,0.372549019607843;0.929411764705882,0.349019607843137,0.372549019607843;0.933333333333333,0.356862745098039,0.368627450980392;0.933333333333333,0.364705882352941,0.364705882352941;0.941176470588235,0.376470588235294,0.364705882352941;0.945098039215686,0.380392156862745,0.360784313725490;0.949019607843137,0.388235294117647,0.360784313725490;0.952941176470588,0.396078431372549,0.360784313725490;0.952941176470588,0.403921568627451,0.356862745098039;0.956862745098039,0.407843137254902,0.356862745098039;0.960784313725490,0.419607843137255,0.356862745098039;0.964705882352941,0.431372549019608,0.356862745098039;0.964705882352941,0.439215686274510,0.356862745098039;0.968627450980392,0.443137254901961,0.356862745098039;0.968627450980392,0.450980392156863,0.360784313725490;0.972549019607843,0.458823529411765,0.360784313725490;0.972549019607843,0.466666666666667,0.360784313725490;0.976470588235294,0.478431372549020,0.360784313725490;0.976470588235294,0.490196078431373,0.364705882352941;0.980392156862745,0.498039215686275,0.368627450980392;0.980392156862745,0.501960784313726,0.368627450980392;0.980392156862745,0.509803921568627,0.372549019607843;0.984313725490196,0.517647058823530,0.376470588235294;0.984313725490196,0.525490196078431,0.376470588235294;0.984313725490196,0.537254901960784,0.380392156862745;0.988235294117647,0.549019607843137,0.388235294117647;0.988235294117647,0.556862745098039,0.388235294117647;0.988235294117647,0.564705882352941,0.392156862745098;0.988235294117647,0.572549019607843,0.396078431372549;0.988235294117647,0.576470588235294,0.400000000000000;0.992156862745098,0.588235294117647,0.403921568627451;0.992156862745098,0.600000000000000,0.411764705882353;0.992156862745098,0.607843137254902,0.415686274509804;0.992156862745098,0.615686274509804,0.419607843137255;0.992156862745098,0.623529411764706,0.423529411764706;0.992156862745098,0.631372549019608,0.431372549019608;0.992156862745098,0.635294117647059,0.435294117647059;0.992156862745098,0.647058823529412,0.439215686274510;0.996078431372549,0.658823529411765,0.450980392156863;0.996078431372549,0.666666666666667,0.454901960784314;0.996078431372549,0.674509803921569,0.458823529411765;0.996078431372549,0.682352941176471,0.462745098039216;0.996078431372549,0.686274509803922,0.470588235294118;0.996078431372549,0.694117647058824,0.474509803921569;0.996078431372549,0.705882352941177,0.482352941176471;0.996078431372549,0.717647058823529,0.490196078431373;0.996078431372549,0.725490196078431,0.498039215686275;0.996078431372549,0.733333333333333,0.501960784313726;0.996078431372549,0.737254901960784,0.509803921568627;0.996078431372549,0.745098039215686,0.513725490196078;0.996078431372549,0.752941176470588,0.521568627450980;0.996078431372549,0.768627450980392,0.533333333333333;0.996078431372549,0.776470588235294,0.537254901960784;0.996078431372549,0.780392156862745,0.545098039215686;0.996078431372549,0.788235294117647,0.552941176470588;0.996078431372549,0.796078431372549,0.556862745098039;0.992156862745098,0.803921568627451,0.564705882352941;0.992156862745098,0.811764705882353,0.572549019607843;0.992156862745098,0.823529411764706,0.584313725490196;0.992156862745098,0.831372549019608,0.592156862745098;0.992156862745098,0.839215686274510,0.596078431372549;0.992156862745098,0.847058823529412,0.603921568627451;0.992156862745098,0.854901960784314,0.611764705882353;0.992156862745098,0.862745098039216,0.615686274509804;0.992156862745098,0.866666666666667,0.623529411764706;0.992156862745098,0.882352941176471,0.639215686274510;0.988235294117647,0.890196078431373,0.647058823529412;0.988235294117647,0.898039215686275,0.650980392156863;0.988235294117647,0.901960784313726,0.658823529411765;0.988235294117647,0.909803921568627,0.666666666666667;0.988235294117647,0.917647058823529,0.674509803921569;0.988235294117647,0.925490196078431,0.682352941176471;0.988235294117647,0.941176470588235,0.694117647058824;0.988235294117647,0.945098039215686,0.701960784313725;0.988235294117647,0.952941176470588,0.709803921568628;0.988235294117647,0.960784313725490,0.717647058823529;0.984313725490196,0.968627450980392,0.725490196078431;0.984313725490196,0.976470588235294,0.733333333333333;0.984313725490196,0.984313725490196,0.745098039215686;0.984313725490196,0.988235294117647,0.749019607843137];

num = size(C,1);
vec = linspace(0,num+1,N+2);
map = interp1(1:num,C,vec(2:end-1),'linear','extrap'); %...��ֵ
map = max(0,min(1,map));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
% ����������            %%%
% ���ںţ������Ŀ����ճ� %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%