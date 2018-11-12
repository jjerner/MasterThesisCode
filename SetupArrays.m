
%{
    Help file for setting up the impedance & admittance matrices with appropriate checks
    to ensure stability and correct indexes
%}

if length(CableData) ~= length(connectionNodes)
    disp('G�r om g�r r�tt!!! REEEEEEEEEEE!')
    error('Mismatch in CableData and nodes!')
end

if min(min(connectionNodes)) ~= 1
   error('Cable index does not start at 1, Check "connectionNodes"'); 
end

nCables = length(CableData);
nTransformers = length(TransformerData);
nNodes = nCables + nTransformers + 1;

% Preallocation 
Z_ser_self = zeros(nNodes);    % Self impedance, series
Z_ser_mutu = zeros(nNodes);    % Mutual impedance, series
Y_shu_self = zeros(nNodes);    % Self admittance, shunt




% Mutual impedance/admittance (non-diagonal elements)
% Negative of sum of all admittances between node ij
for iCable = 1:length(CableData)
        startNode = connectionNodes(iCable,1);
        endNode = connectionNodes(iCable,2);

        Z_ser_mutu(startNode,endNode) = -CableData(iCable).Z_ser;
        Z_ser_mutu(endNode,startNode) = -CableData(iCable).Z_ser;
end

% Self impedance/admittance (diagonal elements)
% Sum of elements terminating at node i
for iNode = 1:length(Z_ser_self)
    Z_ser_self_vec = [];
    Y_shu_self_vec = [];
    for iCable = 1:length(connectionNodes)
        startNode = connectionNodes(iCable,1);
        endNode = connectionNodes(iCable,2);
        
        if iNode == startNode || iNode == endNode
            Z_ser_self_vec = [Z_ser_self_vec; CableData(iCable).Z_ser];
            Y_shu_self_vec = [Y_shu_self_vec; 0.5*CableData(iCable).Y_shu];
        end
    end
    
    Z_ser_self(iNode, iNode) = sum(Z_ser_self_vec);
    Y_shu_self(iNode, iNode) = sum(Y_shu_self_vec);
end

Z_ser_tot = Z_ser_self+Z_ser_mutu;  % Total impedance, series
Y_ser_tot = 1./Z_ser_tot;   
Y_ser_tot(Z_ser_tot==0)=0;          % Total admittance, series
Y_shu_tot = Y_shu_self;             % Total admittance, shunt
Y_bus     = Y_ser_tot + Y_shu_tot;  % Bus admittance matrix

% clear some workspace
clear startNode endNode iNode iCable Z_ser_self_vec Y_shu_self_vec