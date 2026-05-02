function [rm, ranova_table, mult_table]=ChemoANOVA(data_table)
% datain is arranged as a matrix
% each column is data of all animals in one condition

% example provided by MATLAB
% T = readtable('q2_data.xlsx');
% T.Properties.VariableNames = {'T1_TP1', 'T1_TP2', 'T1_TP3', 'T1_TP4', 'T1_TP5', 'T1_TP6', ... 
%     'T2_TP1', 'T2_TP2', 'T2_TP3', 'T2_TP4', 'T2_TP5', 'T2_TP6' };
% withinDesign = table([1 1 1 1 1 1 2 2 2 2 2 2]',[1:6 1:6]','VariableNames',{'Treatment','TimePeriod'});
% withinDesign.Treatment = categorical(withinDesign.Treatment);
% withinDesign.TimePeriod = categorical(withinDesign.TimePeriod);
% rm = fitrm(T, 'T1_TP1-T2_TP6~1', 'WithinDesign', withinDesign);
% ranova(rm, 'WithinModel', 'Treatment*TimePeriod') 

withinDesign = table([1 1  2 2  3 3  4 4]', [1 2 1 2 1 2 1 2]', 'VariableNames', {'FP', 'Condition'});
withinDesign.FP = categorical(withinDesign.FP);
withinDesign.Condition = categorical(withinDesign.Condition);
rm = fitrm(data_table, 's_sal-x_dcz~1', 'WithinDesign', withinDesign);
ranova_table = ranova(rm, 'WithinModel', 'FP*Condition');

 [mult_table] =  multcompare(rm, 'Condition',  'By', 'FP');