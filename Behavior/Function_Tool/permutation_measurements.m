function pval = permutation_measurements(v1, v2, parameter)
% v1 and v2 are random variables from two condtions. we use permutation
% test to see if they are the same.
nperm = 5000;
switch parameter

    case 'median'
        v1_median = median(v1);
        v2_median = median(v2);
        diff_v12 = abs(v1_median-v2_median);
        n1 = length(v1);
        n2 = length(v2);
        v12 = [v1 v2];
        num_extreme = 0;
        for i =1:nperm
            perm_index = randperm(n1+n2, n1+n2);
            v12_perm = v12(perm_index);
            v1_perm = v12_perm(1:n1);
            v2_perm = v12_perm(n1+1:end);
            v1_perm_median = median(v1_perm);
            v2_perm_median = median(v2_perm);
            if abs(v1_perm_median-v2_perm_median)>diff_v12
                num_extreme = num_extreme+1;
            end
        end
        pval =num_extreme/nperm;
        sprintf('p vals for the difference in median is %2.4f', pval)

    case 'var'
        v1_var = var(v1);
        v2_var = var(v2);
        diff_v12 = abs(v1_var-v2_var);
        n1 = length(v1);
        n2 = length(v2);
        v12 = [v1 v2];
        num_extreme = 0;
        for i =1:nperm
            perm_index = randperm(n1+n2, n1+n2);
            v12_perm = v12(perm_index);
            v1_perm = v12_perm(1:n1);
            v2_perm = v12_perm(n1+1:end);
            v1_perm_var = var(v1_perm);
            v2_perm_var = var(v2_perm);
            if abs(v1_perm_var-v2_perm_var)>diff_v12
                num_extreme = num_extreme+1;
            end
        end
        pval =num_extreme/nperm;
        sprintf('p vals for the difference in var is %2.4f', pval)

    case 'sd'
        v1_var = std(v1);
        v2_var = std(v2);
        diff_v12 = abs(v1_var-v2_var);
        n1 = length(v1);
        n2 = length(v2);
        v12 = [v1 v2];
        num_extreme = 0;
        for i =1:nperm
            perm_index = randperm(n1+n2, n1+n2);
            v12_perm = v12(perm_index);
            v1_perm = v12_perm(1:n1);
            v2_perm = v12_perm(n1+1:end);
            v1_perm_var = std(v1_perm);
            v2_perm_var = std(v2_perm);
            if abs(v1_perm_var-v2_perm_var)>diff_v12
                num_extreme = num_extreme+1;
            end
        end
        pval =num_extreme/nperm;
        sprintf('p vals for the difference in std is %2.4f', pval)


    case 'iqr'
        v1_iqr = iqr(v1);
        v2_iqr = iqr(v2);
        diff_v12 = abs(v1_iqr-v2_iqr);
        n1 = length(v1);
        n2 = length(v2);
        v12 = [v1 v2];
        num_extreme = 0;
        for i =1:nperm
            perm_index = randperm(n1+n2, n1+n2);
            v12_perm = v12(perm_index);
            v1_perm = v12_perm(1:n1);
            v2_perm = v12_perm(n1+1:end);
            v1_perm_iqr = iqr(v1_perm);
            v2_perm_iqr = iqr(v2_perm);
            if abs(v1_perm_iqr-v2_perm_iqr)>diff_v12
                num_extreme = num_extreme+1;
            end
        end
        pval =num_extreme/nperm;
        sprintf('p vals for the difference in iqr is %2.4f', pval)

    case 'mode'
        tbins = (0:0.01:4);
        bw = 0.1;
        f1 = ksdensity(v1, tbins, 'Bandwidth',bw, 'Function','pdf');
        peak1 = tbins(f1==max(f1));
        f2 = ksdensity(v2, tbins, 'Bandwidth',bw, 'Function','pdf');
        peak2 = tbins(f2==max(f2));
        diff_peak12 = abs(peak1-peak2);

        nperm = 5000;
        n1 = length(v1);
        n2 = length(v2);
        v12 = [v1 v2];

        num_extreme = 0;
        for i =1:nperm
            perm_index = randperm(n1+n2, n1+n2);
            v12_perm = v12(perm_index);
            v1_perm = v12_perm(1:n1);
            v2_perm = v12_perm(n1+1:end);

            f1 = ksdensity(v1_perm, tbins, 'Bandwidth',bw, 'Function','pdf');
            peak1perm = tbins(f1==max(f1));
            f2 = ksdensity(v2_perm, tbins, 'Bandwidth',bw, 'Function','pdf');
            peak2perm = tbins(f2==max(f2));
            diff_peak12perm = abs(peak1perm-peak2perm);
            if diff_peak12perm>diff_peak12
                num_extreme = num_extreme+1;
            end
        end
        pval =num_extreme/nperm;
        sprintf('p vals for the mode is %2.4f', pval)

    case 'gauss1'
        %      f1(x) =  a1*exp(-((x-b1)/c1)^2)
        num_perm              =       5000;
        xbins                       =       (0:0.1:4);
        kernel_bw               =       0.08; 
        pdf1                        =       ksdensity(v1, xbins,'BandWidth', kernel_bw);
        pdf2                        =       ksdensity(v2, xbins,'BandWidth', kernel_bw);
        f1                            =       fit(xbins', pdf1' , 'gauss1');
        f2                            =       fit(xbins', pdf2' , 'gauss1');

        delta_a1                 =      abs(f1.a1-f2.a1);
        delta_b1                 =      abs(f1.b1-f2.b1);
        delta_c1                 =      abs(f1.c1-f2.c1);

        a1_perm  = zeros(1, num_perm);
         b1_perm  = zeros(1, num_perm);
         c1_perm  = zeros(1, num_perm);
 
        vall = [v1 v2];
        n1 = length(v1);
        n2 = length(v2);

        tic
        for i =1:num_perm
            vall_perm                         = vall(randperm(n1+n2, n1+n2));
            pdf1_perm                        =       ksdensity(vall_perm(1:n1), xbins,'BandWidth', kernel_bw);
            pdf2_perm                        =       ksdensity(vall_perm(n1+1:n1+n2), xbins,'BandWidth', kernel_bw);
            f1                                          =       fit(xbins', pdf1_perm' , 'gauss1');
            f2                                          =       fit(xbins', pdf2_perm' , 'gauss1');
            a1_perm(i)                          =       (f1.a1-f2.a1);
            b1_perm(i)                          =       (f1.b1-f2.b1);
            c1_perm(i)                          =       (f1.c1-f2.c1);
        end
        toc
 
end
