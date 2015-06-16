function [ sim ] = setup_single_sim( name, timesteps, simParams, dataParams, vidParams, vuCells, qualityThresholdMicrosec, nVid, nData )
    sim = dcf_simulation(name);
    sim.nTimesteps = timesteps;
    sim.params = simParams;
    sim.vuCells = vuCells;
    sim.qualityThreshold = qualityThresholdMicrosec;

    for vidNodeIndex=1:nVid
        sim.AddNodegen( vidParams );
    end
    
    for dataNodeIndex=1:nData
        sim.AddNodegen( dataParams );
    end
end
