clear;
close all;

g_test = [13340, 13452, 13547, 13726, 13819];
zero_test = [13598, 13709, 13802, 13895, 13988];
one_test = [13530, 13706, 13863, 14019, 14175];
two_test = [13246, 13374, 13487, 13599, 13710];


f = figure;
plot(g_test, '-o')
hold on
plot(zero_test, '-o')
hold on
plot(one_test, '-o')
hold on
plot(two_test, '-o')

title('GPU Optimization Results')
xlabel('Workloads')
ylabel('Completion times')
legend('N/A', 'O0', '01', '02')

xticklabels({'1','', '2', '', '3','', '4', '', '5'})


