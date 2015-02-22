function dcf_rand_filesize()
niter = 100000;
mean = 1000;
variance = 1000;
max_val = mean + 10 * variance;
nplots = 9;

% Poisson
% lambda = mean
poisson_lambda = mean;
poisson_offset = 0;
poisson_multiplier = 4;

% Normal
% mu = mean
% sigma = variance
normal_mu = mean;
normal_sigma = variance;
normal_offset = 4*mean;
normal_multiplier = 1;

% Extreme Value
% mu = mean
% sigma = variance
extremevalue_mu = mean;
extremevalue_sigma = variance;
extremevalue_offset = 4*mean;
extremevalue_multiplier = 1;

% Binomial
% N = number of trials
% p = prob of success
binomial_N = 1000;
binomial_p = 0.05;
binomial_offset = 0;
binomial_multiplier = mean/10;

% Random Walk
% median = start point
% p = probability of exit
% step = size of step
randwalk_median = 5000;
randwalk_p_exit = 0.004;
randwalk_p_stay = 0.996;
randwalk_right_step = 1;
randwalk_left_step = 1;
randwalkn_num_states = 12;

randwalk1_p_exit = 0.003;
randwalk1_max_startstate = 3;
randwalk1_state_total = 13;

randwalk2_p_exit = 0.003;
randwalk2_max_startstate = 3;
randwalk2_state_total = 14;

randwalk3_p_exit = 0.003;
randwalk3_max_startstate = 3;
randwalk3_state_total = 15;

randwalk4_p_exit = 0.003;
randwalk4_max_startstate = 3;
randwalk4_state_total = 16;

randwalk5_p_exit = 0.003;
randwalk5_max_startstate = 3;
randwalk5_state_total = 17;


% test multiple methods of different random distributions
values = zeros(niter, nplots);
names = cell(nplots,1);
count = 0;

% Poisson
count = count + 1;
poisson_dist = makedist('Poisson','lambda',poisson_lambda);
poisson_values = random(poisson_dist, niter, 1);
values(:,count) = poisson_multiplier * (poisson_offset + poisson_values);
names{count} = 'Poisson';

% Normal
count = count + 1;
normal_dist = makedist('Normal', 'mu', normal_mu, 'sigma', normal_sigma);
normal_values = random(normal_dist, niter, 1);
values(:,count) = normal_multiplier * (normal_offset + normal_values);
names{count} = 'Normal';

% Extreme Value
count = count + 1;
extremevalue_dist = makedist('ExtremeValue', 'mu', extremevalue_mu, 'sigma', extremevalue_sigma);
extremevalue_values = random(extremevalue_dist, niter, 1);
values(:,count) = extremevalue_multiplier * (extremevalue_offset + extremevalue_values);
names{count} = 'Extreme Value';

