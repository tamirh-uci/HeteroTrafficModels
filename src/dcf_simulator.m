%%% DCF Monte Carlo simulator

% Parameters
timeSteps = 1000;
p = 0.5;
Wmin = 2;
Wmax = 4; %1024;
m = log2(Wmax / Wmin);
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^(i-1)) * Wmin;
end

% State variables
backoffTimer = 0;
backoffStage = 0;

for t = 1:timeSteps
   disp('Time step 
end