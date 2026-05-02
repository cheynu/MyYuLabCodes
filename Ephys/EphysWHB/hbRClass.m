classdef hbRClass < handle
    % hbRClass
    % hbWang, Apr 2023
    % Class of r array of one session ephys data

    properties
        Meta
        Behavior
        Units
        BehaviorClass
        BehaviorClassAll
    end

    properties (Dependent)
        saveName
        paramsTable     % Show obj.Params in table, set specific params through @set.paramsPress
        paramsPopTable  % Show obj.ParamsPop in table
        EventTimes_raw
        EventTimes      % Show obj.sortedBeh, update with @obj.behEvents
        PSTHs           % Show obj.EPhys, update with @obj.calEphys
        PSTHPop         % Show obj.EphysPop, update with @obj.calEphysPop
        PSTHWarped      % Show obj.EphysWarped, update with @obj.warpEphys
    end

    properties (GetAccess = private)
        rawBeh          % unsorted behavior events
        sortedBeh       % sorted behavior events
        warpedBeh       % warped behavior medians
        Ephys           % Ephys data of all units (psth, ts, raster, t-raster)
        EphysPop        % Ephys population data (merged psth and firing rate)
        EphysWarped     % Ephys population data warped
        Params          % Parameters used in @jpsth
        ParamsPop       % Parameters of population analysis
        ParamsPopAuto   % ParamsPop for autoshaping
        fpList
    end

    properties (Constant, GetAccess = private)

        event_auto     = ["Trigger" "Reward"]
        event_lever    = ["Press" "Release" "Reward"]
        event_srt      = ["Press" "Release" "Reward" "NonReward" "Trigger"]

        paramsRowNames = ["pre" "post" "binwidth"]
        params_default = ["Press"     1500 2500 20;
                          "Release"   1500 1000 20;
                          "Reward"    1500 2500 20;
                          "NonReward" 1500 2500 20;
                          "Trigger"    500 1000 20]
        params_auto    = ["Trigger"   2000 3000 20;
                          "Reward"    1500 2500 20]
        params_pop     = ["Press"     1000  500 20;
                          "Trigger"    300  300 20;
                          "Release"    300  300 20;
                          "Reward"     700 1800 20]
        params_pop_auto= ["Trigger"   2000 2000 20;
                          "Reward"    1000 1800 20] % Trigger - for autoshaping

        fpList_default = [1500 750]
        outcomeNames   = ["Cor", "Pre", "Late"]
        sortRaster_default = true
    end

    methods
        %% BASIC methods
        function obj = hbRClass(r)
            arguments
                r struct
            end
            obj.Meta = r.Meta;
            obj.Behavior = r.Behavior;
            obj.BehaviorClass = r.BehaviorClass;
            if isfield(r, "BehaviorClassAll")
                obj.BehaviorClassAll = r.BehaviorClassAll;
            else
                obj.BehaviorClassAll = [];
            end
            obj.Units = r.Units;

            % Initialize: params of PSTH
            obj.setParams2Default;
        end

        function save(obj, options)
            arguments
                obj
                options.savePath char = pwd
                options.saveName char = obj.saveName
            end
            rClass = obj;
            [~,~] = mkdir(options.savePath);
            save(fullfile(options.savePath, options.saveName), "rClass");
        end

        function setChannelMap(obj, options)
            arguments
                obj
                options.xtrode string{mustBeMember(options.xtrode, ["MWA", "Tetrode", "Silicon"])} = "Silicon"
                options.map = []
                options.nChannel = []
            end
            chanmap = obj.Units.ChannelMap;
            if ~isempty(options.nChannel)
                chanmap.Nchannels = options.nChannel;
            end
            if ~isempty(options.map)
                if numel(options.map) == chanmap.Nchannels
                    chanmap.xtrodeMap = options.map;
                else
                    error("Please check 'Map' element number")
                end
            else
                switch options.xtrode
                    case "MWA"  % 1 channel per xtrode, 8 ch per row
                        xmap = chanmap.chanMap;
                        n = double(chanmap.Nchannels/8);
                        xcoor = ones(1,n).*(1:8)'*size(obj.Units.SpikeTimes(1).wave_mean,2);
                        ycoor = (1:n).*ones(1,8)'*400;
                    case "Tetrode"  % 4 channels per xtrode and 4 ch per row
                        xmap = zeros(chanmap.Nchannels, 1);
                        n = double(chanmap.Nchannels/4);
                        for i = 1:chanmap.Nchannels
                            if ismember(mod(i,8), [1 3 5 7])
                                xmap(i) = floor((double(i)-1)/8)*2+1;
                            else
                                xmap(i) = floor((double(i)-1)/8)*2+2;
                            end
                        end
                        xcoor = ones(1,n/2).*[1 1 2 2 3 3 4 4]'*size(obj.Units.SpikeTimes(1).wave_mean,2);
                        ycoor = xmap*400;
                    case "Silicon"  % 16 channels per shank, and 8 ch per row
                        n = double(chanmap.Nchannels/16);
                        imap = ones(1,16); imap2 = ones(1,8);
                        xmap = (1:n).*imap';
                        xcoor = ones(1,2*n).*(1:8)'*size(obj.Units.SpikeTimes(1).wave_mean,2);
                        ycoor = (1:2*n).*imap2'*400;
                end
                obj.Units.ChannelMap.xtrodeMap  = reshape(xmap,  [], chanmap.Nchannels);
                obj.Units.ChannelMap.xcoor2plot = reshape(xcoor, [], chanmap.Nchannels);
                obj.Units.ChannelMap.ycoor2plot = reshape(ycoor, [], chanmap.Nchannels);
            end
        end

        %% GET methods
        % Get obj.saveName (Dependent)
        function value = get.saveName(obj)
            value = "RClass_" + string(obj.BehaviorClass.Subject) + "_" + ...
                num2str(obj.BehaviorClass.Date) + "_" + string(obj.Meta(1).Protocol);
        end

        % Get obj.params (Dependent)
        function value = get.paramsTable(obj)
            % Show params of Press/Release/Reward/Trigger in table
            if obj.BehaviorClass.Task == "AutoShaping"
                value = [struct2table(obj.Params.Trigger);
                         struct2table(obj.Params.Reward)];
                value.Properties.RowNames = obj.params_auto(:,1);                
            else
                value = [struct2table(obj.Params.Press);
                         struct2table(obj.Params.Release);
                         struct2table(obj.Params.Reward);
                         struct2table(obj.Params.BadPoke);
                         struct2table(obj.Params.Trigger)];
                value.Properties.RowNames = obj.params_default(:,1);
            end
        end

        function value = get.paramsPopTable(obj)
            % Show params of Press/Release/Reward/Trigger in table
            if isfield(obj.BehaviorClass, "Task") && obj.BehaviorClass.Task == "AutoShaping"
                value = [struct2table(obj.ParamsPop.Trigger);
                         struct2table(obj.ParamsPop.Reward)];
                value.Properties.RowNames = obj.params_pop_auto(:,1);
            else
                value = [struct2table(obj.ParamsPop.Press);
                         struct2table(obj.ParamsPop.Trigger);
                         struct2table(obj.ParamsPop.Release);
                         struct2table(obj.ParamsPop.Reward)];
                value.Properties.RowNames = obj.params_pop(:,1);
            end
        end

        % Get PSTHs, waveforms and autocorrelations
        function value = get.PSTHs(obj)
            value = obj.Ephys;
        end

        function value = get.PSTHPop(obj)
            value = obj.EphysPop;
        end

        function value = get.PSTHWarped(obj)
            value = obj.EphysWarped;
        end


        function value = get.EventTimes(obj)
            value = obj.sortedBeh;
        end
     
        function value = get.EventTimes_raw(obj)
            value = obj.rawBeh;
        end

        %% SET methods
        function set.paramsTable(obj, in)
            for i = 1:height(in)
                fname = in(i,1);
                fvalue = in(i,2:end);
                for j = 1:length(fvalue)
                    obj.Params.(fname).(obj.paramsRowNames(j)) = str2double(fvalue(j));
                end
            end
            if isfield(obj.Params, "NonReward") && isfield(obj.Params, "Reward")
                obj.Params.BadPoke = obj.Params.Reward;
            end
        end
        
        function set.paramsPopTable(obj, in)
            for i = 1:height(in)
                fname = in(i,1);
                fvalue = in(i,2:end);
                for j = 1:length(fvalue)
                    obj.ParamsPop.(fname).(obj.paramsRowNames(j)) = str2double(fvalue(j));
                end
            end
        end

        function set.fpList(obj, in)
            arguments
                obj
                in  (1,:) double
            end
            obj.fpList = in;
        end

        function obj = setParams2Default(obj)
            
            if isfield(obj.BehaviorClass, "Task") && obj.BehaviorClass.Task == "AutoShaping"
                obj.paramsTable = obj.params_auto;
                obj.paramsPopTable = obj.params_pop_auto;
            else
                obj.paramsTable = obj.params_default;
                obj.paramsPopTable = obj.params_pop;
            end
            obj.fpList = obj.fpList_default;
        end

        %% Calculate timings of BR behavior events
        function behEvents(obj)

            b = obj.Behavior;
            tPress   = b.EventTimings(b.EventMarkers == find(b.Labels == "LeverPress"));
            tRelease = b.EventTimings(b.EventMarkers == find(b.Labels == "LeverRelease"));
            tPoke    = b.EventTimings(b.EventMarkers == find(b.Labels == "PokeOnset"));
