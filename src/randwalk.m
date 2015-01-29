function [length] = randwalk(p_exit, max_startstate, state_total)
    length = 0;
    state = randi(max_startstate);
    while (state ~= 0)
        length = length + 1;

        r = rand();
        if (r < p_exit)
            state = state + 1;
            if (state >= (state_total))
                state = 0;
            end
        end
    end
    