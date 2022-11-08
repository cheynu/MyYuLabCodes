function newDLC = unifyDLCformat(DLCin)
    if isfield(DLCin,'DLCTrackingOut')
        DLC = DLCin.DLCTrackingOut;
    elseif isfield(DLCin,'PoseTracking')
        DLC = DLCin;
    else
        warning('Invalid input format');
    end
    sess = DLC.Session;
    if contains(sess,'DSRT')
        idx_udl = strfind(sess,'_');
        date = strrep(sess(idx_udl(end-1):end),'_','');
        name = sess(1:idx_udl(1)-1);
        newSess = [date(1:4),'-',date(5:6),'-',date(7:8),'-',date(9:10),'h',date(11:12),'m-Subject ',name];
        DLC.Session = newSess;
    end
    newDLC = DLC;
end