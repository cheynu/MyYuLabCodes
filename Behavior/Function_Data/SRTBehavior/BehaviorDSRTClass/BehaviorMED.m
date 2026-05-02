classdef BehaviorMED < BehaviorSRT
    % Yu Chen, Apr 2023
    % Inherit from BehaviorDSRT class
    % Data calculated by BehaviorClass (by Jianing Yu)
    
    properties
        RawData
    end
    
    methods
        function obj = BehaviorMED(medfile,bpodfile,MEDProtocol)
            %BEHAVIORMED 构造此类的实例
            arguments
                medfile char {mustBeFile}
                bpodfile = [] % filename or SessionData struct
                MEDProtocol string {mustBeMember(MEDProtocol, ...
                            ["AutoShaping", "LeverPress", "LeverRelease", ...
                             "Wait1", "Wait2", "Wait", "2FPs", "3FPs"])} = "2FPs"
            end

            % pre-process by BehaviorClass of JianingYu
            [b,bc] = TrackMEDBehavior(medfile, MEDProtocol);

            % Assignment
            % basic information
            data = struct;
            data.Subject = bc.Subject;
            data.Experiment = b.Metadata.Experiment;
            data.Date = str2double(bc.Date);
            data.DateTime = datetime([b.Metadata.Date 'T' b.Metadata.StartTime],'InputFormat','yyyyMMdd''T''HH:mm:ss');
            
            calDark = true;
            switch bc.Protocol
                case {"LeverPress", "LeverPressBpod", "LeverPressBpodEphys"}
                    data.Task = "LeverPress"; calDark = false;
                case {"LeverRelease", "LeverReleaseBpod", "LeverReleaseBpodEphys"}
                    data.Task = "LeverRelease"; calDark = false;
                case {"Wait1", "Wait1Bpod", "Wait1BpodLearning"}
                    data.Task = "Wait1";
                case {"Wait2", "Wait2Bpod", "Wait2BpodLearning"}
                    data.Task = "Wait2";
                case {"3FPs", "ThreeFPs"}
                    data.Task = "3FPs";
                case {"2FPs", "TwoFPs"}
                    data.Task = "2FPs";
            end
            
            % data.MixedFP = round(bc.MixedFP./1000,2);

            idxDark = find(ismember(bc.Outcome,{'Dark'}));
            idxTrial = find(ismember(bc.Outcome,bc.PerformanceType));

            data.nTrial = length(idxTrial);
            data.iTrial = (1:data.nTrial)';
            % data.BlockNum = ones(data.nTrial,1);a
            % data.TrialNum = data.iTrial;
            % data.TrialType = repelem("Lever",data.nTrial)';
            % data.ConfuseNum = zeros(data.nTrial,1);
            data.TimeElapsed = bc.PressTime(idxTrial)';
            % FP & RW
            if isempty(bc.FP) % Wait Period
                b = UpdateWaitB(b);
                bc.FP = b.FPs;
            end
            data.FP = bc.FP(idxTrial)'./1000;
            data.RW = nan(data.nTrial,1);
            % Outcome
            outcome = string(bc.Outcome(idxTrial));
            outcome = replace(outcome,{'Correct','Premature'},{'Cor','Pre'});
            data.Outcome = outcome';
            % Reaction time & Hold time
            rt = bc.ReactionTime(idxTrial);
            rt(outcome=="Pre" | outcome=="Late") = NaN;
            data.RT = rt';
            
            data.HT = (bc.ReleaseTime(idxTrial) - bc.PressTime(idxTrial))';

            % darktry
            % if calDark
            %     idxDarkIni = [1 find(diff(idxDark)>1)+1];
            %     darkNum = [diff(idxDarkIni) length(idxDarkIni(end):length(idxDark))];
            %     idxDarkTrial = idxDark(idxDarkIni)-1;
            %     darktry = zeros(data.nTrial,1);
            %     darktry(ismember(idxTrial,idxDarkTrial)) = darkNum;
            %     data.DarkTry = darktry;
            % end
            
            % add Movement time
            if ~isempty(bpodfile)
                switch class(bpodfile)
                    case 'struct'
                        sd = bpodfile;
                    otherwise
                        mustBeFile(bpodfile);
                        load(bpodfile,'SessionData');
                        sd = SessionData;
                end
                % Extract BPOD data
                trialStart = nan(1,sd.nTrials);
                medTTL = nan(1,sd.nTrials);
                mt = nan(1,sd.nTrials);
                for i=1:sd.nTrials
                    trialStart(i) = sd.TrialStartTimestamp(i);
                    % Bpod states are different between MedLick & MedOptoRec protocols
                    if isfield(sd.RawEvents.Trial{i}.States, 'WaitForPokedIn')
                        medTTL(i) = sd.RawEvents.Trial{i}.States.WaitForPokedIn(1); % if ~isnan, then mt ~isnan
                        imt = diff(sd.RawEvents.Trial{i}.States.WaitForPokedIn);
                        mt(i) = imt(end);
                    elseif isfield(sd.RawEvents.Trial{i}.States, 'BriefReward')
                        medTTL(i) = sd.RawEvents.Trial{i}.States.BriefReward(1); % if ~isnan, then mt ~isnan
                        imt = diff(sd.RawEvents.Trial{i}.States.WaitForRewardEntry);
                        mt(i) = imt(end);
                    elseif isfield(sd.RawEvents.Trial{i}.States, 'WaitForRewardEntry')
                        medTTL(i) = sd.RawEvents.Trial{i}.States.WaitForRewardEntry(1); % if ~isnan, then mt ~isnan
                        imt = diff(sd.RawEvents.Trial{i}.States.WaitForRewardEntry);
                        mt(i) = imt(end);
                    else
                        error('Check Bpod MedTTL States');
                    end
                end
                % Align BPOD to MED
                t_BPOD = trialStart + medTTL;
                idxTTL = ~isnan(t_BPOD);
                t_BPOD = t_BPOD(idxTTL);
                mt = mt(idxTTL);
                idxCL = data.Outcome=="Cor" | data.Outcome=="Late";
                if calDark
                    t_MED = data.TimeElapsed(idxCL) + data.FP(idxCL); % Tone
                else
                    t_MED = data.TimeElapsed(idxCL);
                end
                
                tTTLIndexBpod2MED = findseqmatchrev(t_MED, t_BPOD, 0, 0); % each TTL(bpod) in MED timestamp
                idxNotNan = ~isnan(tTTLIndexBpod2MED);
                tTTLIndexBpod2MED = tTTLIndexBpod2MED(idxNotNan);
                MT_medAll = nan(data.nTrial,1);
                MT_medCL = nan(sum(idxCL),1);
                MT_medCL(tTTLIndexBpod2MED) = mt(idxNotNan);
                MT_medAll(idxCL) = MT_medCL;
                data.MT = MT_medAll;
            else
                data.MT = nan(data.nTrial,1);
            end

            close all;
            % Inherit
            obj@BehaviorSRT(data);

            % New properties
            obj.RawData = bc;
        end
    end
end

