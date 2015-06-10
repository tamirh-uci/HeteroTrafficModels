function [ simResults, plotColors ] = run_single_sim( name, timesteps, simParams, dataParams, vidParams, vidUtil, doVideoMangle, nData, nVid )
    sim = dcf_simulation(name);
    sim.nTimesteps = timesteps;
    sim.params = simParams;
    sim.vidUtil = vidUtil;

    for vidNodeIndex=1:nVid
        sim.AddNodegen( vidParams );
    end
    
    for dataNodeIndex=1:nData
        sim.AddNodegen( dataParams );
    end
    
    sim.Run(doVideoMangle);
    
    simResults = sim.simResults;
    plotColors = sim.plotColors;
end
