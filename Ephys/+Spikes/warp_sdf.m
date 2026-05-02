function vw = warp_sdf(t1, v1, tw)
% 4/23/2024 JY
% warp (t1, v1) to tw

vw = zeros(1, length(tw));
bins1 = (0:length(t1)-1);
bins2 = (0:length(tw)-1);
scale_factor = length(bins1)/length(bins2);

for i =1:length(bins2)
    if i == 1
        vw(i) = v1(1);
    elseif i ==length(bins2)
        vw(i)= v1(end);
    else
        omega_i = i*scale_factor; % e.g., if bins1: [1:7], bins2 [1:11], then (i/11)*7 corresponds to data in t1                                                 
        if omega_i == ceil(omega_i)
            this_interp = v1(omega_i);
        else
            this_interp = (ceil(omega_i)-omega_i)*v1(max([1, floor(omega_i)]))+(omega_i-floor(omega_i))*v1(min([ceil(omega_i), length(v1)]));
        end
        vw(i)=this_interp;
    end
end

