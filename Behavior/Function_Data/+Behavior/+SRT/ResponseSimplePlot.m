function ResponseSimplePlot(saline_sessions, dcz_sessions, n_extract, FPs)
if nargin<4
    FPs = [500 1000 1500];
    if nargin<3
        n_extract = 50;
    end
end

nFP = length(FPs);

rootFolder = pwd;
response_all = cell(1, nFP);
response_labels = cell(1, nFP);
response_labels_grouped = cell(1, nFP);

for k =1:length(saline_sessions)
    
    session_folder = fullfile(rootFolder, saline_sessions{k});
    class_data = dir(fullfile(session_folder, 'BClass*.mat'));
    load(fullfile(session_folder, class_data.name));

    k_FP                     = obj.FP(obj.Stage==1);
    k_PressDurs         = obj.ReleaseTime(obj.Stage==1)-obj.PressTime(obj.Stage==1);
    k_PressTimes        = obj.PressTime(obj.Stage==1);
    
    for j =1:nFP
        kj_PressDurs = k_PressDurs(k_FP == FPs(j));
        if length(kj_PressDurs)>n_extract
            response_all{j} = [response_all{j} kj_PressDurs(1:n_extract)];
            label = {[num2str(k) 'c' ]};
            response_labels{j} = [response_labels{j} repmat(label, 1, n_extract)];
            response_labels_grouped{j} = [response_labels_grouped{j} 0*ones(1, n_extract)];
        else
            response_all{j}  = [response_all{j}  kj_PressDurs];
            label = {[num2str(k) 'c' ]};
            response_labels{j}  = [response_labels{j} repmat(label, 1, length(kj_PressDurs))];
            response_labels_grouped{j}  = [response_labels_grouped{j}  zeros(1, length(kj_PressDurs))];
        end
    end
    
end


for k =1:length(dcz_sessions)
    session_folder = fullfile(rootFolder, dcz_sessions{k});
    class_data = dir(fullfile(session_folder, 'BClass*.mat'));
    load(fullfile(session_folder, class_data.name));
    
    k_FP                     = obj.FP(obj.Stage==1);
    k_PressDurs         = obj.ReleaseTime(obj.Stage==1)-obj.PressTime(obj.Stage==1);
    k_PressTimes        = obj.PressTime(obj.Stage==1);
    
    for j =1:nFP
        kj_PressDurs = k_PressDurs(k_FP == FPs(j));
        if length(kj_PressDurs)>n_extract
            response_all{j} = [response_all{j} kj_PressDurs(1:n_extract)];
            label = {[num2str(k) 'd' ]};
            response_labels{j} = [response_labels{j} repmat(label, 1, n_extract)];
            response_labels_grouped{j} = [response_labels_grouped{j} 1*ones(1, n_extract)];
        else
            response_all{j}  = [response_all{j}  kj_PressDurs];
            label = {[num2str(k) 'd' ]};
            response_labels{j}  = [response_labels{j} repmat(label, 1, length(kj_PressDurs))];
            response_labels_grouped{j}  = [response_labels_grouped{j}  1*ones(1, length(kj_PressDurs))];
        end
    end

end

% Build violinplot. For mixed FPs, there are three rows
figure;
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 13], 'paperpositionmode', 'auto', 'color', 'w', 'Visible', 'on')
xnow = 2;
ynow = 1;
width  = 8;
width2 =3;
height = 3;
xnow_org = xnow;

