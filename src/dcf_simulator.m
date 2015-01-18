%%% DCF Monte Carlo simulator

% Parameters
timeSteps = 100000;
p = 0.5; % conditional collision probability
Wmin = 2;
Wmax = 4; %1024;
m = log2(Wmax / Wmin);
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^(i-1)) * Wmin;
end

% State variables
timer = 0;
stage = 0;

% Statistical accumulator variables
successes = 0;
failures = 0;

% Initialize the state
%   - pick random backoff stage
timer = floor(rand(1) * W(1,1));

for T = 1:timeSteps
   if (backoffTimer > 0)
      k = k - 1; 
   else
       txSuccess = rand(1) < (1 - p); 
       if (txSuccess == 1) % if success, go to stage 0 with random backoff k
          successes = successes + 1;
          stage = 0;
          timer = floor(rand(1) * W(1,1));
       else % collision, go to the next backoff stage and choose a new random timer
           failures = failures + 1;
           if (stage ~= m) % loop at stage m
              stage = stage + 1; 
           end
           timer = floor(rand(1) * W(1,stage));
       end
   end
end

% Results
disp(sprintf('Successes =  %d', successes))
disp(sprintf('Failures =  %d', failures))