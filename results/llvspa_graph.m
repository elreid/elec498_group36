clear;
close all;

g_test = [13340, 13452, 13547, 13726, 13819];
zero_test = [13598, 13709, 13802, 13895, 13988];

ll = [3, 13, 24, 51, 232];
pa = [2, 3, 4, 7, 38];


f = figure;
plot(ll, '-o')
hold on
plot(pa, '-o')

title('CPU Time Used for Linked List vs Populate Array')
xlabel('Number of elements')
ylabel('CPU Time Used')
legend('Linked List', 'Populate Array')

xticklabels({'10','', '250', '', '500','', '1000', '', '5000'})