%             tBadPoke = b.EventTimings(b.EventMarkers == find(b.Labels == "BadPokeOnset"));
            tTriggerAll = b.EventTimings(b.EventMarkers == find(b.Labels == "Trigger"));
            tRewardAll  = b.EventTimings(b.EventMarkers == find(b.Labels == "ValveOnset"));

            disp("Current session press number: "+num2str(length(tPress)));
            
            tPressCorAll   = tPress(b.CorrectIndex);
            tReleaseCorAll = tRelease(b.CorrectIndex);
            tHoldCorAll    = tReleaseCorAll - tPressCorAll;
            fpCorAll       = b.Foreperiods(b.CorrectIndex);
            rtCorAll       = tHoldCorAll - fpCorAll';
            
            tPressPreAll   = tPress(b.PrematureIndex);
            tReleasePreAll = tRelease(b.PrematureIndex);
            tHoldPreAll    = tReleasePreAll - tPressPreAll;
            fpPreAll       = b.Foreperiods(b.PrematureIndex);
            rtPreAll       = tHoldPreAll - fpPreAll';

            tPressLateAll   = tPress(b.LateIndex);
            tReleaseLateAll = tRelease(b.LateIndex);
            tHoldLateAll    = tReleaseLateAll - tPressLateAll;
            fpLateAll       = b.Foreperiods(b.LateIndex);
            rtLateAll       = tHoldLateAll - fpLateAll';

            % Find correct trials in tTrigger
            idxTrigger = sort([b.CorrectIndex b.LateIndex]);
            [~, idxTrigger_Cor]  = intersect(idxTrigger, b.CorrectIndex);
            [~, idxTrigger_Late] = intersect(idxTrigger, b.LateIndex);
            % 
            % tPress_TriggerCor  = tPress(idxTrigger_Cor);
            % tPress_TriggerLate = tPress(idxTrigger_Late);

            tTriggerCorAll  = tTriggerAll(idxTrigger_Cor);
            tTriggerLateAll = tTriggerAll(idxTrigger_Late);

            for i = 1:length(tRewardAll)
                dt = tRewardAll(i) - tReleaseCorAll;
                idx = find(dt<3000 & dt>0, 1, "first"); % get reward time and correspond fp
                if isempty(idx)
                    fpRewAll(i) = NaN;
                    tRewardAll(i) = NaN;

                else
                    fpRewAll(i) = tTriggerCorAll(idx) - tPressCorAll(idx);
                end
            end
            fpRewAll = round(fpRewAll(~isnan(fpRewAll)));
            tRewardAll = tRewardAll(~isnan(tRewardAll));

            if isfield(obj.Meta, "Protocol")
                switch obj.Meta(1).Protocol
                    case {"Wait1", "Wait2", "Wait"}
                        isWait = 1;
                        fpIdx.Cor1 = fpCorAll == 1500;
                        fpIdx.Cor2 = fpCorAll <  1500;
                        fpIdx.Pre1 = fpPreAll == 1500;
                        fpIdx.Pre2 = fpPreAll <  1500;
                        fpIdx.Late1 = fpLateAll == 1500;
                        fpIdx.Late2 = fpLateAll <  1500;
                        fpIdx.Rew1 = fpRewAll == 1500;
                        fpIdx.Rew2 = fpRewAll <  1500;
                    case {"2FPs", "3FPs"}
                        isWait = 0;
                        for i = 1:length(obj.fpList)
                            fpIdx.("Cor"+num2str(i))  = fpCorAll  == obj.fpList(i);
                            fpIdx.("Pre"+num2str(i))  = fpPreAll  == obj.fpList(i);
                            fpIdx.("Late"+num2str(i)) = fpLateAll == obj.fpList(i);
                            fpIdx.("Rew"+num2str(i))  = fpRewAll  == obj.fpList(i);
                        end
                end
            else
                isWait = 0;
                for i = 1:length(obj.fpList)
                    fpIdx.("Cor"+num2str(i))  = fpCorAll  == obj.fpList(i);
                    fpIdx.("Pre"+num2str(i))  = fpPreAll  == obj.fpList(i);
                    fpIdx.("Late"+num2str(i)) = fpLateAll == obj.fpList(i);
                    fpIdx.("Rew"+num2str(i))  = fpRewAll  == obj.fpList(i);
                end
            end

            % Divide tPress / tRelease by FPs
            for i = 1:length(fieldnames(fpIdx))/3
                iCor = fpIdx.("Cor"+num2str(i));
                tPressCor{i}   = tPressCorAll(iCor);   %#ok<*AGROW> 
                tReleaseCor{i} = tReleaseCorAll(iCor);
                tHoldCor{i}    = tHoldCorAll(iCor);
                fpCor{i}       = fpCorAll(iCor);
                rtCor{i}       = rtCorAll(iCor);
                
                iPre = fpIdx.("Pre"+num2str(i));
                tPressPre{i}   = tPressPreAll(iPre);
                tReleasePre{i} = tReleasePreAll(iPre);
                tHoldPre{i}    = tHoldPreAll(iPre);
                fpPre{i}       = fpPreAll(iPre);
                rtPre{i}       = rtPreAll(iPre);

                iLate = fpIdx.("Late"+num2str(i));
                tPressLate{i}   = tPressLateAll(iLate);
                tReleaseLate{i} = tReleaseLateAll(iLate);
                tHoldLate{i}    = tHoldLateAll(iLate);
                fpLate{i}       = fpLateAll(iLate);
                rtLate{i}       = rtLateAll(iLate);

                tTriggerCor{i}  = tTriggerCorAll(iCor);
                tTriggerLate{i} = tTriggerLateAll(iLate);

                iRew = fpIdx.("Rew"+num2str(i));
                tReward{i} = tRewardAll(iRew);
                    
                ptrp{i} = [];
                for j = 1:length(tPressCor{i})
                    jtReward = tReward{i}(find(tReward{i}>tReleaseCor{i}(j),1,"first"));
                    % remove trials that correct but no reward
                    % which is, reward time follows release, and no press between these events
                    if ~isempty(jtReward) && isempty(find(tPressCor{i}>tReleaseCor{i}(j) & tPressCor{i}<jtReward, 1))
                        ptrp{i} = [ptrp{i}; [tPressCor{i}(j) tTriggerCor{i}(j) tReleaseCor{i}(j) jtReward]];
                    end
                end
            end

            % Get tMove and sort tReward by tMove
            tMoveRewardAll = zeros(length(tRewardAll),1);
            for i = 1:length(tMoveRewardAll)
                itReward = tRewardAll(i);
                itReleaseCor = tReleaseCorAll(find(itReward>tReleaseCorAll, 1, "last"));
                tMoveRewardAll(i) = itReward - itReleaseCor;
            end
            [tMoveRewardAll_Sorted, idx] = sort(tMoveRewardAll, 'descend');
            tRewardAll_Sorted = tRewardAll(idx);

            for i = 1:length(tReward)
                itReward = tReward{i}; % different fps
                itReleaseCor = tReleaseCor{i};
                tMoveReward{i} = zeros(length(itReward),1);
                for j = 1:length(itReward)
                    ijtReward = itReward(j);
                    ijtReleaseCor = itReleaseCor(find(ijtReward>itReleaseCor, 1, "last"));
                    tMoveReward{i}(j) = ijtReward - ijtReleaseCor;
                end
                [tMoveReward_Sorted{i}, idx] = sort(tMoveReward{i}, 'descend');
                tReward_Sorted{i} = tReward{i}(idx);
                medianMT(i) = median(tMoveReward{i});
            end

            % tBadPoke and tMoveBad
            tNonRewardAll = [];
            tMoveNonRewardAll = [];
            tReleaseError = sort([tReleasePreAll; tReleaseLateAll]); 
            for i = 1:length(tReleaseError)
                itPoke  = tPoke(find(tPoke>tReleaseError(i), 1, 'first'));   % first poke after a bad release    
                itPress = tPress(find(tPress>tReleaseError(i), 1, 'first'));
                if ~isempty(itPoke) && ~isempty(itPress) && itPoke < itPress
                  tNonRewardAll = [tNonRewardAll; itPoke];
                  tMoveNonRewardAll = [tMoveNonRewardAll; itPoke-tReleaseError(i)];
                end
            end
            [tMoveNonRewardAll_Sorted, idx] = sort(tMoveNonRewardAll, 'descend');
            tNonRewardAll_Sorted = tNonRewardAll(idx);

            % Sort
            for i = 1:length(tPressCor)
                if isempty(ptrp{i})
                    medianRTCor(i) = NaN;
                    medianMT(i) = NaN;
                else
                    medianRTCor(i) = median(ptrp{i}(:,3)-ptrp{i}(:,2));
                    medianMT(i)    = median(ptrp{i}(:,4)-ptrp{i}(:,3));
                end
                if isWait && i == 2 % Wait < 1500ms, sort by FPs
                    % [rtCor_Sorted{i}, idx] = sort(rtCor{i}, 'ascend');
                    % fpCor_Sorted{i}        = fpCor{i}(idx);
                    [fpCor_Sorted{i}, idx] = sort(fpCor{i}, 'descend');
                    rtCor_Sorted{i}        = rtCor{i}(idx);
                    tPressCor_Sorted{i}   = tPressCor{i}(idx);
                    tReleaseCor_Sorted{i} = tReleaseCor{i}(idx);
                    tTriggerCor_Sorted{i} = tTriggerCor{i}(idx);
                    tHoldCor_Sorted{i}    = tHoldCor{i}(idx);

                    [fpPre_Sorted{i}, idx] = sort(fpPre{i}, 'descend');
                    tPressPre_Sorted{i}   = tPressPre{i}(idx);
                    tReleasePre_Sorted{i} = tReleasePre{i}(idx);
                    tHoldPre_Sorted{i}    = tHoldPre{i}(idx);
    
                    [fpLate_Sorted{i}, idx] = sort(fpLate{i}, 'descend');
                    tPressLate_Sorted{i}   = tPressLate{i}(idx);
                    tReleaseLate_Sorted{i} = tReleaseLate{i}(idx);
                    tTriggerLate_Sorted{i} = tTriggerLate{i}(idx);
                    tHoldLate_Sorted{i}    = tHoldLate{i}(idx);

                    % warp
                    templates(i,:) = [0 1000 1000+medianRTCor(i) 1000+medianRTCor(i)+medianMT(i)];

                else % multi FPs or Wait 1500ms, sort by holdtime
                    [rtCor_Sorted{i}, idx] = sort(rtCor{i}, 'descend');
                    %[tHoldCor_Sorted{i}, idx] = sort(tHoldCor{i}, 'descend');
                    tPressCor_Sorted{i}   = tPressCor{i}(idx);
                    tReleaseCor_Sorted{i} = tReleaseCor{i}(idx);
                    tTriggerCor_Sorted{i} = tTriggerCor{i}(idx);
                    fpCor_Sorted{i}       = fpCor{i}(idx);
                    tHoldCor_Sorted{i}    = tHoldCor{i}(idx);
    
                    [tHoldPre_Sorted{i}, idx] = sort(tHoldPre{i}, 'descend');
                    tPressPre_Sorted{i}   = tPressPre{i}(idx);
                    tReleasePre_Sorted{i} = tReleasePre{i}(idx);
                    fpPre_Sorted{i}       = fpPre{i}(idx);
    
                    [tHoldLate_Sorted{i}, idx] = sort(tHoldLate{i}, 'descend');
                    tPressLate_Sorted{i}   = tPressLate{i}(idx);
                    tReleaseLate_Sorted{i} = tReleaseLate{i}(idx);
                    tTriggerLate_Sorted{i} = tTriggerLate{i}(idx);
                    fpLate_Sorted{i}       = fpLate{i}(idx);

                    % warp
                    templates(i,:) = [0 obj.fpList(i) obj.fpList(i)+medianRTCor(i) obj.fpList(i)+medianRTCor(i)+medianMT(i)];
                end
            end

            % Add to obj.Unsorted
            obj.rawBeh = struct;
            obj.rawBeh.tPressCor    = tPressCor;
            obj.rawBeh.tReleaseCor  = tReleaseCor;
            obj.rawBeh.tTriggerCor  = tTriggerCor;
            obj.rawBeh.tHoldCor     = tHoldCor;
            obj.rawBeh.fpCor        = fpCor;

            obj.rawBeh.tPressPre    = tPressPre;
            obj.rawBeh.tReleasePre  = tReleasePre;
            obj.rawBeh.tHoldPre     = tHoldPre;
            obj.rawBeh.fpPre        = fpPre;

            obj.rawBeh.tPressLate   = tPressLate;
            obj.rawBeh.tReleaseLate = tReleaseLate;
            obj.rawBeh.tTriggerLate = tTriggerLate;
            obj.rawBeh.tHoldLate    = tHoldLate;
            obj.rawBeh.fpLate       = fpLate;

            obj.rawBeh.tReward      = tReward;
            obj.rawBeh.tRewardAll   = tRewardAll;
            obj.rawBeh.tNonReward   = tNonRewardAll;

            obj.rawBeh.tMoveReward    = tMoveReward;
            obj.rawBeh.tMoveRewardAll = tMoveRewardAll;
            obj.rawBeh.tMoveNonReward = tMoveNonRewardAll;

            obj.rawBeh.tPoke        = tPoke;

            obj.rawBeh.tPressCorAll    = tPressCorAll;
            obj.rawBeh.tReleaseCorAll  = tReleaseCorAll;
            obj.rawBeh.tPressPreAll    = tPressPreAll;
            obj.rawBeh.tReleasePreAll  = tReleasePreAll;            
            obj.rawBeh.tPressLateAll   = tPressLateAll;
            obj.rawBeh.tReleaseLateAll = tReleaseLateAll;
            obj.rawBeh.tTriggerCorAll  = tTriggerCorAll;
            obj.rawBeh.tTriggerLateAll = tTriggerLateAll;

            % Add to obj.Sorted
            obj.sortedBeh = struct;
            obj.sortedBeh.tPressCor   = tPressCor_Sorted;
            obj.sortedBeh.tReleaseCor = tReleaseCor_Sorted;
            obj.sortedBeh.tTriggerCor = tTriggerCor_Sorted;
            obj.sortedBeh.tHoldCor    = tHoldCor_Sorted;
            obj.sortedBeh.fpCor       = fpCor_Sorted;
            obj.sortedBeh.rtCor       = rtCor_Sorted;

            obj.sortedBeh.tPressPre   = tPressPre_Sorted;
            obj.sortedBeh.tReleasePre = tReleasePre_Sorted;
            obj.sortedBeh.tHoldPre    = tHoldPre_Sorted;
            obj.sortedBeh.fpPre       = fpPre_Sorted;

            obj.sortedBeh.tPressLate   = tPressLate_Sorted;
            obj.sortedBeh.tReleaseLate = tReleaseLate_Sorted;
            obj.sortedBeh.tTriggerLate = tTriggerLate_Sorted;
            obj.sortedBeh.tHoldLate    = tHoldLate_Sorted;
            obj.sortedBeh.fpLate       = fpLate_Sorted;

            obj.sortedBeh.tReward      = tReward_Sorted;
            obj.sortedBeh.tRewardAll   = tRewardAll_Sorted;
            obj.sortedBeh.tNonReward   = tNonRewardAll_Sorted;

            obj.sortedBeh.tMoveReward    = tMoveReward_Sorted;
            obj.sortedBeh.tMoveRewardAll = tMoveRewardAll_Sorted;
            obj.sortedBeh.tMoveNonReward = tMoveNonRewardAll_Sorted;

            % Actually, these are unsorted (just to calculate PSTH)
            obj.sortedBeh.tPoke           = tPoke;
            obj.sortedBeh.tPressCorAll    = tPressCorAll;
            obj.sortedBeh.tReleaseCorAll  = tReleaseCorAll;
            obj.sortedBeh.tPressPreAll    = tPressPreAll;
            obj.sortedBeh.tReleasePreAll  = tReleasePreAll;            
            obj.sortedBeh.tPressLateAll   = tPressLateAll;
            obj.sortedBeh.tReleaseLateAll = tReleaseLateAll;
            obj.sortedBeh.tTriggerCorAll  = tTriggerCorAll;
            obj.sortedBeh.tTriggerLateAll = tTriggerLateAll;

            % Add median of RT and MT (for warping)
            obj.warpedBeh.medianRTCor  = medianRTCor;
            % obj.warpedBeh.medianRTPre  = medianRTPre;
            % obj.warpedBeh.medianRTLate = medianRTLate;
            obj.warpedBeh.medianMT     = medianMT;
            obj.warpedBeh.templates    = templates;
            obj.warpedBeh.ptrp         = ptrp;

        end
        
        % AutoShaping & LeverPress/Release style
        function behEvents_Naive(obj)

            b = obj.Behavior;
            tPoke    = b.EventTimings(b.EventMarkers == find(b.Labels == "PokeOnset"));
            tTrigger = b.EventTimings(b.EventMarkers == find(b.Labels == "Trigger"));
            tReward  = b.EventTimings(b.EventMarkers == find(b.Labels == "ValveOnset"));
            disp("Current session reward number: "+num2str(length(tReward)));

            switch obj.BehaviorClass.Task
                case "AutoShaping"
                    isLever = false;
                    tEvent4Move = tTrigger;
                case {"LeverPress", "LeverRelease"}
                    isLever = true;
                    tPress   = b.EventTimings(b.EventMarkers == find(b.Labels == "LeverPress"));
                    tRelease = b.EventTimings(b.EventMarkers == find(b.Labels == "LeverRelease"));
                    tHold = tPress - tRelease;
                    tEvent4Move = tRelease;
            end

            % Get tMove and sort tReward by tMove
            tMoveReward = []; tTriggerNew = []; tRewardNew = [];
            for i = 1:length(tReward)
                itReward = tReward(i);
                idx = find(itReward>tEvent4Move, 1, "last");
                if ~isempty(idx)
                    itEvent = tEvent4Move(idx);
                    tMoveReward = [tMoveReward; itReward-itEvent];
                    if ~isLever
                        tRewardNew  = [tRewardNew; itReward];
                        tTriggerNew = [tTriggerNew; itEvent];
                    end
                end
            end
            [tMoveReward_Sorted, idx] = sort(tMoveReward, 'descend');
            if isLever
                tReward_Sorted = tReward(idx);
            else
                tReward_Sorted = tRewardNew(idx);
                tTrigger_Sorted = tTriggerNew(idx);
                tReward = tRewardNew;
                tTrigger = tTriggerNew;
            end

            % Sort press & release time by press duration
            if isLever
                [tHold_Sorted, idx] = sort(tHold, 'descend');
                tPress_Sorted = tPress(idx);
                tRelease_Sorted = tRelease(idx);
                tTrigger_Sorted = tTrigger(idx);
            end

            % Add to obj.Unsorted
            obj.rawBeh = struct;
            obj.rawBeh.tReward   = tReward;
            % obj.rawBeh.tNonReward   = tNonRewardAll;
            obj.rawBeh.tMoveReward = tMoveReward;
            % obj.rawBeh.tMoveNonReward = tMoveNonRewardAll;
            obj.rawBeh.tPoke     = tPoke;
            obj.rawBeh.tTrigger  = tTrigger;

            % Add to obj.Sorted
            obj.sortedBeh = struct;
            obj.sortedBeh.tReward = tReward_Sorted;
            % obj.sortedBeh.tNonReward   = tNonRewardAll_Sorted;
            obj.sortedBeh.tMoveReward = tMoveReward_Sorted;
            % obj.sortedBeh.tMoveNonReward = tMoveNonRewardAll_Sorted;
            obj.sortedBeh.tPoke    = tPoke;
            obj.sortedBeh.tTrigger = tTrigger_Sorted;

            if isLever
                obj.rawBeh.tHold    = tHold;
                obj.rawBeh.tPress   = tPress;
                obj.rawBeh.tRelease = tRelease;
                obj.sortedBeh.tPress   = tHold_Sorted;
                obj.sortedBeh.tPress   = tPress_Sorted;
                obj.sortedBeh.tRelease = tRelease_Sorted;
            end
        end

        %% Calculate Ephys data of unit(s)
        function [ras, tras] = calEphys(obj, idxUnit, options)
            arguments
                obj
                idxUnit
                options.sortRaster = obj.sortRaster_default
                options.saveRaster = false
                options.gaussian   = 5
                options.setparams  = true
            end

            if isempty(obj.rawBeh)
                disp("**** Calculate behEvents de novo ****");
                obj.behEvents;
            end
            if options.sortRaster
                b = obj.sortedBeh;
            else
                b = obj.rawBeh;
            end
            if options.setparams
                obj.setParams2Default;
            end
            op = obj.Params;
            opp = obj.ParamsPop;
            nFP = length(b.tPressCor);
            allEvents = obj.event_srt;
            Outcomes = obj.outcomeNames;

            iwUnit = obj.Units.SpikeTimes(idxUnit).wave;
            itUnit = obj.Units.SpikeTimes(idxUnit).timings;
            rp = struct; sp = struct; ts = struct; ras = struct; tras = struct; stat = struct;
            for i = 1:length(allEvents)
                % PSTHs
                iEvent = allEvents(i);
                switch iEvent
                    case {"Press", "Release", "Trigger"}
                        for j = 1:length(Outcomes)
                            if iEvent ~= "Trigger" || Outcomes(j) ~= "Pre"  % No "Pre" outcome for Triggers
                                fname = iEvent + Outcomes(j);
                                [rp.(fname+"All"), ts.(iEvent)] = jpsth(itUnit, b.("t"+fname+"All"), op.(iEvent));
                                sp.(fname+"All") = smoothdata(rp.(fname+"All"), "gaussian", options.gaussian);
                                for k = 1:nFP
                                    [rp.(fname){k}, ~, ras.(fname){k}, tras.(fname){k}] = jpsth(itUnit, b.("t"+fname){k}, op.(iEvent));
                                    sp.(fname){k} = smoothdata(rp.(fname){k}, "gaussian", options.gaussian);
                                    if Outcomes(j) == "Cor" && ~isempty(ras.(fname){k}) % iEvent ~= "Trigger" &&
                                        % idxPop = tras.(fname){k} >= -opp.(iEvent).pre & tras.(fname){k} <= opp.(iEvent).post;
                                        % stat.(fname){k} = ExamineTaskResponsive(tras.(fname){k}(idxPop), ras.(fname){k}(idxPop,:));
                                        stat.(fname){k} = ExamineTaskResponsive(tras.(fname){k}, ras.(fname){k});
                                    else
                                        stat.(fname){k} = [];
                                    end
                                end
                            end
                        end
                    case {"Reward"}
                        fname = iEvent;
                        [rp.(fname+"All"), ts.(iEvent), ras.(fname+"All"){1}, tras.(fname+"All"){1}] = jpsth(itUnit, b.("t"+fname+"All"), op.(iEvent));
                        sp.(fname+"All") = smoothdata(rp.(fname+"All"), "gaussian", options.gaussian);
                        for k = 1:nFP
                            [rp.(fname){k}, ~, ras.(fname){k}, tras.(fname){k}] = jpsth(itUnit, b.("t"+fname){k}, op.(iEvent));
                            sp.(fname){k} = smoothdata(rp.(fname){k}, "gaussian", options.gaussian);
                            if ~isempty(ras.(fname){k})
                                % idxPop = tras.(fname){k} >= -opp.(iEvent).pre & tras.(fname){k} <= opp.(iEvent).post;
                                % stat.(fname){k} = ExamineTaskResponsive(tras.(fname){k}(idxPop), ras.(fname){k}(idxPop,:));
                                stat.(fname){k} = ExamineTaskResponsive(tras.(fname){k}, ras.(fname){k});
                            else
                                stat.(fname){k} = [];
                            end
                        end
                    case {"NonReward"}
                        [rp.(iEvent), ts.(iEvent), ras.(iEvent){1}, tras.(iEvent){1}] = jpsth(itUnit, b.("t"+iEvent), op.(iEvent));
                        sp.(iEvent) = smoothdata(rp.(iEvent), "gaussian", options.gaussian);
                end
            end
            % Waveforms 
            mwf = mean(iwUnit, 1);

            % Autocorrelogram
            tempitu = round(itUnit);
            itUnit2 = zeros(1, max(tempitu));
            itUnit2(tempitu) = 1;
            [corr, lags] = xcorr(itUnit2, 100);
            corr(lags == 0) = 0;
            
            % Inter-Spike-Interval (ISI)
            isi = diff(itUnit);

            % Save obj.Ephys
            obj.Ephys.rawPSTH{idxUnit}      = rp;
            obj.Ephys.smoothedPSTH{idxUnit} = sp;
            obj.Ephys.tsPSTH{idxUnit}       = ts;
            obj.Ephys.SpikeWave{idxUnit}    = mwf;
            obj.Ephys.StatOut{idxUnit}      = stat;
            obj.Ephys.ISI{idxUnit}          = isi;
            obj.Ephys.AutoCorrelogram{idxUnit}.corr = corr;
            obj.Ephys.AutoCorrelogram{idxUnit}.lags = lags;
            if options.saveRaster
                obj.Ephys.Raster{idxUnit}  = ras;
                obj.Ephys.tRaster{idxUnit} = tras;
            end
        end

        function [ras, tras] = calEphysNaive(obj, idxUnit, options)
            arguments
                obj
                idxUnit
                options.sortRaster = obj.sortRaster_default
                options.saveRaster = false
            end

            if isempty(obj.rawBeh)
                disp("**** Calculate behEvents de novo ****");
                obj.behEvents_Naive;
            end

            if options.sortRaster
                b = obj.sortedBeh;
            else
                b = obj.rawBeh;
            end

            op = obj.Params;
            opp = obj.ParamsPop;

            switch obj.BehaviorClass.Task
                case "AutoShaping"
                    allEvents = obj.event_auto;
                case {"LeverPress", "LeverRelease"}
                    allEvents = obj.event_lever;
            end

            iwUnit = obj.Units.SpikeTimes(idxUnit).wave;
            itUnit = obj.Units.SpikeTimes(idxUnit).timings;
            rp = struct; sp = struct; ts = struct; ras = struct; tras = struct; stat = struct;
            for i = 1:length(allEvents)
                % PSTHs
                iEvent = allEvents(i);
                fname = iEvent; 
                [rp.(fname), ts.(iEvent), ras.(fname), tras.(fname)] = ...
                    jpsth(itUnit, b.("t"+fname), op.(iEvent));
                sp.(fname) = smoothdata(rp.(fname), "gaussian", 5);
                if ~isempty(ras.(fname))
                    idxPop = tras.(fname) >= -opp.(iEvent).pre & tras.(fname) <= opp.(iEvent).post;
                    stat.(fname) = ExamineTaskResponsive(tras.(fname)(idxPop), ras.(fname)(idxPop,:));
                else
                    stat.(fname) = [];
                end
            end
            % Waveforms 
            mwf = mean(iwUnit, 1);

            % Autocorrelogram
            tempitu = round(itUnit);
            itUnit2 = zeros(1, max(tempitu));
            itUnit2(tempitu) = 1;
            [corr, lags] = xcorr(itUnit2, 100);
            corr(lags == 0) = 0;
            
            % Inter-Spike-Interval (ISI)
            isi = diff(itUnit);

            % Save obj.EPhys
            obj.Ephys.rawPSTH{idxUnit}      = rp;
            obj.Ephys.smoothedPSTH{idxUnit} = sp;
            obj.Ephys.tsPSTH{idxUnit}       = ts;
            obj.Ephys.SpikeWave{idxUnit}    = mwf;
            obj.Ephys.StatOut{idxUnit}      = stat;
            obj.Ephys.ISI{idxUnit}          = isi;
            obj.Ephys.AutoCorrelogram{idxUnit}.corr = corr;
            obj.Ephys.AutoCorrelogram{idxUnit}.lags = lags;
            if options.saveRaster
                obj.Ephys.Raster{idxUnit}  = ras;
                obj.Ephys.tRaster{idxUnit} = tras;
            end
        end

        % Calculate all units' ephys data by calling @obj.calEphys
        function calEphys4All(obj, options)
            arguments
                obj
                options.sortRaster = obj.sortRaster_default
                options.saveRaster = false
                options.save2Path  = true
            end
            allUnits = size(obj.Units.SpikeNotes, 1);
            for i = 1:allUnits
                disp("Calculating Ephys data: Unit #"+num2str(i)+" of "+num2str(allUnits));
                if isfield(obj.BehaviorClass, "Task") && ismember(obj.BehaviorClass.Task, ["AutoShaping","Press","Release"])
                    obj.calEphysNaive(i, "sortRaster", options.sortRaster, "saveRaster", options.saveRaster);
                else
                    obj.calEphys(i, "sortRaster", options.sortRaster, "saveRaster", options.saveRaster);
                end
            end
            if options.save2Path
                PSTH = obj.Ephys;
                tempname = "PSTH_"+string(obj.BehaviorClass.Subject) + "_" + ...
                num2str(obj.BehaviorClass.Date) + "_" + string(obj.Meta(1).Protocol + ".mat");
                save(tempname, "PSTH");
                obj.save();
            end
        end

        function warpEphys(obj, idxUnit, options)
            arguments
                obj
                idxUnit
                options.pre  = 2      % raster: from 2 sec before press
                options.post = 3      % raster: until 3 sec after reward
                options.post_keep = 2 % raster: keep 2 sec after reward
                options.template = [] % template for warping, if is empty, calculate from beh.
                options.dt   = 1      % ms
            end
            if isempty(obj.warpedBeh)
                obj.behEvents;
            end
            tPre = options.pre*1000; tPost = options.post*1000; % in ms
            b = obj.rawBeh; wb = obj.warpedBeh;
            nFP = length(b.tPressCor);
            itUnit = obj.Units.SpikeTimes(idxUnit).timings;
            sdf_warped.Data = cell(1, nFP);

            if isempty(options.template)
                templates = wb.templates;
            else
                templates = options.template;
            end

            for i = 1:nFP
                % template for iFP to warp
                itemp = templates(i,:);
                itarget = 0:options.dt:itemp(end);
                itarget_part{1} = itarget(itarget>=itemp(1) & itarget<itemp(2)); % fp
                itarget_part{2} = itarget(itarget>=itemp(2) & itarget<itemp(3)); % rt
                itarget_part{3} = itarget(itarget>=itemp(3) & itarget<itemp(4)); % mt

                iseq  = wb.ptrp{i};
                itSpikes = {}; isdf = {}; isdf_warped = [];
                for j = 1:length(iseq) % each "complete" trial under iFP
                    jtPress   = iseq(j,1); jtReward  = iseq(j,4);
                    tStart = jtPress - tPre;
                    tEnd   = jtReward + tPost;
                    jDuration = round(tEnd-tStart);
                    jtSpikes  = itUnit(itUnit>=tStart & itUnit<=tEnd);
                    itSpikes  = [itSpikes {jtSpikes}];

                    tsdf = (0:jDuration-1)-tPre;
                    spkmat = zeros(1, jDuration);
                    if ~isempty(jtSpikes)
                        jtSpikes = jtSpikes - (jtPress);
                        [~, idxSpikes] = intersect(round(tsdf), round(jtSpikes));
                        spkmat(idxSpikes) = 1;
                    end
                    jsdf = sdf(tsdf/1000, spkmat, 20)'; % sdf(tspk, spkin, kernel_width)
                    isdf = [isdf [tsdf; jsdf]];

                    % warp each trial
                    jt = iseq(j,:)-iseq(j,1); % normalize press time to 0
                    jsdf_warped = jsdf(tsdf<jt(1)); % time before press: not warped
                    for k = 1:3 % warp
                        ksdf_warp = jsdf(tsdf>=jt(k) & tsdf<jt(k+1));
                        tsdf_warp = tsdf(tsdf>=jt(k) & tsdf<jt(k+1));
                        ksdf_warped = warp_sdf(tsdf_warp, ksdf_warp, itarget_part{k});
                        jsdf_warped = [jsdf_warped ksdf_warped];
                    end
                    % time after reward: not warped
                    jsdf_warped = [jsdf_warped jsdf(tsdf>=jt(end) & tsdf<(jt(end)+options.post_keep*1000))];
                    isdf_warped = [isdf_warped; jsdf_warped];
                end
                sdf_warped.Data{i} = isdf_warped;
                if isempty(isdf_warped)
                    sdf_warped.ci95{i} = [];
                    sdf_warped.mean{i} = [];
                else
                    sdf_warped.ci95{i} = bootci(1000, @mean, isdf_warped);
                    sdf_warped.mean{i} = mean(isdf_warped, 1);
                end
            end
            obj.EphysWarped.sdf{idxUnit}      = sdf_warped.Data;
            obj.EphysWarped.sdf_mean{idxUnit} = sdf_warped.mean;
            obj.EphysWarped.sdf_ci{idxUnit}   = sdf_warped.ci95;
            obj.EphysWarped.template          = templates;
            obj.EphysWarped.PrePost           = [options.pre options.post options.post_keep];
        end

        % warp all units' ephys
        function warpEphys4All(obj, options)
            arguments
                obj
                options.dt   = 1      % ms
                options.pre  = 2      % raster: from 2 sec before press
                options.post = 3      % raster: until 3 sec after reward
                options.post_keep = 2 % raster: keep 2 sec after reward
                options.template = [] % template for warping, if is empty, calculate from beh.
            end

            allUnits = size(obj.Units.SpikeNotes, 1);
            for i = 1:allUnits
                disp("Warping Ephys data: Unit #"+num2str(i)+" of "+num2str(allUnits));
                obj.warpEphys(i, "template", options.template, "pre", options.pre, ...
                    "post", options.post, "post_keep", options.post_keep, "dt", options.dt);
            end

        end

        %% PSTH PLOT methods
        function plotPSTH(obj, idxUnit, options)
            % Plot PSTH for one unit
            arguments
                obj
                % idxUnit: index of target unit, could be:
                % (1,1) double: index in all units
                % (1,2) double: [Channel, Unit] (e.g, [12 2] ~ Ch12 Unit2)
                idxUnit             double
                options.FRrange     double = []     % Firing Rate range, default is max+2
                options.printName   string = ""     % postfix of PSTH figure savename
                options.sortRaster logical = obj.sortRaster_default
                                                    % use sorted or unsorted raster data
                options.printPNG   logical = true   % print .PNG (default = true)
                options.printFIG   logical = false  % print .FIG (default = false)
                options.printEPS   logical = false  % print .EPS (default = false)
                options.printPDF   logical = false  % print .PDF (default = false)
            end

            if length(idxUnit) == 2
                idxUnit = find(obj.Units.SpikeNotes(:,1) == idxUnit(1) ...
                    & obj.Units.SpikeNotes(:,2) == idxUnit(2));
                if isempty(idxUnit)
                    disp("#### No such unit found, please check your UnitID input ####");
                    return;
                end
            end
            if idxUnit > length(obj.Units.SpikeTimes)
                disp("#### That is all you have ####");
                return;
            end

            [ras, tras] = obj.calEphys(idxUnit, "sortRaster", options.sortRaster);
            PSTH = obj.Ephys.smoothedPSTH{idxUnit};
            tsPSTH = obj.Ephys.tsPSTH{idxUnit};
            if options.sortRaster
                b = obj.sortedBeh;
            else
                b = obj.rawBeh;
            end
            op = obj.Params;
            allEvents = obj.params_default(:, 1);

            % if size(ras.RewardAll{1},2) > 50
            %     randidx = randperm(size(ras.RewardAll{1},2), 50);
            %     randidx = sort(randidx);
            %     ras.RewardAll{1} = ras.RewardAll{1}(:, randidx);
            %     b.tRewardAll = b.tRewardAll(randidx);
            %     b.tMoveReward = b.tMoveReward(randidx);
            % end

            numReward = cellfun(@(x) size(x,2), ras.Reward, "UniformOutput", true);
            % numReward = round(50*numReward/sum(numReward));
            for i = 1:length(ras.Reward)
                if size(ras.Reward{i},2) > numReward(i)
                    randidx = randperm(size(ras.Reward{i},2), numReward(i));
                    randidx = sort(randidx);
                    ras.Reward{i} = ras.Reward{i}(:, randidx);
                    b.tReward{i} = b.tReward{i}(randidx);
                    b.tMoveReward{i} = b.tMoveReward{i}(randidx);
                end
            end

            nFP   = size(b.tPressCor, 2);
            nCor  = length(b.tPressCorAll);
            nPre  = length(b.tPressPreAll);
            nLate = length(b.tPressLateAll);
            nReward    = length(b.tRewardAll);
            nNonReward = length(b.tNonReward);

            nCorFP = cellfun(@(x) length(x), b.tPressCor);

            % c: struct of colors
            cTab20c = tab20c(20);  cGreys = cTab20c(17:20,:); 
            cTab10  = tab10(10);   
            cBlue   = cTab10(1,:); cGreen = cTab10(3,:); cRed  = cTab10(4,:);
            cPurple = cTab10(5,:); cPink  = cTab10(7,:); cCyan = cTab10(10,:);
            
            c = struct("Cor", flip(Blues(nFP)), "Pre", flip(Oranges(nFP)), "Late", cGreys(1:nFP,:), ...
                       "Press", cGreen, "Release", cPurple, "Poke", cRed, "Trigger", cPink, ...
                       "Reward", repmat([0 0 0],nFP,1), "NonReward", cGreys(2,:), ...
                       "Wave", cGreys(3,:), "MeanWave", 'k');
            % w: struct of linewidths
            w = struct("PSTH", 0.4*flip(1:nFP)+0.8, "Spike", 1.2, "Align", 1,...
                       "Event", 1.5, "Wave", 0.8, "MeanWave", 2);
            % fondSize: struct of fontsizes
            fontSize = struct("Axes", 7, "Label", 7, "Title", 9);
            tickLen  = [0.02 0.01];

            % Set Firing Rate range
            FRrange = options.FRrange;
            if isempty(options.FRrange)
                for i = 1:nFP
                    if nCorFP(i) >= 10
                        iFRrange = max([PSTH.PressCor{i} PSTH.ReleaseCor{i}]);
                        FRrange = max([FRrange, iFRrange]);
                    end
                end
                FRrange = max([FRrange max(PSTH.RewardAll)]);
                if nPre >= 10
                    FRrange = max([FRrange max(PSTH.PressPreAll) max(PSTH.ReleasePreAll)]);
                end
                if nLate >= 10
                    FRrange = max([FRrange max(PSTH.PressLateAll) max(PSTH.ReleaseLateAll)]);
                end
                FRrange = FRrange + 2;
            end

            % Set x/yLim, x/yTick and x/yTickLabel
            for i = 1:length(allEvents)
                iEvent = allEvents(i);
                xLim.(iEvent)  = [-op.(iEvent).pre   op.(iEvent).post];
                xTick.(iEvent) = [-op.(iEvent).pre 0 op.(iEvent).post];
                xTickLabel.(iEvent) = string(xTick.(iEvent));
            end

            if FRrange <= 10
                yTick.PSTH = 0:2:10;
            elseif FRrange <= 20
                yTick.PSTH = 0:5:20;
            else
                yTick.PSTH = 0:20:100;
            end
            yLim.PSTH = [0 FRrange]; yTickLabel.PSTH   = string(yTick.PSTH);
            yTick.Raster = 0:20:200; yTickLabel.Raster = string(yTick.Raster);

            % Build map (coordinates) of Fig
            xStart = 1.2; yStart = 1.2; xgap = 1; ygap = 0.5;
            xPSTH.Press     = size(tras.PressCor{1}, 2)/1000;
            xPSTH.Release   = size(tras.ReleaseCor{1}, 2)/1000;
            xPSTH.Reward    = size(tras.RewardAll{1}, 2)/1000;
            xPSTH.NonReward = size(tras.NonReward{1}, 2)/1000;
            xPSTH.Trigger   = size(tras.TriggerCor{1}, 2)/1000;
            if xPSTH.Trigger < 3
                xPSTH.Trigger = 3;
            end
            yPSTH = 2; yAct = 0.7*xPSTH.Trigger; yInfo = 2*ygap;
            xRaster = xPSTH; yRaster = 0.04;  % height of one trial in raster plot
            xWave = (xPSTH.Reward-xgap)/2; yWave = xWave*0.8; % Size of Unit Info
            
            xmap = [xStart, ...                            % column 1: Press;
                    xStart+xPSTH.Press+xgap];              % column 2: Release;
            xmap(3) = xmap(2) + xgap*2 + xPSTH.Release;    % column 3: Reward/BadPoke;
            xmap(4) = xmap(3) + xgap*2 + xPSTH.Reward;     % column 4: Trigger;
            ymap = [yStart, ...                            % row -1: Correct PSTH;
                    yStart+yPSTH+ygap, ...                 % row -2: Error PSTH;
                    yStart+yPSTH+ygap*2 + yPSTH];          % row -3: Correct raster
            ymap(4) = ymap(3) + ygap*1 + yRaster*nCor;     % row -4: Premature raster
            ymap(5) = ymap(4) + ygap*1 + yRaster*nPre;     % row -5: Late raster
            ymap(6) = ymap(5) + ygap/2 + yRaster*nLate;    % row -6: A/B

            ymap2 = [yStart, ...                                % row -1: Reward/BadPoke PSTH
                     yStart+yPSTH+ygap];                        % row -2: Reward raster
            ymap2(3) = ymap2(2) + ygap*1 + yRaster*nReward;     % row -3: BadPoke raster
            ymap2(4) = ymap2(3) + ygap/2 + yRaster*nNonReward;  % row -4: C
            ymap2(5) = ymap2(4) + ygap*3 + yInfo;               % row -5: Waveform and AutoCorr
            ymap2(6) = ymap2(5) + ygap*2 + yWave;               % row -6: Waveform in all channels
            ymap2(7) = ymap2(6) + ygap*1 + yWave;               % row -7: E

            ymap3 = [yStart, ...                              % row -1: Trigger PSTH
                     yStart+yPSTH+ygap];                      % row -2: TriggerCor raster
            ymap3(3) = ymap3(2) + ygap*1 + yRaster*nCor;      % row -3: TriggerLate raster
            ymap3(4) = ymap3(3) + ygap/2 + yRaster*nLate;     % row -4: D
            ymap3(5) = ymap3(4) + ygap*3 + yInfo;             % row -5: Activity vs. time
            ymap3(6) = ymap3(5) + ygap/2 + yAct;              % row -6: F

            if ymap(6) - ymap2(7) <= ygap
                xUnitInfo = xmap(1); yUnitInfo = ymap(6) + ygap/2 + yInfo;
                xText = xRaster.Press + xRaster.Release + xgap;
                figSize = [2 2 xmap(end)+xgap+xPSTH.Trigger ymap(end)+ygap*2+yInfo*3];
            elseif ymap(6) - ymap2(7) <= 2*yInfo
                xUnitInfo = xmap(3); yUnitInfo = ymap2(7) + ygap/2 + yInfo;
                xText = xRaster.Reward;
                figSize = [2 2 xmap(end)+xgap+xPSTH.Trigger ymap2(end)+ygap*2+yInfo*3];
            else
                xUnitInfo = xmap(3); 
                yUnitInfo = ymap2(7) + (ymap(6)-ymap2(7))/2 + ygap/2;
                xText = xRaster.Reward;
                figSize = [2 2 xmap(end)+xgap+xPSTH.Trigger ymap(end)+ygap+yInfo];
            end

            Fig = figure(1); clf(Fig, "reset");
            set(Fig, 'name', 'PSTH', 'unit', 'centimeters', 'color', 'w', ...
                'position', figSize, 'paperpositionmode', 'auto');

            % PSTH | Correct - Press
            ha11 = axes;
            set(ha11, 'Units', 'centimeters', 'Position', [xmap(1) ymap(1) xPSTH.Press yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Press, 'XTick', xTick.Press, 'XTickLabel', xTickLabel.Press, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel("Time from press (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("Spikes/sec", "FontSize", fontSize.Label, "FontName", "Arial");
            for i = 1:nFP
                if nCorFP(i) >= 10
                    plot(tsPSTH.Press, PSTH.PressCor{i}, 'color', c.Cor(i,:), 'linewidth', w.PSTH(i));
                end
            end
            line([0 0], yLim.PSTH, 'color', c.Press, 'linewidth', w.Align);

            % PSTH | Error - Press
            ha12 = axes;
            set(ha12, 'Units', 'centimeters', 'Position', [xmap(1) ymap(2) xPSTH.Press yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Press, 'XTick', xTick.Press, 'XTickLabel', {}, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            ylabel("Spikes/sec", "FontSize", fontSize.Label, "FontName", "Arial");
            if nPre >= 10
                plot(tsPSTH.Press, PSTH.PressPreAll,  'color', c.Pre(1,:),  'linewidth', w.PSTH(1));
            end
            if nLate >= 10
                plot(tsPSTH.Press, PSTH.PressLateAll, 'color', c.Late(1,:), 'linewidth', w.PSTH(1));
            end
            line([0 0], yLim.PSTH, 'color', c.Press, 'linewidth', w.Align);

            % PSTH | Correct - Release
            ha21 = axes;
            set(ha21, 'Units', 'centimeters', 'Position', [xmap(2) ymap(1) xPSTH.Release yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Release, 'XTick', xTick.Release, 'XTickLabel', xTickLabel.Release, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel("Time from release (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
            for i = 1:nFP
                if nCorFP(i) >= 10
                    plot(tsPSTH.Release, PSTH.ReleaseCor{i}, 'color', c.Cor(i,:), 'linewidth', w.PSTH(i));
                end
            end
            line([0 0], yLim.PSTH, 'color', c.Release, 'linewidth', w.Align);

            % PSTH | Error - Release
            ha22 = axes;
            set(ha22, 'Units', 'centimeters', 'Position', [xmap(2) ymap(2) xPSTH.Release yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Release, 'XTick', xTick.Release, 'XTickLabel', {}, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            if nPre >= 10
                plot(tsPSTH.Release, PSTH.ReleasePreAll,  'color', c.Pre(1,:),  'linewidth', w.PSTH(1));
            end
            if nLate >= 10
                plot(tsPSTH.Release, PSTH.ReleaseLateAll, 'color', c.Late(1,:), 'linewidth', w.PSTH(1));
            end
            line([0 0], yLim.PSTH, 'color', c.Release, 'linewidth', w.Align);

            % Raster | Correct - Press
            ha13 = axes;
            set(ha13, 'Units', 'centimeters', 'Position', [xmap(1) ymap(3) xRaster.Press yRaster*nCor], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Press, 'XTick', xTick.Press, 'XTickLabel', {}, ...
                'YLim', [0 nCor], 'YTick', yTick.Raster, 'YTickLabel', yTickLabel.Raster, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            title("Correct", "Color", c.Cor(1,:), "Rotation", 90, ...
                "Units", "centimeters", "Position", [-xgap/3 yRaster*nCor/2], ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
            plotRaster(ras.PressCor, tras.PressCor, b, "Press", "Cor");

            % Raster | Correct - Release
            ha23 = axes;
            set(ha23, 'Units', 'centimeters', 'Position', [xmap(2) ymap(3) xRaster.Release yRaster*nCor], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Release, 'XTick', xTick.Release, 'XTickLabel', {}, ...
                'YLim', [0 nCor], 'YTick', yTick.Raster, 'YTickLabel', {}, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            plotRaster(ras.ReleaseCor, tras.ReleaseCor, b, "Release", "Cor");

            % Raster | Premature - Press
            ha14 = axes;
            set(ha14, 'Units', 'centimeters', 'Position', [xmap(1) ymap(4) xRaster.Press yRaster*nPre], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Press, 'XTick', xTick.Press, 'XTickLabel', {}, ...
                'YLim', [0 nPre], 'YTick', yTick.Raster, 'YTickLabel', yTickLabel.Raster, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            title("Premature", "Color", c.Pre(1,:), "Rotation", 90, ...
                "Units", "centimeters", "Position", [-xgap/3 yRaster*nPre/2], ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
            plotRaster(ras.PressPre, tras.PressPre, b, "Press", "Pre");

            % Raster | Premature - Release
            ha24 = axes;
            set(ha24, 'Units', 'centimeters', 'Position', [xmap(2) ymap(4) xRaster.Release yRaster*nPre], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Release, 'XTick', xTick.Release, 'XTickLabel', {}, ...
                'YLim', [0 nPre], 'YTick', yTick.Raster, 'YTickLabel', {}, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            plotRaster(ras.ReleasePre, tras.ReleasePre, b, "Release", "Pre");

            % Raster | Late - Press
            ha15 = axes;
            set(ha15, 'Units', 'centimeters', 'Position', [xmap(1) ymap(5) xRaster.Press yRaster*nLate], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Press, 'XTick', xTick.Press, 'XTickLabel', {}, ...
                'YTick', yTick.Raster, 'YTickLabel', yTickLabel.Raster, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            title("Late", "Color", c.Late(1,:), "Rotation", 90, ...
                "Units", "centimeters", "Position", [-xgap/3 yRaster*nLate/2], ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
            plotRaster(ras.PressLate, tras.PressLate, b, "Press", "Late");

            % Raster | Late - Release
            ha25 = axes;
            set(ha25, 'Units', 'centimeters', 'Position', [xmap(2) ymap(5) xRaster.Release yRaster*nLate], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Release, 'XTick', xTick.Release, 'XTickLabel', {}, ...
                'YTick', yTick.Raster, 'YTickLabel', {}, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            plotRaster(ras.ReleaseLate, tras.ReleaseLate, b, "Release", "Late");
            
            % PSTH | Reward
            ha31 = axes;
            set(ha31, 'Units', 'centimeters', 'Position', [xmap(3) ymap2(1) xPSTH.Reward yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Reward, 'XTick', xTick.Reward, 'XTickLabel', xTickLabel.Reward, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel("Time from reward (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("Spikes/sec", "FontSize", fontSize.Label, "FontName", "Arial");
            for i = 1:nFP
                if numReward(i) >= 10
                    plot(tsPSTH.Reward, PSTH.RewardAll, 'color', c.Reward(i,:), 'LineWidth', w.PSTH(i));
                end
            end
            if nNonReward > 5
                plot(tsPSTH.NonReward, PSTH.NonReward, 'color', c.NonReward, 'LineWidth', w.PSTH(1));
            end
            line([0 0], yLim.PSTH, 'color', c.Poke, 'linewidth', w.Align);

            % Raster | Rewarded poke
            ha32 = axes;
            set(ha32, 'Units', 'centimeters', 'Position', [xmap(3) ymap2(2) xRaster.Reward yRaster*nReward], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Reward, 'XTick', xTick.Reward, 'XTickLabel', {}, ...
                'YLim', [0 nReward], 'YTick', yTick.Raster, 'YTickLabel', yTickLabel.Raster, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            title(["Rewarded";"pokes"], "Color", c.Reward(1,:), "Rotation", 90, ...
                "Units", "centimeters", "Position", [-xgap/3 yRaster*nReward/2], ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
            plotRaster(ras.Reward, tras.Reward, b, "Reward", "Reward");

            % Raster | NonReward poke
            ha33 = axes;
            set(ha33, 'Units', 'centimeters', 'Position', [xmap(3) ymap2(3) xRaster.NonReward yRaster*nNonReward], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.NonReward, 'XTick', xTick.NonReward, 'XTickLabel', {}, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            title("Non-", "Color", c.NonReward(1,:), "Rotation", 90, ...
                "Units", "centimeters", "Position", [-xgap/3 yRaster*nNonReward/2], ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
            if nNonReward > 0
                set(ha33, 'YLim', [0 nNonReward], 'YTick', yTick.Raster, 'YTickLabel', yTickLabel.Raster);
            end
            plotRaster(ras.NonReward, tras.NonReward, b, "NonReward", "NonReward");

            % PSTH | Correct & Late - Trigger
            ha41 = axes;
            set(ha41, 'Units', 'centimeters', 'Position', [xmap(4) ymap3(1) xRaster.Trigger yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Trigger, 'XTick', xTick.Trigger, 'XTickLabel', xTickLabel.Trigger, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel("Time from trigger onset (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("Spikes/sec", "FontSize", fontSize.Label, "FontName", "Arial");
            for i = 1:nFP
                if nCorFP(i) >= 10
                    plot(tsPSTH.Trigger, PSTH.TriggerCor{i}, 'color', c.Cor(i,:), 'linewidth', w.PSTH(i));
                end
            end
            if nLate >= 10
                plot(tsPSTH.Trigger, PSTH.TriggerLateAll, 'color', c.Late(1,:), 'linewidth', w.PSTH(1));
            end
            line([0 0], yLim.PSTH, 'color', c.Trigger, 'linewidth', w.Align);

            % Raster | Correct - Trigger
            ha42 = axes;
            set(ha42, 'Units', 'centimeters', 'Position', [xmap(4) ymap3(2) xRaster.Trigger yRaster*nCor], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Trigger, 'XTick', xTick.Trigger, 'XTickLabel', {}, ...
                'YLim', [0 nCor], 'YTick', yTick.Raster, 'YTickLabel', {}, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            title("Correct", "Color", c.Cor(1,:), "Rotation", 90, ...
                "Units", "centimeters", "Position", [-xgap/3 yRaster*nCor/2], ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
            plotRaster(ras.TriggerCor, tras.TriggerCor, b, "Trigger", "Cor");

            % Raster | Late - Trigger
            ha43 = axes;
            set(ha43, 'Units', 'centimeters', 'Position', [xmap(4) ymap3(3) xRaster.Trigger yRaster*nLate], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Trigger, 'XTick', xTick.Trigger, 'XTickLabel', {}, ...
                'YTick', yTick.Raster, 'YTickLabel', {}, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            title("Late", "Color", c.Late(1,:), "Rotation", 90, ...
                "Units", "centimeters", "Position", [-xgap/3 yRaster*nLate/2], ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
            plotRaster(ras.TriggerLate, tras.TriggerLate, b, "Trigger", "Late");

            %% Pre-press activity vs trial num or time

            tPress = obj.Behavior.EventTimings(obj.Behavior.EventMarkers ...
                == find(obj.Behavior.Labels == "LeverPress"));
            itUnit = obj.Units.SpikeTimes(idxUnit).timings;
            [~ , ~, rasPress, trasPress] = jpsth(itUnit, tPress, op.Press);
            tPress = tPress(tPress-op.Press.pre > 0);
            FRPrePress = 1000*sum(rasPress(trasPress<0, :), 1)/sum(trasPress<0);
            % linear regression
            pFit = polyfit(tPress/1000,FRPrePress,1);
            yFit = pFit(1)*tPress/1000+pFit(2);

            ha44 = axes;
            set(ha44, 'Unit', 'centimeters', 'Position', [xmap(4) ymap3(5) xRaster.Trigger yAct], ...
                'nextplot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', [0 max(tPress/1000)+100], ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel('Time (s)', "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel('Spk rate (Hz)', "FontSize", fontSize.Label, "FontName", "Arial");
            scatter(tPress/1000, FRPrePress, 12, cGreys(1,:), "filled", 'o', "MarkerFaceAlpha", 0.5);
            plot(tPress/1000, yFit, 'r--', 'linewidth', w.Align);
            % tempylim = get(gca, 'ylim');
            % text(max(tPress/1000)/2, tempylim(2)/2, "y="+string(pFit(1))+"x"+string(pFit(2)), 'color', 'r');
            % 
            % Add information
            haA = axes; axis off;
            set(haA, 'units', 'centimeters', 'position', [xmap(1) ymap(6) xRaster.Press 0.1]);
            title(["A. Press-related";"activity"], ...
                'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');
            haB = axes; axis off;
            set(haB, 'units', 'centimeters', 'position', [xmap(2) ymap(6) xRaster.Release 0.1]);
            title(["B. Release-related";"activity"], ...
                'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');
            haC = axes; axis off;
            set(haC, 'units', 'centimeters', 'position', [xmap(3) ymap2(4) xRaster.Reward 0.1]);
            title(["C. Rewarded / Nonrewarded";"poke-related activity"], ...
                'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');
            haD = axes; axis off;
            set(haD, 'units', 'centimeters', 'position', [xmap(4) ymap3(4) xRaster.Trigger 0.1]);
            title(["D. Trigger-related";"activity"], ...
                'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');
            haE = axes; axis off;
            set(haE, 'units', 'centimeters', 'position', [xmap(3) ymap2(7) xRaster.Reward 0.1]);
            title(["E. Spike waveform";"& autocorrelation"], ...
                'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');
            haF = axes; axis off;
            set(haF, 'units', 'centimeters', 'position', [xmap(4) ymap3(6) xRaster.Trigger 0.1]);
            title("F. Activity vs time", ...
                'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');

            %% Add unit info
            % Waveform
            wUnit = obj.Units.SpikeTimes(idxUnit).wave;
            if size(wUnit,1) > 100
                idxWave = randperm(size(wUnit,1), 100);
            else
                idxWave = 1:size(wUnit,1);
            end
            wUnit2plot = wUnit(idxWave,:);
            lenWave = size(wUnit, 2);
            spkTrough = min(wUnit,[],2);
            spkPeak   = max(wUnit,[],2);
            yLim.Waveform = 1.5*[median(spkTrough) median(spkPeak)];
            if abs(median(spkTrough)) > abs(median(spkPeak))
                yTick.Waveform = [round(min(obj.Ephys.SpikeWave{idxUnit})) 0];
            else
                yTick.Waveform = [0 round(max(obj.Ephys.SpikeWave{idxUnit}))];
            end

            ChID   = obj.Units.SpikeNotes(idxUnit,1);
            UnitID = obj.Units.SpikeNotes(idxUnit,2);
            if obj.Units.SpikeNotes(idxUnit,3) == 1
                UnitType = "S";
            else
                UnitType = "M";
            end

            ha0 = axes;
            set(ha0, 'Units', 'centimeters', 'Position', [xmap(3) ymap2(5) xWave yWave], ...
                'NextPlot', 'add', "TickDir", "out", 'TickLength', tickLen, ...
                'XLim', [0 lenWave], ...
                'YLim', yLim.Waveform, "YTick", yTick.Waveform);
            ha0.XAxis.Visible = "off";
            ha0.YAxis.Visible = "off";
            plot(1:lenWave, wUnit2plot, 'Color', c.Wave, 'LineWidth', w.Wave);
            plot(1:lenWave, obj.Ephys.SpikeWave{idxUnit}, 'Color', c.MeanWave, 'LineWidth', w.MeanWave);
            title("#"+num2str(idxUnit)+" (Ch"+num2str(ChID)+"U"+num2str(UnitID)+", "+UnitType+")", ...
                "FontSize", fontSize.Label, "FontName", "Arial", ...
                "Units", "centimeters", "Position", [xWave/2 -ygap*1.6]);

            % Autocorrelation
            lags = obj.Ephys.AutoCorrelogram{idxUnit}.lags;
            corr = obj.Ephys.AutoCorrelogram{idxUnit}.corr;
            ha00 = axes;
            set(ha00, 'Units', 'centimeters', 'Position', [xmap(3)+xWave+xgap ymap2(5) xWave yWave], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', [-25 25], 'XTick', -40:20:40, 'XTickLabel', string(-40:20:40),...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            bar(lags, corr, 'FaceColor', 'k');
            xlabel("Lag (ms)", "FontSize", fontSize.Label, "FontName", "Arial");

            % Waveforms in all channels
            ha000 = axes;
            set(ha000, 'Units', 'centimeters', 'Position', [xmap(3) ymap2(6) xRaster.Reward yWave], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            ha000.YDir = "reverse";

            xc = obj.Units.ChannelMap.xcoor2plot;  % xc - x coordinates of each channel
            yc = obj.Units.ChannelMap.ycoor2plot;  % yc - y coordinates of each channel
            xtmap = obj.Units.ChannelMap.xtrodeMap;  % map of #tetrode or #shank

            % if size(obj.Units.SpikeTimes(1).wave, 2) == size(obj.Units.SpikeTimes(1).wave_mean, 2)
            idxSameProbe = find(xtmap == xtmap(ChID)); % channels in the same probe/tetrode
            % bug fixed by hbWang, sep/2023
            % else
            %     idxSameProbe = find(xtmap == ChID);
            % end
            if length(idxSameProbe) > 16 % neuropixels
                isNP = 1;
                raw_xc = obj.Units.ChannelMap.xcoords;
                raw_yc = obj.Units.ChannelMap.ycoords;
                ixc = raw_xc(ChID);
                iyc = raw_yc(ChID);
                idistance = (raw_xc-ixc).^2+(raw_yc-iyc).^2;
                temp = sort(idistance, "ascend");
                idxSameProbe = find(ismember(idistance, temp(1:16))); % find the nearest 15 channels
            end

            wfAll = obj.Units.SpikeTimes(idxUnit).wave_mean;  % waveform in all channels
            wfAll = wfAll(idxSameProbe, :);  % left waveforms in the same probe, and 1:16 not that useful
            xc = xc(idxSameProbe)';
            yc = yc(idxSameProbe)';

            maxAmp = max(max(wfAll,[],2)-min(wfAll,[],2));  % max amplitude in each channel

            if ~isNP
                yscale = 400/maxAmp; xscale = 1;
            else
                yscale = 50/maxAmp; xscale = 4;
            end
            xdata = (1:size(wfAll,2)) + xc*xscale;
            ydata = -wfAll*yscale + yc;
            for j = 1:size(xdata, 1)
                plot(xdata(j,:), ydata(j,:), 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);
            end

            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "Position", [xUnitInfo yUnitInfo+yInfo*1.4 xText, 1], ...
                "String", string(obj.BehaviorClass.Subject), ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold");
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "Position", [xUnitInfo yUnitInfo+yInfo*0.7 xText, 1], ...
                "String", string(obj.BehaviorClass.Date)+" ("+string(obj.Meta(1).Protocol)+")", ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold");
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "Position", [xUnitInfo yUnitInfo xText, 1], ...
                "String", "Unit #"+num2str(idxUnit)+" (Ch"+num2str(ChID)+" | "+num2str(UnitID)+")", ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold");

            %% Save Fig
            [~,~] = mkdir(fullfile(pwd, "Fig", "PSTH"));
            savename = fullfile(pwd, "Fig", "PSTH", "Ch"+num2str(ChID)+"_Unit"+num2str(UnitID)+...
                "_No"+num2str(idxUnit) + options.printName);
            if options.printPNG
                print(Fig, '-dpng', savename);
            end
            if options.printEPS
                print(Fig, '-depsc2', savename);
            end
            if options.printFIG
                saveas(Fig, savename, 'fig');
            end
            if options.printPDF
                print(Fig, '-dpdf', savename);
            end

            %% function to plot raster data
            function plotRaster(ras, tras, b, event, outcome)

                idx = 0;
                tlim  = tras{1,1}(1,[1,end]);
                for ii = 1:size(ras, 2)
                    iRas  = ras{ii}; itRas = tras{ii};
                    switch event
                        case {"Press", "Release", "Trigger"}
                            iFP   = b.("fp"+outcome){ii};
                            iHT   = b.("tHold"+outcome){ii};
                            itAln = b.("t"+event+outcome){ii};
                        case {"NonReward"}
                            iMT   = b.("tMove"+outcome);  % "Reward" & "NonReward"
                            itAln = b.("t"+event);
                        case {"Reward"}
                            iMT   = b.("tMove"+outcome){ii};
                            itAln = b.("t"+event){ii};
                    end
                    for jj = 1:size(iRas, 2) % number of trials
                        xxspk = [itRas(iRas(:, jj) == 1); itRas(iRas(:, jj) == 1)];
                        yyspk = [0 0.8] + idx;
                        if ~isempty(xxspk)
                            line(xxspk, yyspk, 'color', c.(outcome)(ii,:), 'linewidth', w.Spike);
                        end
                        yyevt = [0 1.0] + idx; yyfp = [0 0 1 1] + idx;
                        switch event
                            case "Press"
                                xxprs = [0 0];
                                xxrls = [iHT(jj) iHT(jj)];
                                xxfp  = [0 iFP(jj) iFP(jj) 0];
                                line(xxprs, yyevt, 'color', c.Press,   'linewidth', w.Align);
                                line(xxrls, yyevt, 'color', c.Release, 'linewidth', w.Event);
                                fill(xxfp,  yyfp, c.Trigger, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                            case "Release"
                                xxrls = [0 0];
                                xxprs = -[iHT(jj) iHT(jj)];
                                xxfp  = [0 iFP(jj) iFP(jj) 0] - iHT(jj);
                                line(xxprs, yyevt, 'color', c.Press,   'linewidth', w.Event);
                                line(xxrls, yyevt, 'color', c.Release, 'linewidth', w.Align);
                                fill(xxfp,  yyfp, c.Trigger, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                            case "Trigger"
                                xxrls = iHT(jj) - iFP(jj);
%                                 xxprs = -[iFP(jj) iFP(jj)];
%                                 xxfp  = -[0 iFP(jj) iFP(jj) 0];
%                                 line(xxprs, yyevt, 'color', c.Press,   'linewidth', w.Align);  % semi-aligned
                                scatter(xxrls, 0.4+idx, 7, c.Release, "filled", "o", "MarkerFaceAlpha", 0.6);
                                line([0 0], yyevt, 'color', c.Trigger, 'linewidth', w.Align);
%                                 fill(xxfp,  yyfp, c.Trigger, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                            case {"Reward", "NonReward"}
                                xxrls = -[iMT(jj) iMT(jj)];
                                line(xxrls, yyevt, 'color', c.Release, 'linewidth', w.Event);
                                line([0 0], yyevt, 'color', c.Poke,    'linewidth', w.Align);
                        end

                        % Add pokes
                        jtPoke = b.tPoke-itAln(jj);
                        jtPoke = jtPoke(jtPoke>=tlim(1) & jtPoke<=tlim(2));
                        jtPoke = jtPoke(jtPoke~=0);
                        if ~isempty(jtPoke)
                            scatter(jtPoke, 0.4+idx, 7, c.Poke, "filled", "o", "MarkerFaceAlpha", 0.6);
                        end
                        idx = idx + 1;
                    end
                end
%                 line([0 0], [0 idx], 'color', c.(event), 'linewidth', w.Align);
            end


        end
    
        function plotPSTH4Paper(obj, idxUnit, options)
            % Plot PSTH for one unit
            arguments
                obj
                % idxUnit: index of target unit, could be:
                % (1,1) double: index in all units
                % (1,2) double: [Channel, Unit] (e.g, [12 2] ~ Ch12 Unit2)
                idxUnit             double
                options.FRrange     double = []     % Firing Rate range, default is max+2
                options.printName   string = "4Paper" % postfix of PSTH figure savename
                options.sortRaster logical = obj.sortRaster_default
                                                    % use sorted or unsorted raster data
                options.printPNG   logical = true   % print .PNG (default = true)
                options.printEPS   logical = false  % print .EPS (default = false)
                options.printPDF   logical = false  % print .PDF (default = false)
            end

            if length(idxUnit) == 2
                idxUnit = find(obj.Units.SpikeNotes(:,1) == idxUnit(1) ...
                    & obj.Units.SpikeNotes(:,2) == idxUnit(2));
                if isempty(idxUnit)
                    disp("#### No such unit found, please check your UnitID input ####");
                    return;
                end
            end
            if idxUnit > length(obj.Units.SpikeTimes)
                disp("#### That is all you have ####");
                return;
            end

            [ras, tras] = obj.calEphys(idxUnit, "sortRaster", options.sortRaster);
            PSTH = obj.Ephys.smoothedPSTH{idxUnit};
            tsPSTH = obj.Ephys.tsPSTH{idxUnit};
            if options.sortRaster
                b = obj.sortedBeh;
            else
                b = obj.rawBeh;
            end
            op = obj.Params;
            allEvents = obj.params_default(:, 1);

            if size(ras.RewardAll{1},2) > 50
                randidx = randperm(size(ras.RewardAll{1},2), 50);
                randidx = sort(randidx);
                ras.RewardAll{1} = ras.RewardAll{1}(:, randidx);
                b.tRewardAll = b.tRewardAll(randidx);
                b.tMoveReward = b.tMoveReward(randidx);
            end

            nFP   = size(b.tPressCor, 2);
            nCor  = length(b.tPressCorAll);
            nPre  = length(b.tPressPreAll);
            nLate = length(b.tPressLateAll);
            nReward    = length(b.tRewardAll);
            nNonReward = length(b.tNonReward);

            nCorFP = cellfun(@(x) length(x), b.tPressCor);

            % c: struct of colors
            cTab20c = tab20c(20);  cGreys = cTab20c(17:20,:); 
            cTab10  = tab10(10);   
            cBlue   = cTab10(1,:); cGreen = cTab10(3,:); cRed  = cTab10(4,:);
            cPurple = cTab10(5,:); cPink  = cTab10(7,:); cCyan = cTab10(10,:);
            
            c = struct("Cor", flip(Blues(nFP)), "Pre", flip(Oranges(nFP)), "Late", cGreys(1:nFP,:), ...
                       "Press", cGreen, "Release", cPurple, "Poke", cRed, "Trigger", cPink, ...
                       "Reward", 'k', "NonReward", cGreys(2,:), ...
                       "Wave", cGreys(3,:), "MeanWave", 'k');
            % w: struct of linewidths
            w = struct("PSTH", 0.4*flip(1:nFP)+0.8, "Spike", 1.2, "Align", 1,...
                       "Event", 1.5, "Wave", 0.8, "MeanWave", 2);
            % fondSize: struct of fontsizes
            fontSize = struct("Axes", 7, "Label", 7, "Title", 9);
            tickLen  = [0.02 0.01];

            % Set Firing Rate range
            FRrange = options.FRrange;
            if isempty(options.FRrange)
                for i = 1:nFP
                    if nCorFP(i) >= 10
                        iFRrange = max([PSTH.PressCor{i} PSTH.ReleaseCor{i}]);
                        FRrange = max([FRrange, iFRrange]);
                    end
                end
                FRrange = max([FRrange max(PSTH.RewardAll)]);
                if nPre >= 10
                    FRrange = max([FRrange max(PSTH.PressPreAll) max(PSTH.ReleasePreAll)]);
                end
                if nLate >= 10
                    FRrange = max([FRrange max(PSTH.PressLateAll) max(PSTH.ReleaseLateAll)]);
                end
                FRrange = FRrange + 2;
            end

            % Set x/yLim, x/yTick and x/yTickLabel
            for i = 1:length(allEvents)
                iEvent = allEvents(i);
                xLim.(iEvent)  = [-op.(iEvent).pre   op.(iEvent).post];
                xTick.(iEvent) = [-op.(iEvent).pre 0 op.(iEvent).post];
                xTickLabel.(iEvent) = string(xTick.(iEvent));
            end

            if FRrange <= 10
                yTick.PSTH = 0:2:10;
            elseif FRrange <= 20
                yTick.PSTH = 0:5:20;
            else
                yTick.PSTH = 0:20:100;
            end
            yLim.PSTH = [0 FRrange]; yTickLabel.PSTH   = string(yTick.PSTH);
            yTick.Raster = 0:20:200; yTickLabel.Raster = string(yTick.Raster);

            % Build map (coordinates) of Fig
            xStart = 1.2; yStart = 1.2; xgap = 1; ygap = 0.5;
            xPSTH.Press     = size(tras.PressCor{1}, 2)/1000;
            xPSTH.Release   = size(tras.ReleaseCor{1}, 2)/1000;
            xPSTH.Reward    = size(tras.RewardAll{1}, 2)/1000;
            xPSTH.NonReward = size(tras.NonReward{1}, 2)/1000;
            xPSTH.Trigger   = size(tras.TriggerCor{1}, 2)/1000;
            if xPSTH.Trigger < 3
                xPSTH.Trigger = 3;
            end
            yPSTH = 2; yAct = 0.7*xPSTH.Trigger; yInfo = 2*ygap;
            xRaster = xPSTH; yRaster = 0.04;  % height of one trial in raster plot
            xWave = (xPSTH.Reward-xgap)/2; yWave = xWave*0.8; % Size of Unit Info
            
            xmap = [xStart, ...                            % column 1: Press;
                    xStart+xPSTH.Press+xgap];              % column 2: Release;
            xmap(3) = xmap(2) + xgap*2 + xPSTH.Release;    % column 3: Reward/BadPoke;
            xmap(4) = xmap(3) + xgap*2 + xPSTH.Reward;     % column 4: Trigger;
            ymap = [yStart, ...                            % row -1: Correct PSTH;
                    yStart+yPSTH+ygap, ...                 % row -2: Error PSTH;
                    yStart+yPSTH+ygap*2 + yPSTH];          % row -3: Correct raster
            ymap(4) = ymap(3) + ygap*1 + yRaster*nCor;     % row -4: Premature raster
            ymap(5) = ymap(4) + ygap*1 + yRaster*nPre;     % row -5: Late raster
            ymap(6) = ymap(5) + ygap/2 + yRaster*nLate;    % row -6: A/B

            ymap2 = [yStart, ...                                % row -1: Reward/BadPoke PSTH
                     yStart+yPSTH+ygap];                        % row -2: Reward raster
            ymap2(3) = ymap2(2) + ygap*1 + yRaster*nReward;     % row -3: BadPoke raster
            ymap2(4) = ymap2(3) + ygap/2 + yRaster*nNonReward;  % row -4: C
            ymap2(5) = ymap2(4) + ygap*3 + yInfo;               % row -5: Waveform and AutoCorr
            ymap2(6) = ymap2(5) + ygap*2 + yWave;               % row -6: Waveform in all channels
            ymap2(7) = ymap2(6) + ygap*1 + yWave;               % row -7: E

            ymap3 = [yStart, ...                              % row -1: Trigger PSTH
                     yStart+yPSTH+ygap];                      % row -2: TriggerCor raster
            ymap3(3) = ymap3(2) + ygap*1 + yRaster*nCor;      % row -3: TriggerLate raster
            ymap3(4) = ymap3(3) + ygap/2 + yRaster*nLate;     % row -4: D
            ymap3(5) = ymap3(4) + ygap*3 + yInfo;             % row -5: Activity vs. time
            ymap3(6) = ymap3(5) + ygap/2 + yAct;              % row -6: F

            if ymap(6) - ymap2(7) <= ygap
                xUnitInfo = xmap(1); yUnitInfo = ymap(6) + ygap/2 + yInfo;
                xText = xRaster.Press + xRaster.Release + xgap;
                figSize = [2 2 xmap(end)+xgap+xPSTH.Trigger ymap(end)+ygap*2+yInfo*3];
            elseif ymap(6) - ymap2(7) <= 2*yInfo
                xUnitInfo = xmap(3); yUnitInfo = ymap2(7) + ygap/2 + yInfo;
                xText = xRaster.Reward;
                figSize = [2 2 xmap(end)+xgap+xPSTH.Trigger ymap2(end)+ygap*2+yInfo*3];
            else
                xUnitInfo = xmap(3); 
                yUnitInfo = ymap2(7) + (ymap(6)-ymap2(7))/2 + ygap/2;
                xText = xRaster.Reward;
                figSize = [2 2 xmap(end)+xgap+xPSTH.Trigger ymap(end)+ygap+yInfo];
            end

            Fig = figure(1); clf(Fig, "reset");
            set(Fig, 'name', 'PSTH', 'unit', 'centimeters', 'color', 'w', ...
                'position', figSize, 'paperpositionmode', 'auto');

            % PSTH | Correct - Press
            ha11 = axes;
            set(ha11, 'Units', 'centimeters', 'Position', [xmap(1) ymap(1) xPSTH.Press yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Press, 'XTick', xTick.Press, 'XTickLabel', xTickLabel.Press, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel("Time from press (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("Spikes/sec", "FontSize", fontSize.Label, "FontName", "Arial");
            for i = 1:nFP
                if nCorFP(i) >= 10
                    plot(tsPSTH.Press, PSTH.PressCor{i}, 'color', c.Cor(i,:), 'linewidth', w.PSTH(i));
                end
            end
            line([0 0], yLim.PSTH, 'color', c.Press, 'linewidth', w.Align);

            % PSTH | Error - Press
            ha12 = axes;
            set(ha12, 'Units', 'centimeters', 'Position', [xmap(1) ymap(2) xPSTH.Press yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Press, 'XTick', xTick.Press, 'XTickLabel', {}, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            ylabel("Spikes/sec", "FontSize", fontSize.Label, "FontName", "Arial");
            if nPre >= 10
                plot(tsPSTH.Press, PSTH.PressPreAll,  'color', c.Pre(1,:),  'linewidth', w.PSTH(1));
            end
            if nLate >= 10
                plot(tsPSTH.Press, PSTH.PressLateAll, 'color', c.Late(1,:), 'linewidth', w.PSTH(1));
            end
            line([0 0], yLim.PSTH, 'color', c.Press, 'linewidth', w.Align);

            % PSTH | Correct - Release
            ha21 = axes;
            set(ha21, 'Units', 'centimeters', 'Position', [xmap(2) ymap(1) xPSTH.Release yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Release, 'XTick', xTick.Release, 'XTickLabel', xTickLabel.Release, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel("Time from release (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
            for i = 1:nFP
                if nCorFP(i) >= 10
                    plot(tsPSTH.Release, PSTH.ReleaseCor{i}, 'color', c.Cor(i,:), 'linewidth', w.PSTH(i));
                end
            end
            line([0 0], yLim.PSTH, 'color', c.Release, 'linewidth', w.Align);

            % PSTH | Error - Release
            ha22 = axes;
            set(ha22, 'Units', 'centimeters', 'Position', [xmap(2) ymap(2) xPSTH.Release yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Release, 'XTick', xTick.Release, 'XTickLabel', {}, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            if nPre >= 10
                plot(tsPSTH.Release, PSTH.ReleasePreAll,  'color', c.Pre(1,:),  'linewidth', w.PSTH(1));
            end
            if nLate >= 10
                plot(tsPSTH.Release, PSTH.ReleaseLateAll, 'color', c.Late(1,:), 'linewidth', w.PSTH(1));
            end
            line([0 0], yLim.PSTH, 'color', c.Release, 'linewidth', w.Align);

            % PSTH | Reward
            ha31 = axes;
            set(ha31, 'Units', 'centimeters', 'Position', [xmap(3) ymap2(1) xPSTH.Reward yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Reward, 'XTick', xTick.Reward, 'XTickLabel', xTickLabel.Reward, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel("Time from reward (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("Spikes/sec", "FontSize", fontSize.Label, "FontName", "Arial");
            plot(tsPSTH.Reward,    PSTH.RewardAll,    'color', c.Reward,    'LineWidth', w.PSTH(1));
            if nNonReward > 5
                plot(tsPSTH.NonReward, PSTH.NonReward, 'color', c.NonReward, 'LineWidth', w.PSTH(1));
            end
            line([0 0], yLim.PSTH, 'color', c.Poke, 'linewidth', w.Align);

            % PSTH | Correct & Late - Trigger
            ha41 = axes;
            set(ha41, 'Units', 'centimeters', 'Position', [xmap(4) ymap3(1) xRaster.Trigger yPSTH], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.Trigger, 'XTick', xTick.Trigger, 'XTickLabel', xTickLabel.Trigger, ...
                'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel("Time from trigger onset (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("Spikes/sec", "FontSize", fontSize.Label, "FontName", "Arial");
            for i = 1:nFP
                if nCorFP(i) >= 10
                    plot(tsPSTH.Trigger, PSTH.TriggerCor{i}, 'color', c.Cor(i,:), 'linewidth', w.PSTH(i));
                end
            end
            if nLate >= 10
                plot(tsPSTH.Trigger, PSTH.TriggerLateAll, 'color', c.Late(1,:), 'linewidth', w.PSTH(1));
            end
            line([0 0], yLim.PSTH, 'color', c.Trigger, 'linewidth', w.Align);

            %% Pre-press activity vs trial num or time

            tPress = obj.Behavior.EventTimings(obj.Behavior.EventMarkers ...
                == find(obj.Behavior.Labels == "LeverPress"));
            itUnit = obj.Units.SpikeTimes(idxUnit).timings;
            [~ , ~, rasPress, trasPress] = jpsth(itUnit, tPress, op.Press);
            tPress = tPress(tPress-op.Press.pre > 0);
            FRPrePress = 1000*sum(rasPress(trasPress<0, :), 1)/sum(trasPress<0);
            % linear regression
            pFit = polyfit(tPress/1000,FRPrePress,1);
            yFit = pFit(1)*tPress/1000+pFit(2);

            ha44 = axes;
            set(ha44, 'Unit', 'centimeters', 'Position', [xmap(4) ymap3(5) xRaster.Trigger yAct], ...
                'nextplot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', [0 max(tPress/1000)+100], ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            xlabel('Time (s)', "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel('Spk rate (Hz)', "FontSize", fontSize.Label, "FontName", "Arial");
            scatter(tPress/1000, FRPrePress, 12, cGreys(1,:), "filled", 'o', "MarkerFaceAlpha", 0.5);
            plot(tPress/1000, yFit, 'r--', 'linewidth', w.Align);
            % tempylim = get(gca, 'ylim');
            % text(max(tPress/1000)/2, tempylim(2)/2, "y="+string(pFit(1))+"x"+string(pFit(2)), 'color', 'r');
            % 

            %% Add unit info
            % Waveform
            wUnit = obj.Units.SpikeTimes(idxUnit).wave;
            if size(wUnit,1) > 100
                idxWave = randperm(size(wUnit,1), 100);
            else
                idxWave = 1:size(wUnit,1);
            end
            wUnit2plot = wUnit(idxWave,:);
            lenWave = size(wUnit, 2);
            spkTrough = min(wUnit,[],2);
            spkPeak   = max(wUnit,[],2);
            yLim.Waveform = 1.5*[median(spkTrough) median(spkPeak)];
            if abs(median(spkTrough)) > abs(median(spkPeak))
                yTick.Waveform = [round(min(obj.Ephys.SpikeWave{idxUnit})) 0];
            else
                yTick.Waveform = [0 round(max(obj.Ephys.SpikeWave{idxUnit}))];
            end

            ChID   = obj.Units.SpikeNotes(idxUnit,1);
            UnitID = obj.Units.SpikeNotes(idxUnit,2);
            if obj.Units.SpikeNotes(idxUnit,3) == 1
                UnitType = "S";
            else
                UnitType = "M";
            end

            ha0 = axes;
            set(ha0, 'Units', 'centimeters', 'Position', [xmap(3) ymap2(5) xWave yWave], ...
                'NextPlot', 'add', "TickDir", "out", 'TickLength', tickLen, ...
                'XLim', [0 lenWave], ...
                'YLim', yLim.Waveform, "YTick", yTick.Waveform);
            ha0.XAxis.Visible = "off";
            ha0.YAxis.Visible = "off";
            plot(1:lenWave, wUnit2plot, 'Color', c.Wave, 'LineWidth', w.Wave);
            plot(1:lenWave, obj.Ephys.SpikeWave{idxUnit}, 'Color', c.MeanWave, 'LineWidth', w.MeanWave);
            title("#"+num2str(idxUnit)+" (Ch"+num2str(ChID)+"U"+num2str(UnitID)+", "+UnitType+")", ...
                "FontSize", fontSize.Label, "FontName", "Arial", ...
                "Units", "centimeters", "Position", [xWave/2 -ygap*1.6]);

            % Autocorrelation
            lags = obj.Ephys.AutoCorrelogram{idxUnit}.lags;
            corr = obj.Ephys.AutoCorrelogram{idxUnit}.corr;
            ha00 = axes;
            set(ha00, 'Units', 'centimeters', 'Position', [xmap(3)+xWave+xgap ymap2(5) xWave yWave], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', [-25 25], 'XTick', -40:20:40, 'XTickLabel', string(-40:20:40),...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            bar(lags, corr, 'FaceColor', 'k');
            xlabel("Lag (ms)", "FontSize", fontSize.Label, "FontName", "Arial");

            % Waveforms in all channels
            ha000 = axes;
            set(ha000, 'Units', 'centimeters', 'Position', [xmap(3) ymap2(6) xRaster.Reward yWave], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            ha000.YDir = "reverse";

            xc = obj.Units.ChannelMap.xcoor2plot;  % xc - x coordinates of each channel
            yc = obj.Units.ChannelMap.ycoor2plot;  % yc - y coordinates of each channel
            xtmap = obj.Units.ChannelMap.xtrodeMap;  % map of #tetrode or #shank


            if size(obj.Units.SpikeTimes(1).wave, 2) == size(obj.Units.SpikeTimes(1).wave_mean, 2)
                idxSameProbe = find(xtmap == xtmap(ChID)); % channels in the same probe/tetrode
            else
                idxSameProbe = find(xtmap == ChID);
            end

            wfAll = obj.Units.SpikeTimes(idxUnit).wave_mean;  % waveform in all channels
            wfAll = wfAll(idxSameProbe, :);  % left waveforms in the same probe, and 1:16 not that useful
            xc = xc(idxSameProbe)';
            yc = yc(idxSameProbe)';

            maxAmp = max(max(wfAll,[],2)-min(wfAll,[],2));  % max amplitude in each channel

            yscale = 400/maxAmp;
            xdata = (1:size(wfAll,2)) + xc;
            ydata = -wfAll*yscale + yc;
            for j = 1:size(xdata, 1)
                plot(xdata(j,:), ydata(j,:), 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);
            end

            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "Position", [xUnitInfo yUnitInfo+yInfo*1.4 xText, 1], ...
                "String", string(obj.BehaviorClass.Subject), ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold");
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "Position", [xUnitInfo yUnitInfo+yInfo*0.7 xText, 1], ...
                "String", string(obj.BehaviorClass.Date)+" ("+string(obj.Meta(1).Protocol)+")", ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold");
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "Position", [xUnitInfo yUnitInfo xText, 1], ...
                "String", "Unit #"+num2str(idxUnit)+" (Ch"+num2str(ChID)+" | "+num2str(UnitID)+")", ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold");

            %% Save Fig
            [~,~] = mkdir(fullfile(pwd, "Fig", "PSTH"));
            savename = fullfile(pwd, "Fig", "PSTH", "Ch"+num2str(ChID)+"_Unit"+num2str(UnitID)+...
                "_No"+num2str(idxUnit) + options.printName);
            if options.printPNG
                print(Fig, '-dpng', savename);
            end
            if options.printEPS
                print(Fig, '-depsc2', savename);
            end
            if options.printPDF
                print(Fig, '-dpdf', savename);
            end

        end
        
        function plotPSTHNaive(obj, idxUnit, options)
            % Plot PSTH for one unit
            arguments
                obj
                % idxUnit: index of target unit, could be:
                % (1,1) double: index in all units
                % (1,2) double: [Channel, Unit] (e.g, [12 2] ~ Ch12 Unit2)
                idxUnit             double
                options.FRrange     double = []     % Firing Rate range, default is max+2
                options.printName   string = ""     % postfix of PSTH figure savename
                options.sortRaster logical = obj.sortRaster_default
                                                    % use sorted or unsorted raster data
                options.printPNG   logical = true   % print .PNG (default = true)
                options.printFIG   logical = false  % print .FIG (default = false)
                options.printEPS   logical = false  % print .EPS (default = false)
                options.printPDF   logical = false  % print .PDF (default = false)
            end

            if length(idxUnit) == 2
                idxUnit = find(obj.Units.SpikeNotes(:,1) == idxUnit(1) ...
                    & obj.Units.SpikeNotes(:,2) == idxUnit(2));
                if isempty(idxUnit)
                    disp("#### No such unit found, please check your UnitID input ####");
                    return;
                end
            end
            if idxUnit > length(obj.Units.SpikeTimes)
                disp("#### That is all you have ####");
                return;
            end

            [ras, tras] = obj.calEphysNaive(idxUnit, "sortRaster", options.sortRaster);
            PSTH = obj.Ephys.smoothedPSTH{idxUnit};
            tsPSTH = obj.Ephys.tsPSTH{idxUnit};
            if options.sortRaster
                b = obj.sortedBeh;
            else
                b = obj.rawBeh;
            end
            op = obj.Params;

            switch obj.BehaviorClass.Task
                case "AutoShaping"
                    allEvents = obj.event_auto;
                    nTrials = length(b.tTrigger);
                case {"LeverPress", "LeverRelease"}
                    allEvents = obj.event_lever;
                    nTrials = length(b.tPress);
            end
            nReward = length(b.tReward);
            nEvent  = length(allEvents);

            % c: struct of colors
            cTab20c = tab20c(20);  cGreys = cTab20c(17:20,:); 
            cTab10  = tab10(10);   
            cBlue   = cTab10(1,:); cGreen = cTab10(3,:); cRed  = cTab10(4,:);
            cPurple = cTab10(5,:); cPink  = cTab10(7,:); cCyan = cTab10(10,:);
            
            c = struct("Cor", Blues(1), "Pre", Oranges(1), ...
                       "Poke", cRed, "Trigger", cPink, ...
                       "Reward", cGreen, "NonReward", cGreys(2,:), ...
                       "Wave", cGreys(3,:), "MeanWave", 'k', ...
                       "Press", Blues(1), "Release", Oranges(1));
            % w: struct of linewidths
            w = struct("PSTH", 1.2, "Spike", 1.2, "Align", 1,...
                       "Event", 1.5, "Wave", 0.8, "MeanWave", 2);
            % fondSize: struct of fontsizes
            fontSize = struct("Axes", 7, "Label", 7, "Title", 9);
            tickLen  = [0.02 0.01];

            % Set Firing Rate range
            FRrange = options.FRrange;
            if isempty(options.FRrange)
                FRrange = max(struct2array(PSTH))+2;
            end

            % Set x/yLim, x/yTick and x/yTickLabel
            for i = 1:nEvent
                iEvent = allEvents(i);
                xLim.(iEvent)  = [-op.(iEvent).pre   op.(iEvent).post];
                xTick.(iEvent) = [-op.(iEvent).pre 0 op.(iEvent).post];
                xTickLabel.(iEvent) = string(xTick.(iEvent));
                xPSTH.(iEvent) = size(tras.(iEvent), 2)/1000;
            end

            if FRrange <= 10
                yTick.PSTH = 0:2:10;
            elseif FRrange <= 20
                yTick.PSTH = 0:5:20;
            else
                yTick.PSTH = 0:20:100;
            end
            yLim.PSTH = [0 FRrange]; yTickLabel.PSTH   = string(yTick.PSTH);
            yTick.Raster = 0:20:200; yTickLabel.Raster = string(yTick.Raster);

            % Build map (coordinates) of Fig
            xStart = 1.2; yStart = 1.2; xgap = 1; ygap = 0.5;
            
            yPSTH = 2; yInfo = 2*ygap;
            xRaster = xPSTH; yRaster = 0.04;  % height of one trial in raster plot
            xWave = (xPSTH.Reward-xgap)/2; yWave = xWave*0.8; % Size of Unit Info
            
            xmap(1) = xStart;
            for i = 2:nEvent
                iEvent = allEvents(i-1);
                xmap(i) = xmap(i-1) + xPSTH.(iEvent) + xgap;
            end
            xmap(i+1) = xmap(i) + xPSTH.(allEvents(end)) + xgap;

            ymap = [yStart, ...                              % row -1: Correct PSTH;
                    yStart+yPSTH+ygap, ...                   % row -2: Correct raster;
                    yStart+yPSTH+ygap + yRaster*nTrials];   % row -3: A/B
            ymap(4) = ymap(3) + ygap*2 + yInfo;              % row -4: Waveform and AutoCorr
            ymap(5) = ymap(4) + ygap*1 + yWave;              % row -5: Waveform in all channels
            ymap(6) = ymap(5) + ygap*1 + yWave;              % row -6: E
                
            xUnitInfo = xmap(1)/2; yUnitInfo = ymap(4) + ygap/2 + yInfo;
            figSize = [2 2 xmap(end) ymap(end)+ygap+yInfo];
            

            Fig = figure(1); clf(Fig, "reset");
            set(Fig, 'name', 'PSTH', 'unit', 'centimeters', 'color', 'w', ...
                'position', figSize, 'paperpositionmode', 'auto');

            for i = 1:nEvent
                iEvent = allEvents(i);
                % PSTH
                ha11 = axes;
                set(ha11, 'Units', 'centimeters', 'Position', [xmap(i) ymap(1) xPSTH.(iEvent) yPSTH], ...
                    'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                    'XLim', xLim.(iEvent), 'XTick', xTick.(iEvent), 'XTickLabel', xTickLabel.(iEvent), ...
                    'YLim', yLim.PSTH, 'YTick', yTick.PSTH, 'YTickLabel', yTickLabel.PSTH, ...
                    'FontSize', fontSize.Axes, 'FontName', 'Arial');
                xlabel("Time from "+iEvent+" (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
                ylabel("Spikes/sec", "FontSize", fontSize.Label, "FontName", "Arial");
    
                plot(tsPSTH.(iEvent), PSTH.(iEvent), 'color', c.(iEvent), 'linewidth', w.PSTH);
                line([0 0], yLim.PSTH, 'color', c.(iEvent), 'linewidth', w.Align);
    
                % Raster
                ha12 = axes;
                set(ha12, 'Units', 'centimeters', 'Position', [xmap(i) ymap(2) xRaster.(iEvent) yRaster*nTrials], ...
                    'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                    'XLim', xLim.(iEvent), 'XTick', xTick.(iEvent), 'XTickLabel', {}, ...
                    'YLim', [0 nTrials], 'YTick', yTick.Raster, 'YTickLabel', yTickLabel.Raster, ...
                    'FontSize', fontSize.Axes, 'FontName', 'Arial');
                axis off;
                title(iEvent, "Color", c.(iEvent), "Rotation", 90, ...
                    "Units", "centimeters", "Position", [-xgap/3 yRaster*nTrials/2], ...
                    "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
                plotRasterNaive(ras.(iEvent), tras.(iEvent), b, iEvent);
            end
            
            % Add information
            switch obj.BehaviorClass.Task

                case "AutoShaping"
                    haA = axes; axis off;
                    set(haA, 'units', 'centimeters', 'position', [xmap(1) ymap(3) xRaster.Trigger 0.1]);
                    title(["A. Trigger-related";"activity"], ...
                        'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');
                    haB = axes; axis off;
                    set(haB, 'units', 'centimeters', 'position', [xmap(2) ymap(3) xRaster.Reward 0.1]);
                    title(["B. Reward-related";"activity"], ...
                        'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');
                    haC = axes; axis off;
                    set(haC, 'units', 'centimeters', 'position', [xmap(2) ymap(6) xRaster.Reward 0.1]);
                    title(["C. Spike waveform";"& autocorrelation"], ...
                        'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');
                case {"LeverPress", "LeverRelease"}
            end
            %% Add unit info
            % Waveform
            wUnit = obj.Units.SpikeTimes(idxUnit).wave;
            if size(wUnit,1) > 100
                idxWave = randperm(size(wUnit,1), 100);
            else
                idxWave = 1:size(wUnit,1);
            end
            wUnit2plot = wUnit(idxWave,:);
            lenWave = size(wUnit, 2);
            spkTrough = min(wUnit,[],2);
            spkPeak   = max(wUnit,[],2);
            yLim.Waveform = 1.5*[median(spkTrough) median(spkPeak)];
            if abs(median(spkTrough)) > abs(median(spkPeak))
                yTick.Waveform = [round(min(obj.Ephys.SpikeWave{idxUnit})) 0];
            else
                yTick.Waveform = [0 round(max(obj.Ephys.SpikeWave{idxUnit}))];
            end

            ChID   = obj.Units.SpikeNotes(idxUnit,1);
            UnitID = obj.Units.SpikeNotes(idxUnit,2);
            if obj.Units.SpikeNotes(idxUnit,3) == 1
                UnitType = "S";
            else
                UnitType = "M";
            end

            ha0 = axes;
            set(ha0, 'Units', 'centimeters', 'Position', [xmap(2) ymap(4) xWave yWave], ...
                'NextPlot', 'add', "TickDir", "out", 'TickLength', tickLen, ...
                'XLim', [0 lenWave], ...
                'YLim', yLim.Waveform, "YTick", yTick.Waveform);
            ha0.XAxis.Visible = "off";
            ha0.YAxis.Visible = "off";
            plot(1:lenWave, wUnit2plot, 'Color', c.Wave, 'LineWidth', w.Wave);
            plot(1:lenWave, obj.Ephys.SpikeWave{idxUnit}, 'Color', c.MeanWave, 'LineWidth', w.MeanWave);
            title("#"+num2str(idxUnit)+" (Ch"+num2str(ChID)+"U"+num2str(UnitID)+", "+UnitType+")", ...
                "FontSize", fontSize.Label, "FontName", "Arial", ...
                "Units", "centimeters", "Position", [xWave/2 -ygap*1.6]);

            % Autocorrelation
            lags = obj.Ephys.AutoCorrelogram{idxUnit}.lags;
            corr = obj.Ephys.AutoCorrelogram{idxUnit}.corr;
            ha00 = axes;
            set(ha00, 'Units', 'centimeters', 'Position', [xmap(2)+xWave+xgap ymap(4) xWave yWave], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', [-25 25], 'XTick', -40:20:40, 'XTickLabel', string(-40:20:40),...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            bar(lags, corr, 'FaceColor', 'k');
            xlabel("Lag (ms)", "FontSize", fontSize.Label, "FontName", "Arial");

            % Waveforms in all channels
            ha000 = axes;
            set(ha000, 'Units', 'centimeters', 'Position', [xmap(2) ymap(5) xRaster.Reward yWave], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            axis off;
            ha000.YDir = "reverse";

            xc = obj.Units.ChannelMap.xcoor2plot;  % xc - x coordinates of each channel
            yc = obj.Units.ChannelMap.ycoor2plot;  % yc - y coordinates of each channel
            xtmap = obj.Units.ChannelMap.xtrodeMap;  % map of #tetrode or #shank

            idxSameProbe = find(xtmap == xtmap(ChID)); % channels in the same probe/tetrode

            wfAll = obj.Units.SpikeTimes(idxUnit).wave_mean;  % waveform in all channels
            wfAll = wfAll(idxSameProbe, :);  % left waveforms in the same probe, and 1:16 not that useful
            xc = xc(idxSameProbe)';
            yc = yc(idxSameProbe)';

            maxAmp = max(max(wfAll,[],2)-min(wfAll,[],2));  % max amplitude in each channel

            yscale = 400/maxAmp;
            xdata = (1:size(wfAll,2)) + xc;
            ydata = -wfAll*yscale + yc;
            for j = 1:size(xdata, 1)
                plot(xdata(j,:), ydata(j,:), 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);
            end

            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "Position", [xUnitInfo yUnitInfo+yInfo*1.4 5 1], ...
                "String", string(obj.BehaviorClass.Subject)+"-"+string(obj.BehaviorClass.Date), ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold");
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "Position", [xUnitInfo yUnitInfo+yInfo*0.7 5 1], ...
                "String", "("+string(obj.Meta(1).Protocol)+")", ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold");
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "Position", [xUnitInfo yUnitInfo 5 1], ...
                "String", "Unit #"+num2str(idxUnit)+" (Ch"+num2str(ChID)+" | "+num2str(UnitID)+")", ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold");

            %% Save Fig
            [~,~] = mkdir(fullfile(pwd, "Fig", "PSTH"));
            savename = fullfile(pwd, "Fig", "PSTH", "Ch"+num2str(ChID)+"_Unit"+num2str(UnitID)+...
                "_No"+num2str(idxUnit) + options.printName);
            if options.printPNG
                print(Fig, '-dpng', savename);
            end
            if options.printEPS
                print(Fig, '-depsc2', savename);
            end
            if options.printFIG
                saveas(Fig, savename, 'fig');
            end
            if options.printPDF
                print(Fig, '-dpdf', savename);
            end

            %% function to plot raster data
            function plotRasterNaive(ras, tras, b, event, task)

                idx = 0;
                tlim  = tras(1,[1,end]);
                    itAln = b.("t"+event);
                    iMT   = b.tMoveReward;
                    for jj = 1:size(ras, 2) % number of trials
                        xxspk = [tras(ras(:, jj) == 1); tras(ras(:, jj) == 1)];
                        yyspk = [0 0.8] + idx;
                        if ~isempty(xxspk)
                            line(xxspk, yyspk, 'color', 'k', 'linewidth', w.Spike);
                        end
                        yyevt = [0 1.0] + idx;
                        switch event
                            case "Press"
                                xxprs = [0 0];
                                xxrls = [b.tRelease(jj)-b.tPress(jj) b.tRelease(jj)-b.tPress(jj)];
                                line(xxprs, yyevt, 'color', c.Press,   'linewidth', w.Align);
                                line(xxrls, yyevt, 'color', c.Release, 'linewidth', w.Event);
                            case "Release"
                                xxrls = [0 0];
                                xxprs = [b.tPress(jj)-b.tRelease(jj) b.tPress(jj)-b.tRelease(jj)];
                                line(xxprs, yyevt, 'color', c.Press,   'linewidth', w.Align);
                                line(xxrls, yyevt, 'color', c.Release, 'linewidth', w.Event);   
                            case "Trigger"
                                xxrls = iMT(jj);
                                scatter(xxrls, 0.4+idx, 6, c.Poke, "filled", "o", "MarkerFaceAlpha", 0.6);
                                line([0 0], yyevt, 'color', c.Trigger, 'linewidth', w.Align);
                            case "Reward"
                                xxrls = -[iMT(jj) iMT(jj)];
                                line(xxrls, yyevt, 'color', c.Trigger, 'linewidth', w.Event);
                                line([0 0], yyevt, 'color', c.Poke,    'linewidth', w.Align);
                        end

                        % Add pokes
                        jtPoke = b.tPoke-itAln(jj);
                        jtPoke = jtPoke(jtPoke>=tlim(1) & jtPoke<=tlim(2));
                        jtPoke = jtPoke(jtPoke~=0);
                        if ~isempty(jtPoke)
                            scatter(jtPoke, 0.4+idx, 7, c.Poke, "filled", "o", "MarkerFaceAlpha", 0.6);
                        end
                        idx = idx + 1;
                    end
            end

        end

        function plotPSTH4All(obj, options)
            % Plot PSTH for all units
            arguments
                % All arguments are same with @obj.plotPSTH
                obj
                options.FRrange     double = []
                options.printName   string = ""
                options.sortRaster logical = obj.sortRaster_default
                options.printPNG   logical = true
                options.printFIG   logical = false
                options.printEPS   logical = false
                options.printPDF   logical = false
            end
            allUnits = size(obj.Units.SpikeNotes, 1);
            for i = 1:allUnits
                disp("Plotting PSTH "+num2str(i)+" of "+num2str(allUnits));
                if ismember(obj.BehaviorClass.Task, ["AutoShaping","LeverPress","LeverRelease"])
                    obj.plotPSTHNaive(i, "FRrange", options.FRrange, ...
                        "printName", options.printName, "printPDF", options.printPDF, ...
                        "sortRaster", options.sortRaster, "printPNG", options.printPNG, ...
                        "printFIG", options.printFIG, "printEPS", options.printEPS);
                else
                    obj.plotPSTH(i, "FRrange", options.FRrange, ...
                        "printName", options.printName, "printPDF", options.printPDF, ...
                        "sortRaster", options.sortRaster, "printPNG", options.printPNG, ...
                        "printFIG", options.printFIG, "printEPS", options.printEPS);
                end
            end
%             curRClassName = string(dir("RClass_*.mat").name);
%             if length(curRClassName) == 1
%                 obj.save("saveName", curRClassName);
%             end
        end

        %% Calculate population PSTH - obj.EphysPop
        function calPopulationPSTH(obj)
            if ~isempty(obj.PSTHs)
                if sum(cellfun(@(x) ~isempty(x), obj.PSTHs.tsPSTH)) ~= size(obj.Units.SpikeNotes, 1)
                    disp("**** Using @calEphys4All, please wait ****");
                    obj.calEphys4All("save2Path", false);
                end
            else
                disp("**** Using @calEphys4All, please wait ****");
                obj.calEphys4All("save2Path", false);
            end
            
            p = obj.PSTHs.smoothedPSTH;
            opp = obj.ParamsPop;
            nFP = length(p{1,1}.PressCor);
            nUnit = length(p);

            psthAll.Press   = cellfun(@(x) x.PressCorAll,   p, "UniformOutput", false);
            psthAll.Trigger = cellfun(@(x) x.TriggerCorAll, p, "UniformOutput", false);
            psthAll.Release = cellfun(@(x) x.ReleaseCorAll, p, "UniformOutput", false);
            psthAll.Reward  = cellfun(@(x) x.RewardAll,     p, "UniformOutput", false);
            for i = 1:nFP
                psth{i}.Press   = cellfun(@(x) x.PressCor{i},   p, "UniformOutput", false);
                psth{i}.Trigger = cellfun(@(x) x.TriggerCor{i}, p, "UniformOutput", false);
                psth{i}.Release = cellfun(@(x) x.ReleaseCor{i}, p, "UniformOutput", false);
                psth{i}.Reward  = cellfun(@(x) x.Reward{i},     p, "UniformOutput", false);
            end

            ts = obj.PSTHs.tsPSTH{1};
            idxPress   = ts.Press   >= -opp.Press.pre   & ts.Press   <= opp.Press.post;
            idxTrigger = ts.Trigger >= -opp.Trigger.pre & ts.Trigger <= opp.Trigger.post;
            idxRelease = ts.Release >= -opp.Release.pre & ts.Release <= opp.Release.post;
            idxReward  = ts.Reward  >= -opp.Reward.pre  & ts.Reward  <= opp.Reward.post;
            nbins   = [sum(idxPress), sum(idxTrigger), sum(idxRelease), sum(idxReward)]';
            idxbins = [                           1 nbins(1); 
                                         nbins(1)+1 nbins(1)+nbins(2);
                                nbins(1)+nbins(2)+1 nbins(1)+nbins(2)+nbins(3);...
                       nbins(1)+nbins(2)+nbins(3)+1 sum(nbins)];
            paramMerge = obj.paramsPopTable; % use table format
            paramMerge = addvars(paramMerge, nbins, idxbins);

            for i = 1:nUnit
                psthMergeAll(i,:) = [psthAll.Press{i}(idxPress) psthAll.Trigger{i}(idxTrigger) psthAll.Release{i}(idxRelease) psthAll.Reward{i}(idxReward)];
                for j = 1:nFP
                    psthMerge{j}(i,:) = [psth{j}.Press{i}(idxPress) psth{j}.Trigger{i}(idxTrigger) psth{j}.Release{i}(idxRelease) psth{j}.Reward{i}(idxReward)];
                end
            end
            psthMergeAllZ = zscore(psthMergeAll, 1, 2);
            psthMergeZ    = cellfun(@(x) zscore(x, 1, 2), psthMerge, "UniformOutput", false);
            frMergeAll    = mean(psthMergeAll, 2);
            frMerge       = cellfun(@(x) mean(x, 2), psthMerge, "UniformOutput", false);

            obj.EphysPop.psthMergeAll  = psthMergeAll;
            obj.EphysPop.psthMergeAllZ = psthMergeAllZ;
            obj.EphysPop.psthMerge  = psthMerge;
            obj.EphysPop.psthMergeZ = psthMergeZ;
            obj.EphysPop.frMergeAll = frMergeAll;
            obj.EphysPop.frMerge    = frMerge;
            obj.EphysPop.paramMerge = paramMerge;
            obj.EphysPop.TrialNum   = cellfun(@(x) size(x,1), obj.EventTimes.tPressCor);
        end

        function calPopulationPSTH_AutoShaping(obj)
            if ~isempty(obj.PSTHs)
                if sum(cellfun(@(x) ~isempty(x), obj.PSTHs.tsPSTH)) ~= size(obj.Units.SpikeNotes, 1)
                    disp("**** Using @calEphys4All, please wait ****");
                    obj.calEphys4All("save2Path", false);
                end
            else
                disp("**** Using @calEphys4All, please wait ****");
                obj.calEphys4All("save2Path", false);
            end
            
            p = obj.PSTHs.smoothedPSTH;
            opp = obj.ParamsPop;
            nUnit = length(p);

            psthAll.Trigger = cellfun(@(x) x.Trigger, p, "UniformOutput", false);
            psthAll.Reward  = cellfun(@(x) x.Reward,  p, "UniformOutput", false);

            ts = obj.PSTHs.tsPSTH{1};
            idxTrigger = ts.Trigger >= -opp.Trigger.pre & ts.Trigger <= opp.Trigger.post;
            idxReward  = ts.Reward  >= -opp.Reward.pre  & ts.Reward  <= opp.Reward.post;
            nbins   = [sum(idxTrigger), sum(idxReward)]';
            idxbins = [1 nbins(1); nbins(1)+1 nbins(1)+nbins(2)];
            paramMerge = obj.paramsPopTable; % use table format
            paramMerge = addvars(paramMerge, nbins, idxbins);

            for i = 1:nUnit
                psthMergeAll(i,:) = [psthAll.Trigger{i}(idxTrigger) psthAll.Reward{i}(idxReward)];
            end
            psthMergeAllZ = zscore(psthMergeAll, 1, 2);
            frMergeAll    = mean(psthMergeAll, 2);

            obj.EphysPop.psthMergeAll  = psthMergeAll;
            obj.EphysPop.psthMergeAllZ = psthMergeAllZ;

            obj.EphysPop.frMergeAll = frMergeAll;
            obj.EphysPop.paramMerge = paramMerge;
            obj.EphysPop.TrialNum   = size(obj.EventTimes.tReward,1);
        end

        %% PSTHPOP PLOT methods
        function plotPopulationPSTH(obj, options)
            arguments
                obj
                options.NormMethod  string {mustBeMember(options.NormMethod, ...
                    ["Normalize", "Rescale"])} = "Normalize"
                options.NormRange   double     = [0 1]
                options.ZscoreRange double     = [-3 3]
                options.printName   string     = ""
                options.printPNG   logical     = true
                options.printFIG   logical     = false
                options.printEPS   logical     = false
                options.printPDF   logical     = false
            end
            if isempty(obj.PSTHPop)
                disp("**** Calculate PSTHPop de novo ****");
                obj.calPopulationPSTH();
            end
            if isempty(obj.PSTHWarped)
                disp("**** Calculate PSTHPop de novo ****");
                obj.warpEphys4All();
            end

            paramMerge = obj.PSTHPop.paramMerge;
            spikeInfo  = obj.Units.SpikeNotes;
            nUnits = size(spikeInfo, 1);
            warped = obj.EphysWarped;
            for i = 1:length(warped.sdf_mean{1})
                temp = cellfun(@(x) x{i}, warped.sdf_mean, "UniformOutput", false);
                sdf_mean{i} = cell2mat(temp');
                sdf_ci(i,:)   = cellfun(@(x) x{i}, warped.sdf_ci,   "UniformOutput", false);
            end

            % Sort and check p-value using FP with max trialnum
            trialnum = cellfun(@height, warped.sdf{1}, "UniformOutput", true);
            [~, idxFP] = max(trialnum);
            if length(idxFP)>1; idxFP = idxFP(1); end

            [~, tPeak] = max(sdf_mean{idxFP}, [], 2);
            [~, idxSort] = sort(tPeak, 1, "ascend");

            stat.Press   = cellfun(@(x) x.PressCor{idxFP},   obj.PSTHs.StatOut, "UniformOutput", false);
            stat.Trigger = cellfun(@(x) x.TriggerCor{idxFP}, obj.PSTHs.StatOut, "UniformOutput", false);
            stat.Release = cellfun(@(x) x.ReleaseCor{idxFP}, obj.PSTHs.StatOut, "UniformOutput", false);
            stat.Reward  = cellfun(@(x) x.Reward{idxFP},     obj.PSTHs.StatOut, "UniformOutput", false);
            pval = cellfun(@(x) x.pval, [stat.Press; stat.Release; stat.Reward]', "UniformOutput", true);
%             tpeak = cellfun(@(x) x.tpeak, [stat.Press; stat.Release; stat.Reward]', "UniformOutput", true);
            pvalMerge = min(pval,[],2);
            pvalMerge2Sort = pvalMerge(idxSort);
            
            idxSignificant = pvalMerge2Sort < 0.05;
            if ~isempty(idxSignificant)
                idxSort = [idxSort(idxSignificant); idxSort(~idxSignificant)];
%                 idxSignificant = [idxSignificant(idxSignificant); idxSignificant(~idxSignificant)];
            end

%             pval = pval(idxSort, :);
            pvalMerge = pvalMerge(idxSort);
            spikeInfo = spikeInfo(idxSort,:);
            meanWaves = obj.PSTHs.SpikeWave(idxSort);
            nameUnits = "Ch" + spikeInfo(:,1) + "U" + spikeInfo(:,2);

            % Remove FP less than 10 trials (for wait protocol)
            idxFP = obj.PSTHPop.TrialNum > 10;
            allFPs = obj.fpList(idxFP);
            % psthSorted  = cellfun(@(x) x(idxSort,:), obj.PSTHPop.psthMerge(idxFP),  "UniformOutput", false);
            psthZSorted = cellfun(@(x) x(idxSort,:), obj.PSTHPop.psthMergeZ(idxFP), "UniformOutput", false);
            warpSorted  = cellfun(@(x) x(idxSort,:), sdf_mean(idxFP), "UniformOutput", false);
%             frSorted = cellfun(@(x) x(idxSort), obj.PSTHPop.frMerge(idxFP), "UniformOutput", false);
            frAllSorted = obj.PSTHPop.frMergeAll(idxSort);
            nTrial = obj.PSTHPop.TrialNum(idxFP);
            nFP = length(nTrial);

            mycolormap = cold2warm;
            tickLen = [0.02 0.01];
            lineStyle = '--'; lineWidth = 1.5; lineColor = 'k';
            fontSize = struct("Axes", 7, "Label", 7, "Title", 9);

            xstart = 1; ystart = 1.5;  xgap = 0.15; ygap = 0.6; xgap2 = 5*xgap;
            if nUnits < 50
                h8Unit = 0.1;
            else
                h8Unit = 5/nUnits;
            end
            h8Axes = h8Unit*nUnits; 
            h8ColorBar = 2; lenAxes.ColorBar = 0.25;

            lenUnit = 1/50;

            popEvent = string(paramMerge.Properties.RowNames);
            for i = 1:length(popEvent)
                iEvent = popEvent(i);
                ipm = paramMerge(i,:);
                lenAxes.(iEvent)    = ipm.nbins*lenUnit;
                xLim.(iEvent)       = [-ipm.pre ipm.post]/ipm.binwidth;
                xTick.(iEvent)      = (-2000:500:2000)/ipm.binwidth;
                xTickLabel.(iEvent) = string(-2000:500:2000);
            end

            for i = 1:nFP
                twarp = size(warpSorted{i}, 2);
                xvalues_warped = [0 twarp]-warped.PrePost(1)*1000;
                lenAxes.("Warp"+num2str(i)) = twarp/1000;
                xLim.("Warp"+num2str(i)) = [xvalues_warped(1) xvalues_warped(end)];
                xTick.("Warp"+num2str(i)) = xvalues_warped(1):1000:xvalues_warped(end);
                xTickLabel.("Warp"+num2str(i)) = string(xvalues_warped(1):1000:xvalues_warped(end));

            end

            xmap(1) = xstart;
            xmap(2) = xmap(1) + xgap*1 + lenAxes.Press;
            xmap(3) = xmap(2) + xgap*1 + lenAxes.Trigger;
            xmap(4) = xmap(3) + xgap*1 + lenAxes.Release;
            xmap(5) = xmap(4) + xgap*3 + lenAxes.Reward;
            xmap(6) = xmap(5) + xgap2  + lenAxes.ColorBar;
            xmap(7) = xmap(6) + xgap2  + lenAxes.Warp1;
            xmap(8) = xmap(7) + xgap2  + lenAxes.ColorBar;

            ymap(1) = ystart;
            for i = 1:nFP
                ymap(1+i) = ymap(i) + ygap*1 + h8Axes;
            end

            if nUnits > 18; nWave = 8; else; nWave = 6; end
            lenAxes.Wave = (xmap(end-1)-xmap(1)-(nWave-1)*xgap2)/nWave;
            xLim.Wave = size(meanWaves{1}, 2);

            xmap2(1) = xstart; ymap2(1) = ymap(end) + ygap;
            for i = 2:nWave
                xmap2(i) = xmap2(i-1) + lenAxes.Wave + xgap2;
            end
            for i = 2:ceil(nUnits/nWave)
                ymap2(i) = ymap2(i-1) + lenAxes.Wave*2/3 + ygap;
            end
            ymap2 = fliplr(ymap2);


            Fig = figure(1); clf(Fig, "reset");
            set(Fig, 'units', 'centimeters', 'color', 'w', 'paperpositionmode', 'auto',...
                'position', [2 2 xmap(end) ymap2(1)+lenAxes.Wave*2/3+ygap+1]);

            for i = 1:nFP
                for j = 1:length(popEvent)
                    jEvent = popEvent(j);
                    idxPlot = paramMerge(j,:).idxbins(1):paramMerge(j,:).idxbins(2);

                    % Z-scored
                    aname = "a"+num2str(i)+num2str(j);  % axes name
                    h.(aname) = axes("Units", "centimeters", "NextPlot", "add", ...
                        "Position", [xmap(j) ymap(i) lenAxes.(jEvent) h8Axes], ...
                        "TickDir", "out", "TickLength", tickLen, ...
                        "XLim", [xLim.(jEvent)(1)-0.5 xLim.(jEvent)(2)+0.5], ...
                        "XTick", xTick.(jEvent), "XTickLabel", {}, "XTickLabelRotation", 90, ...
                        "YLim", [0.5 nUnits+0.5], "YDir", "reverse", ... 
                        "FontSize", fontSize.Axes, "FontName", "Arial");
                    imagesc(xLim.(jEvent), [1 nUnits], psthZSorted{i}(:,idxPlot), options.ZscoreRange);
                    line([0 0], [0.5 nUnits+0.5], 'LineStyle', lineStyle, 'Color', lineColor, 'LineWidth', lineWidth);
                    colormap(h.(aname), mycolormap);

                    if i == 1
                        set(h.(aname), "XTickLabel", xTickLabel.(jEvent));
                    end
                    if i == 1 && j == 1
                        xlabel(h.(aname), "Time from press / release / reward (ms)", ...
                            "HorizontalAlignment", "left", ...
                            "FontSize", fontSize.Label, "FontName", "Arial");
                    end
                    if j == 1
                        plotFPlines = true;
                        switch obj.Meta(1).Protocol
                            case {"Wait", "Wait1", "Wait2"}
                                if allFPs(i) < obj.fpList(1)
                                    titletext = "FP < "+num2str(obj.fpList(1))+"ms, nTrials = "+num2str(nTrial(i));
                                    plotFPlines = false;
                                else
                                    titletext = "FP = "+allFPs(i)+"ms, nTrials = "+num2str(nTrial(i));
                                end
                            case {"2FPs", "3FPs"}
                                titletext = "FP = "+allFPs(i)+"ms, nTrials = "+num2str(nTrial(i));
                        end
                        if plotFPlines
                            line(h.(aname), [allFPs(i) allFPs(i)]/paramMerge(1,:).binwidth, [0.5 nUnits+0.5], ...
                                'LineStyle', lineStyle, 'Color', 'r', 'LineWidth', lineWidth);
                        end
                        title(h.(aname), titletext, ...
                            "HorizontalAlignment", "left", ...
                            "FontSize", fontSize.Label, "FontName", "Arial", "FontWeight", "bold");
                        ylabel(h.(aname), "Units #", "FontSize", fontSize.Label, "FontName", "Arial");
                    else
                        set(h.(aname), "YTick", [], "YTickLabel", {});
                    end
                end

                % warped
                bname = "Warp"+num2str(i);  % axes name
                h.(bname) = axes("Units", "centimeters", "NextPlot", "add", ...
                    "Position", [xmap(6) ymap(i) lenAxes.(bname) h8Axes], ...
                    "TickDir", "out", "TickLength", tickLen/3, ...
                    "XLim", [xLim.(bname)(1)-0.5 xLim.(bname)(2)+0.5], ...
                    "XTick", xTick.(bname), "XTickLabel", {}, "XTickLabelRotation", 0, ...
                    "YLim", [0.5 nUnits+0.5], "YDir", "reverse", ... 
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                warp_data = warpSorted{i};
                warp_data = zscore(warp_data, 1, 2);
                imagesc(xLim.(bname), [1 nUnits], warp_data, options.ZscoreRange);
                line([0 0], [0.5 nUnits+0.5], 'LineStyle', lineStyle, 'Color', lineColor, 'LineWidth', lineWidth);
                colormap(h.(bname), mycolormap);
                if i == 1
                    set(h.(bname), "XTickLabel", xTickLabel.(bname));
                    xlabel(h.(bname), "Time from press (warped, ms)", ...
                        "HorizontalAlignment", "center", ...
                        "FontSize", fontSize.Label, "FontName", "Arial");
                    ylabel(h.(bname), "Units #", "FontSize", fontSize.Label, "FontName", "Arial");
                end

                title(h.(bname), titletext, "HorizontalAlignment", "center", ...
                    "FontSize", fontSize.Label, "FontName", "Arial", "FontWeight", "bold");

                % if plotFPlines
                     line(h.(bname), [warped.template(i,2) warped.template(i,2)], [0.5 nUnits+0.5], ...
                        'LineStyle', lineStyle, 'Color', 'r', 'LineWidth', lineWidth);
                % end
                line(h.(bname), [warped.template(i,3) warped.template(i,3)], [0.5 nUnits+0.5], ...
                   'LineStyle', lineStyle, 'Color', 'b', 'LineWidth', lineWidth);
                line(h.(bname), [warped.template(i,4) warped.template(i,4)], [0.5 nUnits+0.5], ...
                   'LineStyle', lineStyle, 'Color', 'g', 'LineWidth', lineWidth);

            end

            % hcbar1 = colorbar(h.a11, 'AxisLocation', 'in', 'Units', 'Centimeters', ...
            %     'Position',[xmap(4), ymap(1) lenAxes.ColorBar h8ColorBar], ...
            %     'YTick', options.NormRange, 'YTickLabel', string(options.NormRange), ...
            %     'TickDirection', 'out', 'TickLength', tickLen(2), ...
            %     'FontSize', fontSize.Axes, 'FontName', 'arial');
            % hcbarbel = ylabel(hcbar1, "Normalized FR", 'Rotation', 270, ...
            %     'FontSize', fontSize.Label, 'FontName', 'Arial');
            % hcbarbel.Position(1) = hcbarbel.Position(1)+3;

            hcbar2 = colorbar(h.Warp1, 'AxisLocation', 'in', 'Units', 'Centimeters', ...
                'Position',[xmap(7), ymap(1) lenAxes.ColorBar h8ColorBar], ...
                'YTick', [options.ZscoreRange(1) 0 options.ZscoreRange(2)], ...
                'YTickLabel', string([options.ZscoreRange(1) 0 options.ZscoreRange(2)]), ...
                'TickDirection', 'out', 'TickLength', tickLen(2), ...
                'FontSize', fontSize.Axes, 'FontName', 'arial');
            hcbarbel2 = ylabel(hcbar2, "Z-scored FR", 'Rotation', 270, ...
                'FontSize', fontSize.Label, 'FontName', 'Arial');
            hcbarbel2.Position(1) = hcbarbel2.Position(1)+3.3;

            % Plot waveforms
            for i = 1:nUnits
                ycol = ceil(i/nWave);
                xrow = i - nWave*(ycol-1);
                hawave = axes;
                set(hawave, 'Units', 'centimeters', 'NextPlot', 'add', ...
                    'Position', [xmap2(xrow) ymap2(ycol) lenAxes.Wave*3/4 lenAxes.Wave*1/2], ...
                    'XLim', [0 xLim.Wave], 'YLim', [min([min(meanWaves{i}) -800]) max([max(meanWaves{i}) 400])]);
                axis off;
                plot(1:xLim.Wave, meanWaves{i}, 'Color', lineColor, 'LineWidth', lineWidth);
                title(nameUnits(i), "FontSize", fontSize.Axes, "FontName", "Arial");
                
                if pvalMerge(i) >= 0.05
                    pvtext = "n.s.";
                elseif pvalMerge(i) >= 0.01
                    pvtext = "*";
                elseif pvalMerge(i) >= 0.001
                    pvtext = "**";
                else
                    pvtext = "***";
                end

                curYLim = get(gca, "YLim");
                if abs(curYLim(1)) > abs(curYLim(2))
                    ytext1 = curYLim(1)*2/3;
                else
                    ytext1 = curYLim(2)*2/3;
                end
                text(xLim.Wave*3/4, ytext1, [num2str(frAllSorted(i), "%.2f")+" Hz";pvtext], ...
                    "FontSize", fontSize.Label, "FontName", "Arial");
%                 text(xLim.Wave*3/4, ytext2, pvtext, "FontSize", fontSize.Label, "FontName", "Arial");
            end

            % ha00, add title text
            titleText = "Session summary: "+string(obj.BehaviorClass.Subject) + "-" + ...
                num2str(obj.BehaviorClass.Date) + "-" + string(obj.Meta(1).Protocol);
            ha00 = axes;
            set(ha00, 'units', 'centimeters', ...
                'position', [xmap2(1) ymap2(1)+lenAxes.Wave*2/3+ygap xmap2(end)-xmap2(1)+lenAxes.Wave 0.1]);
            axis off;
            title(titleText, 'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');

            %% Save Fig
            [~,~] = mkdir(pwd, "Fig");
            savename = fullfile(pwd, "Fig", "Session summary_"+string(obj.BehaviorClass.Subject)+"_"+ ...
                num2str(obj.BehaviorClass.Date)+"_"+string(obj.Meta(1).Protocol)+options.printName);
            if options.printPNG
                print(Fig, '-dpng', savename);
            end
            if options.printEPS
                print(Fig, '-depsc2', savename);
            end
            if options.printFIG
                saveas(Fig, savename, 'fig');
            end
            if options.printPDF
                print(Fig, '-dpdf', savename);
            end

        end

        function plotPopulationPSTH_AutoShaping(obj, options)
            arguments
                obj
                options.NormMethod  string {mustBeMember(options.NormMethod, ...
                    ["Normalize", "Rescale"])} = "Normalize"
                options.NormRange   double     = [0 1]
                options.ZscoreRange double     = [-4 4]
                options.printName   string     = ""
                options.printPNG   logical     = true
                options.printFIG   logical     = false
                options.printEPS   logical     = false
                options.printPDF   logical     = false
            end
            if isempty(obj.PSTHPop)
                disp("**** Calculate PSTHPop de novo ****");
                obj.calPopulationPSTH_AutoShaping();
            end
            paramMerge = obj.PSTHPop.paramMerge;
            spikeInfo  = obj.Units.SpikeNotes;
            nUnits = size(spikeInfo, 1);
            
            % Sort and check p-value using FP with max trialnum
            [~, tPeak] = max(obj.PSTHPop.psthMergeAll, [], 2);
            [~, idxSort] = sort(tPeak, 1, "ascend");

            stat.Trigger = cellfun(@(x) x.Trigger, obj.PSTHs.StatOut, "UniformOutput", false);
            stat.Reward  = cellfun(@(x) x.Reward,  obj.PSTHs.StatOut, "UniformOutput", false);
            pval = cellfun(@(x) x.pval, [stat.Trigger; stat.Reward]', "UniformOutput", true);
%             tpeak = cellfun(@(x) x.tpeak, [stat.Press; stat.Release; stat.Reward]', "UniformOutput", true);
            pvalMerge = min(pval,[],2);
            pvalMerge2Sort = pvalMerge(idxSort);
            
            idxSignificant = pvalMerge2Sort < 0.05;
            if ~isempty(idxSignificant)
                idxSort = [idxSort(idxSignificant); idxSort(~idxSignificant)];
%                 idxSignificant = [idxSignificant(idxSignificant); idxSignificant(~idxSignificant)];
            end

%             pval = pval(idxSort, :);
            pvalMerge = pvalMerge(idxSort);
            spikeInfo = spikeInfo(idxSort,:);
            meanWaves = obj.PSTHs.SpikeWave(idxSort);
            nameUnits = "Ch" + spikeInfo(:,1) + "U" + spikeInfo(:,2);

            % Remove FP less than 10 trials (for wait protocol)
            psthSorted  = obj.PSTHPop.psthMergeAll(idxSort,:);
            psthZSorted = obj.PSTHPop.psthMergeAllZ(idxSort,:);
            frAllSorted = obj.PSTHPop.frMergeAll(idxSort);
            nTrial = obj.PSTHPop.TrialNum;

            switch options.NormMethod
               case "Normalize"
                   psthSorted = normalize(psthSorted, 2, "range", options.NormRange);
               case "Rescale"
                   psthSorted = rescale(psthSorted, options.NormRange(1), options.NormRange(2), ...
                    "InputMin", min(x,[],2), "InputMax", max(x,[],2));
            end

            mycolormap = cold2warm;
            tickLen = [0.02 0.01];
            lineStyle = '--'; lineWidth = 1.5; lineColor = 'k';
            fontSize = struct("Axes", 7, "Label", 7, "Title", 9);

            xstart = 1; ystart = 1.5;  xgap = 0.15; ygap = 0.6; xgap2 = 5*xgap;
            h8Unit = 0.2; h8Axes = h8Unit*nUnits; 
            h8ColorBar = 2; lenAxes.ColorBar = 0.25;
            lenUnit = 1/50;

            popEvent = string(paramMerge.Properties.RowNames);
            for i = 1:length(popEvent)
                iEvent = popEvent(i);
                ipm = paramMerge(i,:);
                lenAxes.(iEvent)    = ipm.nbins*lenUnit;
                xLim.(iEvent)       = [-ipm.pre ipm.post]/ipm.binwidth;
                xTick.(iEvent)      = (-2000:500:2000)/ipm.binwidth;
                xTickLabel.(iEvent) = string(-2000:500:2000);
            end

            xmap(1) = xstart;
            xmap(2) = xmap(1) + xgap*1 + lenAxes.Trigger;
            xmap(3) = xmap(2) + xgap*3 + lenAxes.Reward;
            xmap(4) = xmap(3) + xgap2*2+ lenAxes.ColorBar;
            xmap(5) = xmap(4) + xgap*1 + lenAxes.Trigger;
            xmap(6) = xmap(5) + xgap*3 + lenAxes.Reward;
            xmap(7) = xmap(6) + xgap2  + lenAxes.ColorBar;

            ymap(1) = ystart;
            ymap(2) = ymap(1) + ygap*1 + h8Axes;

            if nUnits > 18; nWave = 8; else; nWave = 6; end
            lenAxes.Wave = (xmap(end-1)-xmap(1)-(nWave-1)*xgap2)/nWave;
            xLim.Wave = size(meanWaves{1}, 2);

            xmap2(1) = xstart; ymap2(1) = ymap(end) + ygap;
            for i = 2:nWave
                xmap2(i) = xmap2(i-1) + lenAxes.Wave + xgap2;
            end
            for i = 2:ceil(nUnits/nWave)
                ymap2(i) = ymap2(i-1) + lenAxes.Wave*2/3 + ygap;
            end
            ymap2 = fliplr(ymap2);


            Fig = figure(1); clf(Fig, "reset");
            set(Fig, 'units', 'centimeters', 'color', 'w', 'paperpositionmode', 'auto',...
                'position', [2 2 xmap(end) ymap2(1)+lenAxes.Wave*2/3+ygap+1]);

            for j = 1:length(popEvent)
                jEvent = popEvent(j);
                idxPlot = paramMerge(j,:).idxbins(1):paramMerge(j,:).idxbins(2);

                % Normalized
                aname = "a"+num2str(j);  % axes name
                h.(aname) = axes("Units", "centimeters", "NextPlot", "add", ...
                    "Position", [xmap(j) ymap(1) lenAxes.(jEvent) h8Axes], ...
                    "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", [xLim.(jEvent)(1)-0.5 xLim.(jEvent)(2)+0.5], ...
                    "XTick", xTick.(jEvent), "XTickLabel", xTickLabel.(jEvent), "XTickLabelRotation", 90, ...
                    "YLim", [0.5 nUnits+0.5], "YDir", "reverse", ... 
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                imagesc(xLim.(jEvent), [1 nUnits], psthSorted(:,idxPlot), options.NormRange);
                line([0 0], [0.5 nUnits+0.5], 'LineStyle', lineStyle, 'Color', lineColor, 'LineWidth', lineWidth);
                colormap(h.(aname), "parula");

                % Z-scored
                bname = "b"+num2str(j);  % axes name
                h.(bname) = axes("Units", "centimeters", "NextPlot", "add", ...
                    "Position", [xmap(j+3) ymap(1) lenAxes.(jEvent) h8Axes], ...
                    "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", [xLim.(jEvent)(1)-0.5 xLim.(jEvent)(2)+0.5], ...
                    "XTick", xTick.(jEvent), "XTickLabel", xTickLabel.(jEvent), "XTickLabelRotation", 90, ...
                    "YLim", [0.5 nUnits+0.5], "YDir", "reverse", ... 
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                imagesc(xLim.(jEvent), [1 nUnits], psthZSorted(:,idxPlot), options.ZscoreRange);
                line([0 0], [0.5 nUnits+0.5], 'LineStyle', lineStyle, 'Color', lineColor, 'LineWidth', lineWidth);
                colormap(h.(bname), mycolormap);

                if j == 1
                    xlabel(h.(aname), "Time from press / release / reward (ms)", ...
                        "HorizontalAlignment", "left", ...
                        "FontSize", fontSize.Label, "FontName", "Arial");
                    xlabel(h.(bname), "Time from press / release / reward (ms)", ...
                        "HorizontalAlignment", "left", ...
                        "FontSize", fontSize.Label, "FontName", "Arial");
                    titletext = "nTrials = "+num2str(nTrial);
                    title(h.(aname), titletext, ...
                        "HorizontalAlignment", "left", ...
                        "FontSize", fontSize.Label, "FontName", "Arial", "FontWeight", "bold");
                    ylabel(h.(aname), "Units #", "FontSize", fontSize.Label, "FontName", "Arial");

                    title(h.(bname), titletext, ...
                        "HorizontalAlignment", "left", ...
                        "FontSize", fontSize.Label, "FontName", "Arial", "FontWeight", "bold");
                    ylabel(h.(bname), "Units #", "FontSize", fontSize.Label, "FontName", "Arial");
                else
                    set(h.(aname), "YTick", [], "YTickLabel", {});
                    set(h.(bname), "YTick", [], "YTickLabel", {});
                end
            end
            hcbar1 = colorbar(h.a1, 'AxisLocation', 'in', 'Units', 'Centimeters', ...
                'Position',[xmap(3), ymap(1) lenAxes.ColorBar h8ColorBar], ...
                'YTick', options.NormRange, 'YTickLabel', string(options.NormRange), ...
                'TickDirection', 'out', 'TickLength', tickLen(2), ...
                'FontSize', fontSize.Axes, 'FontName', 'arial');
            hcbarbel = ylabel(hcbar1, "Normalized FR", 'Rotation', 270, ...
                'FontSize', fontSize.Label, 'FontName', 'Arial');
            hcbarbel.Position(1) = hcbarbel.Position(1)+3;

            hcbar2 = colorbar(h.b1, 'AxisLocation', 'in', 'Units', 'Centimeters', ...
                'Position',[xmap(6), ymap(1) lenAxes.ColorBar h8ColorBar], ...
                'YTick', [options.ZscoreRange(1) 0 options.ZscoreRange(2)], ...
                'YTickLabel', string([options.ZscoreRange(1) 0 options.ZscoreRange(2)]), ...
                'TickDirection', 'out', 'TickLength', tickLen(2), ...
                'FontSize', fontSize.Axes, 'FontName', 'arial');
            hcbarbel2 = ylabel(hcbar2, "Z-scored FR", 'Rotation', 270, ...
                'FontSize', fontSize.Label, 'FontName', 'Arial');
            hcbarbel2.Position(1) = hcbarbel2.Position(1)+3.3;

            % Plot waveforms
            for i = 1:nUnits
                ycol = ceil(i/nWave);
                xrow = i - nWave*(ycol-1);
                hawave = axes;
                set(hawave, 'Units', 'centimeters', 'NextPlot', 'add', ...
                    'Position', [xmap2(xrow) ymap2(ycol) lenAxes.Wave*3/4 lenAxes.Wave*1/2], ...
                    'XLim', [0 xLim.Wave], 'YLim', [min([min(meanWaves{i}) -800]) max([max(meanWaves{i}) 400])]);
                axis off;
                plot(1:xLim.Wave, meanWaves{i}, 'Color', lineColor, 'LineWidth', lineWidth);
                title(nameUnits(i), "FontSize", fontSize.Axes, "FontName", "Arial");
                
                if pvalMerge(i) >= 0.05
                    pvtext = "n.s.";
                elseif pvalMerge(i) >= 0.01
                    pvtext = "*";
                elseif pvalMerge(i) >= 0.001
                    pvtext = "**";
                else
                    pvtext = "***";
                end

                curYLim = get(gca, "YLim");
                if abs(curYLim(1)) > abs(curYLim(2))
                    ytext1 = curYLim(1)*2/3;
                else
                    ytext1 = curYLim(2)*2/3;
                end
                text(xLim.Wave*3/4, ytext1, [num2str(frAllSorted(i), "%.2f")+" Hz";pvtext], ...
                    "FontSize", fontSize.Label, "FontName", "Arial");
%                 text(xLim.Wave*3/4, ytext2, pvtext, "FontSize", fontSize.Label, "FontName", "Arial");
            end

            % ha00, add title text
            titleText = "Session summary: "+string(obj.BehaviorClass.Subject) + "-" + ...
                num2str(obj.BehaviorClass.Date) + "-" + string(obj.Meta(1).Protocol);
            ha00 = axes;
            set(ha00, 'units', 'centimeters', ...
                'position', [xmap2(1) ymap2(1)+lenAxes.Wave*2/3+ygap xmap2(end)-xmap2(1)+lenAxes.Wave 0.1]);
            axis off;
            title(titleText, 'FontSize', fontSize.Title, 'FontName', 'Arial', 'FontWeight', 'bold');

            %% Save Fig
            [~,~] = mkdir(pwd, "Fig");
            savename = fullfile(pwd, "Fig", "Session summary_"+string(obj.BehaviorClass.Subject)+"_"+ ...
                num2str(obj.BehaviorClass.Date)+"_"+string(obj.Meta(1).Protocol)+options.printName);
            if options.printPNG
                print(Fig, '-dpng', savename);
            end
            if options.printEPS
                print(Fig, '-depsc2', savename);
            end
            if options.printFIG
                saveas(Fig, savename, 'fig');
            end
            if options.printPDF
                print(Fig, '-dpdf', savename);
            end

        end

        % export rclass to ./sameNeuronCheck folder
        function prepare4SameNeuronCheck(obj, options)
            arguments
                obj
                options.saveName   = obj.saveName
                options.targetPath = []
                options.sameNeuronCheckMode = 0
            end
            if ~options.sameNeuronCheckMode
                curRClassName = string(dir("RClass_*.mat").name);
                if isscalar(curRClassName)
                    obj.save("saveName", curRClassName);
                else
                    disp("#### Multi RClass*.mat files in current directory ####");
                    return;
                end
            end

            if isempty(obj.EphysPop)
                disp("**** Using @calPopulationPSTH ****");
                obj.calPopulationPSTH();
            end

            nUnit = size(obj.Units.SpikeNotes, 1);
            for i = 1:nUnit
                obj.Units.SpikeTimes(i).AutoCorrelogram = obj.Ephys.AutoCorrelogram{i};
                obj.Units.SpikeTimes(i).ISI = obj.Ephys.ISI{i};
                [~, idxFP] = max(obj.EphysPop.TrialNum);
                obj.Units.SpikeTimes(i).PSTH = obj.EphysPop.psthMerge{idxFP}(i,:);
            end

            if ~isempty(options.targetPath)
                obj.Ephys = [];
                obj.EphysPop = [];
                obj.save("savePath", options.targetPath, "saveName", options.saveName);
            end
        end

        function glmFilter(obj, idxUnit, options)
            arguments
                obj 
                idxUnit 
                options.plotPSTH = true
            end
        end

    end
end