for j =1:nFP
    xnow = xnow_org;
    ha1 = axes('units', 'centimeters', 'position', [xnow ynow width height]);
    xnow = xnow + width +.5;
    hv=violinplot(response_all{j}, response_labels{j}, 'HalfViolin','left', 'Width', 0.4);
    control_color = '#003285';
    dcz_color = '#850F8D';
    
    control_color_sahde = '#2A629A';
    dcz_color_shade = '#E49BFF';
    
    shift = 0.25;
    box_width = 0.1;
    line([0 length(hv)+.5], [obj.MixedFP(j) obj.MixedFP(j)]/1000, 'color', 'k', 'linestyle', '-.')
    
    for i =1:length(hv)
        if rem(i, 2)==1
            hv(i).ScatterPlot.MarkerFaceColor = control_color;
            hv(i).ScatterPlot.MarkerFaceAlpha = .6;
            hv(i).ViolinPlot.FaceColor = control_color_sahde;
        else
            hv(i).ScatterPlot.MarkerFaceColor = dcz_color;
            hv(i).ScatterPlot.MarkerFaceAlpha = .6;
            hv(i).ViolinPlot.FaceColor = dcz_color_shade;
        end
        
        hv(i).ScatterPlot.XData = hv(i).ScatterPlot.XData-shift;
        hv(i).ViolinPlot.XData = hv(i).ViolinPlot.XData-shift;
        
        hv(i).BoxPlot.Vertices(1) = i-box_width;
        hv(i).BoxPlot.Vertices(4) = i-box_width;
        hv(i).BoxPlot.Vertices(2) = i+box_width;
        hv(i).BoxPlot.Vertices(3) = i+box_width;
        
        hv(i).ScatterPlot.SizeData = 5;
        hv(i).MedianPlot.SizeData = 15;
        
    end
    
    set(gca, 'ylim', [-.5 .6]+FPs(j)/1000, 'xlim', [0 length(hv)+.5],'box', 'off', 'xticklabel', {'saline', 'DCZ'}, 'fontsize', 7)
    ylabel('Hold duration (s)')
    if j == nFP
        title(['Rat: ' obj.Subject ' | ' obj.Protocol])
    end
    
    line([2:2:length(hv);2:2:length(hv)]+0.25,  [-.5 .6]+FPs(j)/1000, 'color', 'r', 'linewidth', 1)
    
    ha2 = axes('units', 'centimeters', 'position', [xnow ynow width2 height]);
    ynow = ynow +height +.75;
    hv=violinplot(response_all{j}, response_labels_grouped{j}, 'HalfViolin','left', 'Width', 0.4);
    control_color = '#003285';
    dcz_color = '#850F8D';
    
    control_color_shade = '#2A629A';
    dcz_color_shade = '#E49BFF';
    
    shift = 0.2;
    box_width = 0.1;
    line([0 2.5], [obj.MixedFP(j) obj.MixedFP(j)]/1000, 'color', 'k', 'linestyle', '-.')
    
    for i =1:length(hv)
        if rem(i, 2)==1
            hv(i).ScatterPlot.MarkerFaceColor = control_color;
            hv(i).ScatterPlot.MarkerFaceAlpha = .6;
            hv(i).ViolinPlot.FaceColor = control_color_shade;
        else
            hv(i).ScatterPlot.MarkerFaceColor = dcz_color;
            hv(i).ScatterPlot.MarkerFaceAlpha = .6;
            hv(i).ViolinPlot.FaceColor = dcz_color_shade;
        end
        
        hv(i).ScatterPlot.XData = hv(i).ScatterPlot.XData-shift;
        hv(i).ViolinPlot.XData = hv(i).ViolinPlot.XData-shift;
        
        hv(i).BoxPlot.Vertices(1) = i-box_width;
        hv(i).BoxPlot.Vertices(4) = i-box_width;
        hv(i).BoxPlot.Vertices(2) = i+box_width;
        hv(i).BoxPlot.Vertices(3) = i+box_width;
        
        hv(i).ScatterPlot.SizeData = 4;
        hv(i).MedianPlot.SizeData = 15;
    end
    
    set(gca, 'ylim', [-.5 .6]+FPs(j)/1000, 'xlim', [0 2.5], 'YTickLabel', [],'box', 'off', 'xticklabel', {'saline', 'DCZ'}, 'fontsize', 7)
    
    % simple stat tests
    response_saline = response_all{j}(response_labels_grouped{j}==0);
    response_dcz = response_all{j}(response_labels_grouped{j}==1);
    
    bins = quantile(response_saline, (0:0.1:1));
    distribution_saline = histcounts(response_saline, bins);
    distribution_dcz = histcounts(response_dcz, bins);
    
    a=[distribution_saline; distribution_dcz];
    [pval, chi2stat, dof] = Chi2Test(a);
    
    text(2, FPs(j)/1000-.5+0.1, ['pval=' num2str(pval)], 'fontsize', 7);
    text(2, FPs(j)/1000-.5+0.2, ['chi2: ' num2str(chi2stat)], 'fontsize', 7);
    text(2, FPs(j)/1000-.5+0.3, ['df' num2str(dof)], 'fontsize', 7);
end

if ~exist(fullfile(rootFolder, 'Figure'), 'dir')
    mkdir(fullfile(rootFolder, 'Figure'))
end

savename = fullfile(rootFolder, 'Figure', 'inactivation_effect');
print (gcf,'-dpng', savename)
