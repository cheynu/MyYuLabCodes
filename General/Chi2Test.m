function [p_value, chi_stat, dof] = Chi2Test(Data)

% Jianing Yu 12/15/2023
% Data: Row represents subgroups, Column represents categories
% Data = [
%    % 1-3 4-6 7-9  
%     111 96 48      % community college students
%     96 133 61   % four-year college students
%     91 150 53   % nonstudents
%     ];

sample_size     = sum(Data(:));
sample_size_subgroups = sum(Data, 2);
% disp(sample_size_subgroups);
% Estimate distribution
p_0             = sum(Data, 1)/sample_size;
disp(p_0)
% Compute expectation
Expectation     = sample_size_subgroups*p_0;
% disp(Data)
% disp(Expectation)
Squared_Difference = (Expectation-Data).^2;
% disp(Squared_Difference);
% Normalized by the expected value
Squared_Difference_Norm = Squared_Difference./Expectation;
% disp(Squared_Difference_Norm);
% Compute test statistic
T = sum(Squared_Difference_Norm(:));
dof = (size(Data, 1)-1)*(size(Data, 2)-1);
p_value = 1-chi2cdf(T, dof);

chi_stat=T;
disp([T, dof])
xx = linspace(0, 20, 1000);
yy = chi2pdf(xx, dof);
% 
figure;
plot(xx, yy, 'r', 'linewidth', 1);
hold on
line([1 1]*T, get(gca, 'ylim'), 'color', 'c','linewidth', 2)
xlabel('Chi-square')
ylabel('Density')

line([14 15], [0.002 0.06],'color','k')
text(14, 0.065, sprintf('p-val: %2.2f', p_value))
legend('Chi2 distribution', 'test stat.')