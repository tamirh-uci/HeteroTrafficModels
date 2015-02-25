function [ markovMatrix ] = dcf_matrix_factory( pSuccess, pArrive, pEnter, m, wMin, nPkt, nInterarrival )

    markovMatrix = dcf_matrix_collapsible();
    markovMatrix.pRawArrive = pArrive;
    markovMatrix.pEnterInterarrival = pEnter;
    markovMatrix.m = m;
    markovMatrix.wMin = wMin;
    markovMatrix.nPkt = nPkt;
    markovMatrix.nInterarrival = nInterarrival;
    markovMatrix.CreateMarkovChain(pSuccess);
     
end