% Binomials
count = count + 1;
binomial_dist = makedist('Binomial', 'N', binomial_N, 'p', binomial_p);
binomial_values = random(binomial_dist, niter, 1);
values(:,count) = binomial_multiplier * (binomial_offset + binomial_values);
names{count} = 'Binomial';
% 
% % Random walk
% % 3 states, the exit state and the walking left and walking right states
% count = count + 1;
% randwalk_values = zeros(niter,1);
% for i=1:niter
%     size = randwalk_median;
%     state = 1;
%     while (state ~= 0)
%         r = rand();
%         
%         % We have previously walked right
%         if (state == 1)
%             if (r < randwalk_p_stay)
%                 % Walk right again
%                 size = size + randwalk_right_step;
%             else
%                 % Walk left and move states
%                 size = size - randwalk_left_step;
%                 state = 2;
%             end
%         % We have previously walked left
%         else
%             if (r < randwalk_p_stay)
%                 % Walk left again
%                 size = size - randwalk_left_step;
%             else
%                 % Walk right and move states
%                 size = size + randwalk_right_step;
%                 state = 1;
%             end
%         end
%         
%         % check for exit condition
%         r = rand();
%         if (r < randwalk_p_exit)
%             state = 0;
%         end
%     end
%     
%     randwalk_values(i,1) = size;
% end
% 
% values(:,count) = randwalk_values;
% names{count} = 'Rand Walk';
% 
% 
% % Random walk 2
% % 2 states, the spin state and the exit state
% count = count + 1;
% randwalk2_values = zeros(niter,1);
% for i=1:niter
%     size = 0;
%     state = 1;
%     while (state ~= 0)
%         size = size + randwalk_right_step;
%         
%         % check for exit condition
%         r = rand();
%         if (r < randwalk_p_exit)
%             state = 0;
%         end
%     end
%     
%     % choose walk direction
%     r = rand();
%     if (r < 0.5)
%         size = randwalk_median + size;
%     else
%         if (size > randwalk_median)
%             size = 0;
%         else
%             size = randwalk_median - size;
%         end
%     end
%     
%     randwalk2_values(i,1) = size;
% end
% 
% values(:,count) = randwalk2_values;
% names{count} = 'Rand Walk 2';
% 
% 
% % Random walk 3
% % 3 states, the exit state, the filesize min state, loop until we find our start for
% % filesize. the filesize compute state, loop until we exit to determine
% % final size
% count = count + 1;
% randwalk3_values = zeros(niter,1);
% for i=1:niter
%     size = 0;
%     state = 1;
%     while (state ~= 0)
%         size = size + 1;
%         
%         r = rand();
%         if (r < randwalk_p_exit)
%             state = state + 1;
%             if (state == randwalkn_num_states)
%                 state = 0;
%             end
%         end
%     end
%     
%     randwalk3_values(i,1) = size;
% end
% 
% values(:,count) = randwalk3_values;
% names{count} = 'Rand Walk 3';
% 
% % Random walk 4
% % same as rand walk 3 but with double the states
% count = count + 1;
% randwalk4_values = zeros(niter,1);
% for i=1:niter
%     size = 0;
%     state = 1;
%     while (state ~= 0)
%         size = size + 1;
%         
%         r = rand();
%         if (r < randwalk_p_exit)
%             state = state + 1;
%             if (state == (randwalkn_num_states*2))
%                 state = 0;
%             end
%         end
%     end
%     
%     randwalk4_values(i,1) = size;
% end
% 
% values(:,count) = randwalk4_values;
% names{count} = 'Rand Walk 4';


% Random walk - trying to emulate normal distribution
% start in a random state, only move forward through symmetric states
count = count + 1;
randwalk1_values = zeros(niter,1);
for i=1:niter
    randwalk1_values(i,1) = randwalk(randwalk1_p_exit, randwalk1_max_startstate, randwalk1_state_total);
end
values(:,count) = randwalk1_values;
names{count} = 'Rand Walk 1';

count = count + 1;
randwalk2_values = zeros(niter,1);
for i=1:niter
    randwalk2_values(i,1) = randwalk(randwalk2_p_exit, randwalk2_max_startstate, randwalk2_state_total);
end
values(:,count) = randwalk2_values;
names{count} = 'Rand Walk 2';

count = count + 1;
randwalk3_values = zeros(niter,1);
for i=1:niter
    randwalk3_values(i,1) = randwalk(randwalk3_p_exit, randwalk3_max_startstate, randwalk3_state_total);
end
values(:,count) = randwalk3_values;
names{count} = 'Rand Walk 3';

count = count + 1;
randwalk4_values = zeros(niter,1);
for i=1:niter
    randwalk4_values(i,1) = randwalk(randwalk4_p_exit, randwalk4_max_startstate, randwalk4_state_total);
end
values(:,count) = randwalk4_values;
names{count} = 'Rand Walk 4';

count = count + 1;
randwalk5_values = zeros(niter,1);
for i=1:niter
    randwalk5_values(i,1) = randwalk(randwalk5_p_exit, randwalk5_max_startstate, randwalk5_state_total);
end
values(:,count) = randwalk5_values;
names{count} = 'Rand Walk 5';

% plot all the options
figure;

for i = 1:nplots
    data = values(:,i);
    
    % get rid of negative values
    goodindices = (data > 0);
    data = data(goodindices);
    
    % get rid of very large values for plotting purposes
    goodindices = (data <= max_val);
    data = data(goodindices);
    
    % make sure we plot the entire range (not sure how to set this in the
    % hist funciton
    data(1) = 0;
    data(2) = max_val;
    
    subplot(3,3,i);
    hist(data,100);
    title(names(i));
end