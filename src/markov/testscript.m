import dcf_container;

m = dcf_container();

state00 = dcf_state( [0 0], dcf_state_type.Transmit );
state01 = dcf_state( [0 1], dcf_state_type.Backoff );
state10 = dcf_state( [1 0], dcf_state_type.Transmit );
state11 = dcf_state( [1 1], dcf_state_type.Backoff );

m.NewState(state00);
m.NewState(state01);
m.NewState(state10);
m.NewState(state11);

m.SetP([0 0], [0 1], 0.5);
m.SetP([0 0], [1 1], 0.5);

m.SetP([0 1], [0 0], 1.0);

m.SetP([1 0], [0 0], 0.5);
m.SetP([1 0], [0 1], 0.25);
m.SetP([1 0], [1 1], 0.25);

m.SetP([1 1], [1 0], 1.0);

assert( m.Verify() );
t = m.TransitionTable();

t
