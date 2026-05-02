%% Parameters
rng(0);
PeriLesionNums = 940;
NarrowRange = 200;
PeriLesion = [-5:-1,1:10];
PeriLesionLabels = {'-5','','-3','','-1','','1','','3','','5','','7','','9',''};
CorrectLim = [20 100];
PrematureLim = [0 80];
RTLim = [200 800];
RTLim_PrePost = [100 1000];
HTIQRLim = [0 1200];
PDFLim = [0 6];
FontName = 'Helvetica';

set_matlab_default_CY;
%% Bilateral mPFC Lesion
manipType = 'Bilateral_mPFC_Lesion';
manipTypeShort = 'Lesion';
subFolder = '01_Bilateral_mPFC_Lesion';
LesionedRats = {
    '38'
    'Brillant'
    'Fantasy'
    'Handson'
    'Pippin'
    'Rommel'
    'Roy'
    'Smeagol'
    };

thisFolder = pwd;
thisFolderSplitted = strsplit(thisFolder, filesep);
rootIndex = find(strcmp(thisFolderSplitted, 'Results'))-1;
rootPath = fullfile(thisFolderSplitted{1:rootIndex});
anmPath = fullfile(rootPath,'ANMs');

Nrats = length(LesionedRats);
bmpfcLesionRats = cell(1,Nrats);
for i=1:Nrats
    iRatName = LesionedRats{i};
    disp(iRatName);
    tarFile = fullfile(anmPath,iRatName,subFolder,['SRTGroupClass_' iRatName '.mat']);
    disp(tarFile);
    load(tarFile);
    bmpfcLesionRats{i} = obj;
end

Lesion.OperationGroupAnalysis(bmpfcLesionRats,...
    'PlotSingleRats', 0, 'ManipType', manipType,'ManipTypeShort', manipTypeShort,...
    'PeriLesionTrialNum',PeriLesionNums, 'PeriLesionTrialNumNarrow', NarrowRange,...
    'PeriLesion',PeriLesion, 'PeriLesionLabels',PeriLesionLabels,...
    'CorrectLim',CorrectLim, 'PrematureLim',PrematureLim,'RTLim',RTLim,'RTLim_PrePost',RTLim_PrePost,...
    'HTIQRLim',HTIQRLim,'PDFLim',PDFLim,'FontName',FontName);
%% Bilateral mPFC Sham
manipType = 'Bilateral_mPFC_Sham';
manipTypeShort = 'Sham';
subFolder = '01_Bilateral_mPFC_Lesion';
LesionedRats = {
    '42'
    'Merry'
    'Novel'
    'Tyrell'
    'Wise'
    };

thisFolder = pwd;
thisFolderSplitted = strsplit(thisFolder, filesep);
rootIndex = find(strcmp(thisFolderSplitted, 'Results'))-1;
rootPath = fullfile(thisFolderSplitted{1:rootIndex});
anmPath = fullfile(rootPath,'ANMs');

Nrats = length(LesionedRats);
bmpfcLesionRats = cell(1,Nrats);
for i=1:Nrats
    iRatName = LesionedRats{i};
    disp(iRatName);
    tarFile = fullfile(anmPath,iRatName,subFolder,['SRTGroupClass_' iRatName '.mat']);
    disp(tarFile);
    load(tarFile);
    bmpfcLesionRats{i} = obj;
end

Lesion.OperationGroupAnalysis(bmpfcLesionRats,...
    'PlotSingleRats', 0, 'ManipType', manipType,'ManipTypeShort', manipTypeShort,...
    'PeriLesionTrialNum',PeriLesionNums, 'PeriLesionTrialNumNarrow', NarrowRange,...
    'PeriLesion',PeriLesion, 'PeriLesionLabels',PeriLesionLabels,...
    'CorrectLim',CorrectLim, 'PrematureLim',PrematureLim,'RTLim',RTLim,'RTLim_PrePost',RTLim_PrePost,...
    'HTIQRLim',HTIQRLim,'PDFLim',PDFLim,'FontName',FontName);