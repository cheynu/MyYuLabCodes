classdef hbRClassGroup < handle
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明

    properties
        Meta
        rClassAll
    end

    properties (Dependent)
        Date
        saveName
        sameNeuronList
        nullSpace
        sortSpace
    end

    properties (GetAccess = private)
        SameNeuronList
        NullSpace
        SortSpace
    end

    properties (Constant)
        FeatureNameNull = ["Waveform", "AutoCorrelation", "ISI", "PSTH",...
            "Date", "xTrode", "OriIndex"];
        FeatureNameSort = ["Waveform", "AutoCorrelation", "ISI", "PSTH",...
            "OriIndex", "Index"];
    end

    methods
        function obj = hbRClassGroup(rClasses)
            arguments
                rClasses (1,:) cell
            end
            obj.rClassAll = rClasses;
            names = cellfun(@(x) string(x.BehaviorClass.Subject), rClasses, "UniformOutput", true);
            if length(unique(names)) ~= 1
                disp("rClasses must come from the same subject");
                return;
            else
                obj.Meta.Subject = unique(names);
            end
            obj.rClassSlim();
            obj.updateSameNeuronList();
        end

        function rClassSlim(obj)
            % slim rclasses by squeeze spk waveforms to mean waveform
            obj.rClassAll = cellfun(@squeezeWaveform, obj.rClassAll, "UniformOutput", false);
            function out = squeezeWaveform(in)
                for i = 1:size(in.Units.SpikeTimes, 2)
                    in.Units.SpikeTimes(i).wave = mean(in.Units.SpikeTimes(i).wave, 1);
                end
                out = in;
            end
        end

        function save(obj, options)
            arguments
                obj
                options.savePath char = pwd
                options.saveName char = obj.saveName
            end
            rClassGroup = obj;
            [~,~] = mkdir(options.savePath);
            save(fullfile(options.savePath, options.saveName), "rClassGroup");
        end

        function value = get.Date(obj)
            value = cellfun(@(x) str2double(x.BehaviorClass.Date), obj.rClassAll, "UniformOutput", true);
        end

        function value = get.saveName(obj)
            value = "RClassGroup_" + string(obj.Meta.Subject);
        end

        function value = get.sameNeuronList(obj)
            value = obj.SameNeuronList;
        end

        function value = get.nullSpace(obj)
            value = obj.NullSpace;
        end

        function value = get.sortSpace(obj)
            value = obj.SortSpace;
        end

        function [idxR, idxU] = getUnitIdx(obj, OriIndex)
            % This function return the index of rclass and unit of oriindex
            idxList = obj.sameNeuronList.OriIndex == OriIndex;
            date = obj.SameNeuronList.Date(idxList);
            idxR = find(obj.Date == date);
            iChannel = obj.SameNeuronList.Channel(idxList);
            iUnit = obj.SameNeuronList.Unit(idxList);
            spkNotes = obj.rClassAll{1,idxR}.Units.SpikeNotes;
            idxU = find(spkNotes(:,1) == iChannel & spkNotes(:,2) == iUnit);
        end

        function OriIndex = getOriIdx(obj, in)
            idxR = in(1); idxU = in(2);
            date = obj.Date(idxR);
            spkNotes = obj.rClassAll{1,idxR}.Units.SpikeNotes;
            iChannel = spkNotes(idxU,1); iUnit = spkNotes(idxU,2);
            OriIndex = find(obj.SameNeuronList.Date == date & ...
                obj.SameNeuronList.Channel == iChannel & obj.SameNeuronList.Unit == iUnit);
        end

        function out = getWaveform(obj, in, mode)
            arguments
                obj
                in (1,1) double % must be oriindex
                mode = "xtrode" % "all" for waveform in all channels (0 in different xtrode)
                                % "xtrode" for that only in this tetrode/wire/shank
            end
            [idxR, idxU] = obj.getUnitIdx(in);
            idxList = obj.SameNeuronList.OriIndex == in;
            ixTrode = obj.SameNeuronList.xTrode(idxList);
            idxxTrode = obj.rClassAll{1,idxR}.Units.ChannelMap.xtrodeMap == ixTrode;
            allwf = obj.rClassAll{1,idxR}.Units.SpikeTimes(idxU).wave_mean;
            allwf(~idxxTrode,:) = 0; % here we use 0 but nan for waveform similarity compare
            iwf = allwf(idxxTrode,:);
            % hbWang Sep/10/2023, to compare waveform between wave_clus and
            % kilosort, use peak-based waveform
            iwf_max = max(abs(iwf));
            [~,idxpeak] = max(iwf_max);
            if idxpeak <= 16
                idxwf = 1:48;
            elseif idxpeak <= 32
                idxwf = (idxpeak-15):(idxpeak+32);
            else
                idxwf = 17:64;
            end
            switch mode
                case "all"
                    out = reshape(allwf(:,idxwf)',1,[]);
                case "xtrode"
                    out = reshape(iwf(:,idxwf)',1,[]);
            end
        end

        function out = getFearture(obj, in)
            for i = 1:length(in)
                idx = obj.SameNeuronList.OriIndex == in(i);

                out(i).OriIndex = in(i);
                out(i).Index = obj.SameNeuronList.Index(idx);
                out(i).Date = obj.SameNeuronList.Date(idx);
                out(i).xTrode = obj.SameNeuronList.xTrode(idx);
                out(i).Waveform = obj.getWaveform(in(i), "xtrode");

                [idxR, idxU] = obj.getUnitIdx(in(i));
                ispkTimes = obj.rClassAll{1,idxR}.Units.SpikeTimes(idxU);
                corr = ispkTimes.AutoCorrelogram.corr;
                out(i).AutoCorrelation = corr./max(corr);
                isi_hist = histcounts(ispkTimes.ISI, 'BinLimits', [0 100], 'BinWidth', 1);
                out(i).ISI = isi_hist./sum(isi_hist);
                out(i).PSTH = ispkTimes.PSTH;
            end
        end

        function out = getSimilarity(obj, in, mode)
            arguments
                obj
                in            % must be oriindex of these units
                mode = "Null" % Null for nullspace and Sort for sortspace
            end
            switch mode
                case "Null"
                    fnames = obj.FeatureNameNull;
                case "Sort"
                    fnames = obj.FeatureNameSort;
            end
            Feature = obj.getFearture(in);
            nUnit = length(in);
            for i = 1:length(fnames)
                out.(fnames(i)) = nan(nUnit);
            end
            for i = 1:nUnit
                for j = 1:nUnit
                    if j < i
                        for k = 1:length(fnames)
                            kfname = fnames(k);
                            switch kfname
                                % case "Waveform"
                                %     iwf = Feature(i).(kfname); idxi = iwf ~= 0;
                                %     jwf = Feature(j).(kfname); idxj = jwf ~= 0;
                                %     iwf = iwf(idxi | idxj); jwf = jwf(idxi | idxj);
                                %     wfsim = calSimilarity(iwf, jwf);
                                %     out.(kfname)(i,j) = log(abs(wfsim));
                                case {"Waveform", "AutoCorrelation", "ISI", "PSTH"}
                                    out.(kfname)(i,j) = calSimilarity(Feature(i).(kfname), Feature(j).(kfname));
                                case {"Date", "xTrode", "Index"}
                                    out.(kfname)(i,j) = Feature(i).(kfname) == Feature(j).(kfname);
                                case "OriIndex"
                                    out.(kfname)(i,j) = Feature(j).(kfname) + Feature(i).(kfname)/10000;
                            end
                        end
                    end
                end
            end
        end

        function extractNullSpace(obj)
            allSU = obj.SameNeuronList(obj.SameNeuronList.Type == "Single",:); % all SingleUnits
            Similarity = obj.getSimilarity(allSU.OriIndex, "Null");
            for k = 1:length(obj.FeatureNameNull)
                kfname = obj.FeatureNameNull(k);
                ns.(kfname) = reshape(Similarity.(kfname), [] ,1);
                ns.(kfname) = ns.(kfname)(~isnan(ns.(kfname)));
            end
            idxNull = ns.Date == 1 | ns.xTrode == 0;
            ns.Waveform = ns.Waveform(idxNull);
            ns.AutoCorrelation = ns.AutoCorrelation(idxNull);
            ns.ISI = ns.ISI(idxNull);
            ns.PSTH = ns.PSTH(idxNull);
            ns.OriIndex = ns.OriIndex(idxNull);
            obj.NullSpace = ns;
        end

        function extractSortSpace(obj)
            allSU = obj.SameNeuronList(obj.SameNeuronList.Flag == 1,:); % all SortedUnits
            if ~isempty(allSU)
                Similarity = obj.getSimilarity(allSU.OriIndex, "Sort");
                for k = 1:length(obj.FeatureNameSort)
                    kfname = obj.FeatureNameSort(k);
                    space.(kfname) = reshape(Similarity.(kfname), [] ,1);
                    space.(kfname) = space.(kfname)(~isnan(space.(kfname)));
                end
                idxSame = space.Index == 1; % Sep/12/2023 remove "space.OriIndex == 0"
                sameSpace.Waveform = space.Waveform(idxSame);
                sameSpace.AutoCorrelation = space.AutoCorrelation(idxSame);
                sameSpace.ISI = space.ISI(idxSame);
                sameSpace.PSTH = space.PSTH(idxSame);
                sameSpace.OriIndex = space.OriIndex(idxSame);
                obj.SortSpace.SameSpace = sameSpace;
                
                idxDiff = space.Index == 0;
                diffSpace.Waveform = space.Waveform(idxDiff);
                diffSpace.AutoCorrelation = space.AutoCorrelation(idxDiff);
                diffSpace.ISI = space.ISI(idxDiff);
                diffSpace.PSTH = space.PSTH(idxDiff);
                diffSpace.OriIndex = space.OriIndex(idxDiff);
                obj.SortSpace.DiffSpace = diffSpace;
            else
                obj.SortSpace.SameSpace = [];
                obj.SortSpace.DiffSpace = [];
            end
        end

        %% Functions of marking same neurons
        function updateSameNeuronList(obj, in)
            arguments
                obj
                in = []
            end
            if ~isempty(in)
                obj.SameNeuronList = in;
            else
                disp("No input, just list all neurons");
                names = []; dates = []; tasks = []; xtrodes = []; channel = []; unit = []; type = [];
                for i = 1:length(obj.rClassAll)
                    irClass = obj.rClassAll{i};
                    ispkNotes = irClass.Units.SpikeNotes;
                    channel = [channel; ispkNotes(:,1)]; %#ok<*AGROW>
                    unit = [unit; ispkNotes(:,2)];
                    type = [type; ispkNotes(:,3)];
                    nUnits = size(ispkNotes, 1);
                    names = [names; repmat(string(irClass.BehaviorClass.Subject), nUnits, 1)];
                    dates = [dates; repmat(str2double(irClass.BehaviorClass.Date), nUnits, 1)];
                    tasks = [tasks; repmat(string(irClass.Meta(1).Protocol), nUnits, 1)];
                    xtrodes = [xtrodes; arrayfun(@(x) irClass.Units.ChannelMap.xtrodeMap(x), ispkNotes(:,1))];
                end
                type = arrayfun(@getTypeName, type);
                index = 1:length(type);
                num = ones(length(type),1);
                flag = zeros(length(type),1);
                obj.SameNeuronList = table(index', index', num, flag, names, dates, tasks, xtrodes, channel, unit, type, ...
                    'VariableNames', ["Index", "OriIndex", "SessionNum", "Flag", "Name", "Date", "Task", "xTrode", "Channel", "Unit", "Type"]);
            end
            function out = getTypeName(in)
                if in == 1
                    out = "Single";
                else
                    out = "Mua";
                end
            end
        end

        function isSame(obj, CurrentUnit, CombinedUnit)
            % This method add OriIndexUnit to CombinedIndexUnit(s)
            % Update obj.SameNeuronList and sort then
            arguments
                obj
                CurrentUnit (1,1) double % original index of target unit
                CombinedUnit (1,1) double % index of combined unit(s)
            end
            % hbWang Sep/2023: For now, we can just add later unit to combined units

            tbl = obj.SameNeuronList;
            idxCurrent = tbl.OriIndex == CurrentUnit;
            if ~any(idxCurrent)
                disp("Unit not exist: original index == "+num2str(CurrentUnit));
                return;
            end
            idxCombined = tbl.OriIndex == CombinedUnit;
            if any(idxCombined)
                CombinedIndex = tbl.Index(idxCombined);
                tbl = isSameUnit(tbl, CombinedUnit, CurrentUnit);
                tbl = obj.updateSessionNumber(tbl, CombinedIndex);
                tbl = sortrows(tbl, {'Index', 'OriIndex'}, {'ascend', 'ascend'});
                obj.SameNeuronList = tbl;
                obj.mark([CombinedUnit CurrentUnit]);
            else
                disp("Combined unit not exist: index == "+num2str(Index));
                return;
            end

            function tbl = isSameUnit(tbl, OriIndexU1, OriIndexU2)
                u1 = find(tbl.OriIndex == OriIndexU1);
                u2 = find(tbl.OriIndex == OriIndexU2);
                if tbl.xTrode(u1) ~= tbl.xTrode(u2)
                    disp("These two units are from different xTrodes!");
                    return;
                else
                    tbl.Index(u2) = tbl.Index(u1);
                end
            end
        end

        function splitUnit(obj, OriIndex)
            % This method split unit (original index == OriIndex)
            % from combined units (index == Index)
            arguments
                obj
                OriIndex
            end
            tbl = obj.SameNeuronList;
            idxTarget = tbl.OriIndex == OriIndex;
            if ~any(idxTarget)
                disp("Unit not exist: original index == "+num2str(OriIndex));
                return;
            end
            CombinedIndex = tbl.Index(idxTarget);
            idxCombined = tbl.Index == CombinedIndex;
            if sum(idxCombined) == 0
                disp("Combined unit not exist: index == "+num2str(CombinedIndex));
                return;
            elseif sum(idxCombined) == 1
                disp("Only one session for current unit!");
                return;
            else
                % reset target unit info and switch flag to false
                tbl.Index(idxTarget) = tbl.OriIndex(idxTarget);
                tbl.SessionNum(idxTarget) = 1;
                tbl = obj.updateSessionNumber(tbl, CombinedIndex);
                tbl = sortrows(tbl, {'Index', 'OriIndex'}, {'ascend', 'ascend'});
                obj.SameNeuronList = tbl;
                obj.unmark(OriIndex);
            end
        end
        
        function tbl = updateSessionNumber(~, tbl, index)
            num = sum(tbl.Index == index);
            tbl.SessionNum(tbl.Index == index) = num;
        end

        function mark(obj, OriIndex)
            for i = 1:length(OriIndex)
                obj.SameNeuronList(obj.SameNeuronList.OriIndex == OriIndex(i),:).Flag = 1;
            end
        end

        function unmark(obj, OriIndex)
            for i = 1:length(OriIndex)
                obj.SameNeuronList(obj.SameNeuronList.OriIndex == OriIndex(i),:).Flag = 0;
            end
        end
    end
end