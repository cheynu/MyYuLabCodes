function tbl = sampleTrials(tbl, exp, num, mark, fps, flip)

    idx_exp = tbl.Experiment == exp;
    session = unique(tbl.Session(idx_exp), "sorted");
    if flip; session = flipud(session); end
    for ifp = 1:length(fps)
        idx_ifp = tbl.FP == fps(ifp);
        cnt = 0;
        for jsess = 1:length(session)
            idx_jsess = tbl.Session == session(jsess);
            idx_jsess_ifp = idx_jsess & idx_ifp;
            if sum(idx_jsess_ifp) <= num-cnt
                tbl.Sampled(idx_jsess_ifp) = mark;
                cnt = cnt + sum(idx_jsess_ifp);
            else
                idx_smpl = randperm(sum(idx_jsess_ifp), num-cnt);
                idx_jsess_ifp = find(idx_jsess_ifp);
                tbl.Sampled(idx_jsess_ifp(idx_smpl)) = mark;
                break;
            end
        end 
    end
end