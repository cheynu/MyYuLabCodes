classdef GPSColor
    %GPSCOLOR 此处显示有关此类的摘要
    %   此处显示详细说明

    properties (Constant)
        % Performence
        Correct     = [108  184  48 ] / 255;
        Wrong       = [0    0    172] / 255;
        Premature   = [230  31   26 ] / 255;
        Late        = [113  113  113] / 255;
        Probe       = [160  82   45 ] / 255;
        % Port
        PortL       = [72   128  184] / 255; % 64   136  238
        PortR       = [85   160  92] / 255; % 64   238  136
        % Treatment
        Control     = [47   79   79 ] / 255;
        Treat       = [248  124  36 ] / 255;
        % FP
        FPLong      = [254  245  172] / 255;
        FPMed       = [151  210  236] / 255;
        FPShort     = [95   111  148] / 255;
        % Phase
        PhaseEarly  = [63   85   172] / 255;
        PhaseLate   = [250  75   40 ] / 255;
        % Cue
        Cue         = [240  160  40 ] / 255;
        % Filled vs. Empty
        Filled      = [.2 .2 .2];
        Empty       = [.6 .6 .6];
        % Lesion
        PreControl  = [61   59   64 ] / 255;
        LesionEarly = [255  108  34 ] / 255
        LesionExtensive = [82 92 235] / 255;
        % Contra vs. Ipsi
        Contra = [216 48 96] / 255;
        Ipsi   = [96  48 216] / 255;
        % Task paradigm
        FP = [247 182 45] / 255;
        RW = [0   152 68] / 255;
    end

    methods
        function obj = GPSColor()

        end

        function show(obj)
            figure(21); clf(21);
            set(gcf, 'unit', 'centimeters', 'position',[2 2 8 13], 'paperpositionmode', 'auto', 'color', 'w')

            uicontrol('Style', 'text', 'parent', 21, 'units', 'normalized', 'position', [0.25 0.95 0.5 0.04],...
                'string', 'Color mode', 'fontweight', 'bold', 'backgroundcolor', 'w', 'fontsize', 12);

            ha1 = axes;
            set(ha1, 'units', 'centimeters', 'position', [0.5 0.5 4 12], ...
                'nextplot', 'add', 'xcolor', 'none', 'ycolor', 'none', 'color', 'w', ...
                'ylim', [0 18], 'xlim', [0 1], 'ydir', 'reverse')            
            barh(1, 1, 0.8, 'FaceColor', obj.Correct, 'EdgeColor', 'none');
            barh(2, 1, 0.8, 'FaceColor', obj.Wrong, 'EdgeColor', 'none');
            barh(3, 1, 0.8, 'FaceColor', obj.Premature, 'EdgeColor', 'none');
            barh(4, 1, 0.8, 'FaceColor', obj.Late, 'EdgeColor', 'none');
            barh(6, 1, 0.8, 'FaceColor', obj.PortL, 'EdgeColor', 'none');
            barh(7, 1, 0.8, 'FaceColor', obj.PortR, 'EdgeColor', 'none');
            barh(9, 1, 0.8, 'FaceColor', obj.Control, 'EdgeColor', 'none');
            barh(10, 1, 0.8, 'FaceColor', obj.Treat, 'EdgeColor', 'none');
            barh(12, 1, 0.8, 'FaceColor', obj.FPShort, 'EdgeColor', 'none');
            barh(13, 1, 0.8, 'FaceColor', obj.FPMed, 'EdgeColor', 'none');
            barh(14, 1, 0.8, 'FaceColor', obj.FPLong, 'EdgeColor', 'none');
            barh(16, 1, 0.8, 'FaceColor', obj.PhaseEarly, 'EdgeColor', 'none');
            barh(17, 1, 0.8, 'FaceColor', obj.PhaseLate, 'EdgeColor', 'none');

            ha2 = axes;
            set(ha2, 'units', 'centimeters', 'position', [5 0.5 4 12], ...
                'nextplot', 'add', 'xcolor', 'none', 'ycolor', 'none', ...
                'fontsize', 12, 'color', 'w', 'ydir', 'reverse', ...
                'ylim', [0 18], 'xlim', [0 1])            
            text(0, 1, 'Correct', 'fontweight', 'bold');
            text(0, 2, 'Wrong', 'fontweight', 'bold');
            text(0, 3, 'Premature', 'fontweight', 'bold');
            text(0, 4, 'Late', 'fontweight', 'bold');
            text(0, 6, 'PortL', 'fontweight', 'bold');
            text(0, 7, 'PortR', 'fontweight', 'bold');
            text(0, 9, 'Control', 'fontweight', 'bold');
            text(0, 10, 'Treat', 'fontweight', 'bold');
            text(0, 12, 'FPShort', 'fontweight', 'bold');
            text(0, 13, 'FPMed', 'fontweight', 'bold');
            text(0, 14, 'FPLong', 'fontweight', 'bold');
            text(0, 16, 'PhaseEarly', 'fontweight', 'bold');
            text(0, 17, 'PhaseLate', 'fontweight', 'bold');
        end
    end
end

