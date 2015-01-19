%%% DCF Monte Carlo simulator

% Parameters
timeSteps = 10000000; % number of time steps to emulate
N = 2; % number of nodes
Wmin = 2;
Wmax = 4; %1024;
m = log2(Wmax / Wmin);
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^(i-1)) * Wmin;
end

% State variables
timer = zeros(1,N);
stage = zeros(1,N);
nodeOrder = zeros(1,N);

% Statistical accumulator variables
successes = zeros(1,N);
failures = zeros(1,N);
% attempts = successes + failures

% Initialize the state
%   - pick random backoff stage
for n = 1:N
    timer(1,n) = floor(rand(1) * W(1,1));
    nodeOrder(1,n) = n; % sequential order to start
end

for T = 1:timeSteps
    
   % Shuffle the nodes so that they are handled in a different order
   for n = N:-1:1
       index = randi(N);
       temp = nodeOrder(index);
       nodeOrder(index) = nodeOrder(n);
       nodeOrder(n) = temp;
   end
   
   collisions = zeros(1,N); % assume no one collides to start
    
   % Handle the behavior of each node based on their current state
   for n = 1:N
      if (timer(n) > 0)
        stage(n) = stage(n) - 1; 
      else
          
          % Determine if any other node is in timer 0 state, since that
          % is what causes a collision
          for nn = 1:N
             if (n ~= nn && timer(nn) == 0)
                 collisions(1,n) = 1;
                 collisions(1,nn) = 1;
             end
          end
          
          % Handle the transmission state now
           if (collisions(1,n) == 0) % if success, go to stage 0 with random backoff k
              successes(n) = successes(n) + 1;
              stage(n) = 0;
              timer(n) = floor(rand(1) * W(1,1));
           else % collision, go to the next backoff stage and choose a new random timer
               failures(n) = failures(n) + 1;
               if (stage(n) ~= m) % loop at stage m
                  stage(n) = stage(n) + 1; 
               end
               timer(n) = floor(rand(1) * W(1,stage(n)));
           end
       end 
   end
end

% Results
for n = 1:N
    disp(sprintf('Node %d successes =  %d', n, successes(n)));
    disp(sprintf('Node %d failures =  %d', n, failures(n)));
end