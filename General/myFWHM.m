function [width,tlead,ttrail] = myFWHM(x,y,options)
% function width = fwhm(x,y)
%
% Full-Width at Half-Maximum (FWHM) of the waveform y(x)
% and its polarity.
% The FWHM result in 'width' will be in units of 'x'
% Rev 1.2, April 2006 (Patrick Egan)
%
% 2024.8.27, Yu Chen, revised from Patrick's function "fwhm"
%   width:      full-width at half-maximum of the waveform y(x)
%   tlead:      the first point intersected by y=Imax/2 (if number > 1)
%   ttrail:     the first point intersected by y=Imax/2 after peak (if number > 1)
%   options:
%       minPeakDistance: extend the ttrail if next point intersected by
%           y=Imax/2 is within minPeakDistance (x distance)

arguments
    x
    y
    options.minPeakDistance = []
end
minDist = options.minPeakDistance;

if isempty(minDist)
    y = y / max(y);
    N = length(y);
    lev50 = 0.5;
    if y(1) < lev50                  % find index of center (max or min) of pulse
        [~,centerindex]=max(y);
        Pol = 'Positive';
    %     disp('Pulse Polarity = Positive')
    else
        [~,centerindex]=min(y);
        Pol = 'Negative';
    %     disp('Pulse Polarity = Negative')
    end
    i = 2;
    while sign(y(i)-lev50) == sign(y(i-1)-lev50)
        i = i+1;
    end                                   %first crossing is between v(i-1) & v(i)
    interp = (lev50-y(i-1)) / (y(i)-y(i-1));
    tlead = x(i-1) + interp*(x(i)-x(i-1));
    i = centerindex+1;                    %start search for next crossing at center
    while ((sign(y(i)-lev50) == sign(y(i-1)-lev50)) & (i <= N-1))
        i = i+1;
    end
    if i ~= N
    %     disp('Pulse is Impulse or Rectangular with 2 edges')
        interp = (lev50-y(i-1)) / (y(i)-y(i-1));
        ttrail = x(i-1) + interp*(x(i)-x(i-1));
        width = ttrail - tlead;
    else
    %     disp('Step-Like Pulse, no second edge')
        ttrail = NaN;
        width = NaN;
    end
else
    [pk,ind_pk] = max(y);
    hfPk = pk/2;
    idxLead = find(sign(y(2:end)-hfPk) ~= sign(y(1:end-1)-hfPk) & x(2:end)<x(ind_pk)) + 1;
    idxTrail = find(sign(y(2:end)-hfPk) ~= sign(y(1:end-1)-hfPk) & x(2:end)>x(ind_pk)) + 1;
%     idxLead = find(y(2:end)>=0.5*pk &...
%         y(1:end-1)<0.5*pk &...
%         x(2:end)<x(ind_pk)) + 1;
%     idxTrail = find(y(2:end)<=0.5*pk &...
%         y(1:end-1)>0.5*pk &...
%         x(2:end)>x(ind_pk)) + 1;

    iLead = idxLead(1);
    interLead = [iLead-1 iLead];
    tlead = interp1(y(interLead),x(interLead),hfPk);

    if length(idxTrail)>1
        dVal = diff(x(idxTrail));
        idx = 1;
        for idVal=1:length(dVal)
            if dVal(idVal)<minDist
                idx = idx + 1;
            else
                break;
            end
        end
        iTrail = idxTrail(idx);
    else
        iTrail = idxTrail(1);
    end
    interTrail = [iTrail-1 iTrail];
    ttrail = interp1(y(interTrail),x(interTrail),pk/2);
    width = ttrail - tlead;
end

end