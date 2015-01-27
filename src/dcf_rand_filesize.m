function dcf_rand_filesize()
niter = 160000;
mean = 1000;
variance = 1000;
max_val = mean + 10 * variance;

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

% Exponential
% mu = mean
exponential_mu = mean;
exponential_offset = 0;
exponential_multiplier = 1;

% Lognormal
% mu = log(mean)
% sigma = log(variance)
lognormal_mu = log(mean);
lognormal_sigma = log(variance);
lognormal_offset = 0;
lognormal_multiplier = 1;

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

% test multiple methods of different random distributions
values = zeros(niter, 6);
names = cell(6,1);
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

% Exponential
count = count + 1;
exponential_dist = makedist('Exponential', 'mu', exponential_mu);
exponential_values = random(exponential_dist, niter, 1);
values(:,count) = exponential_multiplier * (exponential_offset + exponential_values);
names{count} = 'Exponential';

% Lognormal
count = count + 1;
lognormal_dist = makedist('Lognormal', 'mu', lognormal_mu, 'sigma', lognormal_sigma);
lognormal_values = random(lognormal_dist, niter, 1);
values(:,count) = lognormal_multiplier * (lognormal_offset + lognormal_values);
names{count} = 'Lognormal';

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


% plot all the options
figure;

for i = 1:6
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
    
    subplot(3,2,i);
    hist(data,100);
    title(names(i));
end