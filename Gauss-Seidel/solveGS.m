% Gauss-Seidel solver for power flow analysis
% result=solveGS(Y_bus,busTypes,V_0,P_inj,Q_inj,accFactor,doPlot)
%
% INPUTS:
% Y_bus:        Bus admittance matrix (n x n complex double)
% busTypes:    Vector describing bus types (n x 2 char)
% V_0:          Voltage magnitude guess for each bus [V] (n x 1 double)
% P_inj:        Active power injected at each bus [W] (n x 1 double)
% Q_inj:        Reactive power injected at each bus [VAr] (n x 1 double)
% doPlot:       Switch to produce plots or not (1 x 1 bool)
%
% OUTPUTS:
% result:           Struct containing solver results
% result.V_hist:    Voltage iteration history per bus
% result.P_hist:    Active power iteration history per bus
% result.Q_hist:    Reactive power iteration history per bus
% result.V_diff:    Voltage difference between the last two iterations
% result.P_diff:    Active power difference between the last two iterations
% result.Q_diff:    Reactive power difference between the last two iterations
%
% SAMPLE DATA:
%  Y_bus=[-13 5 4 0; 5 -13.5 2.5 2;4 2.5 -9 2.5; 0 2 2.5 -4.5];
%  busTypes=['SL';'PQ';'PV';'PQ'];
%  V_0=[1 0.95 1 0.9];
%  P_inj=[0 1 1.01 1.5];
%  Q_inj=[0 0.01 0 0.01];


function result=solveGS(Y_bus,busTypes,V_0,P_inj,Q_inj,accFactor,doPlot)

    if nargin < 5
        error('Not enough input arguments.')
    elseif nargin == 5
        accFactor = 1;
        doPlot = 0;
    elseif nargin == 6
        doPlot = 0;
    end

    j=1i;   % Imaginary unit
    % Check criterias for bus admittance matrix
    fprintf(['Bus admittance matrix Y_bus must fulfil either criteria \n' ...
        '1. Diagonally dominant\n' ...
        '2. Symmetric AND positive definite\n']);

    % Diagonally dominant (weak)
    isDiagonallyDominant = all(2*abs(diag(Y_bus)) >= sum(abs(Y_bus),2));
    % Symmetricity
    isSymmetric = issymmetric(Y_bus);
    % Positive definite
    isPositiveDefinite = all(eig((Y_bus+Y_bus')/2) > 0);

    if isDiagonallyDominant
        disp('OK - Y_bus fulfills criteria 1');
    elseif isSymmetric && isPositiveDefinite
        disp('OK - Y_bus fulfills criteria 1');
    else
        warning('Neither criteria 1 nor 2 fulfilled - convergence not guaranteed');
    end

    V_latest=V_0;           % Latest calculated bus voltages
    P_latest=P_inj;         % Latest calculated bus powers (active)
    Q_latest=Q_inj;         % Latest calculated bus powers (reactive)
    V_hist(1,:)=V_0;        % Full history of calculated bus voltages
    P_hist(1,:)=P_inj;      % Full history of calculated bus powers (active)
    Q_hist(1,:)=Q_inj;      % Full history of calculated bus powers (reactive)
    iLoop=1;
    V_diff=inf*ones(1,length(Y_bus));   % Initial difference to avoid immediate stop
    P_diff=inf*ones(1,length(Y_bus));
    Q_diff=inf*ones(1,length(Y_bus));


    while norm(V_diff,2)>1e-5 && norm(P_diff,2)>1e-5 && norm(Q_diff,2)>1e-5
        for iBus = 1:length(Y_bus)
            switch busTypes(iBus,:)
                case 'PQ'   % If PQ-bus, find V
                    V_latest(iBus)=(1/Y_bus(iBus,iBus))*((P_latest(iBus)+j*Q_latest(iBus)/conj(V_latest(iBus)))...
                        -(sum(Y_bus(iBus,:).*V_latest)-Y_bus(iBus,iBus).*V_latest(iBus)));
                    % Acceleration factor
                    V_latest(iBus)=accFactor*V_latest(iBus)+(1-accFactor)*V_hist(iLoop,iBus);
                case 'PV'   % If PV-bus, find Q
                    Q_latest(iBus)=-imag(conj(V_latest(iBus))*sum(Y_bus(iBus,:).*V_latest));
                    % If Q_latest is within limits, then compute updated voltage
                    V_latest(iBus)=(1/Y_bus(iBus,iBus))*((P_latest(iBus)+j*Q_latest(iBus)/conj(V_latest(iBus)))...
                        -(sum(Y_bus(iBus,:).*V_latest)-Y_bus(iBus,iBus).*V_latest(iBus)));
                    % Force voltage magnitude to specified value
                    V_latest(iBus)=abs(V_0(iBus))*V_latest(iBus)/abs(V_latest(iBus));
                case 'SL'   % If slack-bus, find P and Q ???
                    P_latest(iBus)=real(conj(V_latest(iBus))*sum(Y_bus(iBus,:).*V_latest));
                    Q_latest(iBus)=-imag(conj(V_latest(iBus))*sum(Y_bus(iBus,:).*V_latest));
                    % Compute updated voltage ???
                    %V_latest(iBus)=(1/Y_bus(iBus,iBus))*((P_latest(iBus)+j*Q_latest(iBus)/conj(V_latest(iBus)))...
                    %    -(sum(Y_bus(iBus,:).*V_latest)-Y_bus(iBus,iBus).*V_latest(iBus,iBus)));
            end    
        end
        V_hist(iLoop+1,:)=V_latest;     % Add latest voltages to history
        P_hist(iLoop+1,:)=P_latest;     % Add latest active powers to history
        Q_hist(iLoop+1,:)=Q_latest;     % Add latest reactive powers to history
        V_diff=V_hist(iLoop+1,:)-V_hist(iLoop,:);   % Voltage difference
        P_diff=V_hist(iLoop+1,:)-V_hist(iLoop,:);   % Active power difference
        Q_diff=V_hist(iLoop+1,:)-V_hist(iLoop,:);   % Reactive power difference
        iLoop=iLoop+1;
    end
    result.V_hist=V_hist;
    result.P_hist=P_hist;
    result.Q_hist=Q_hist;
    result.V_diff=V_diff;
    result.P_diff=P_diff;
    result.Q_diff=Q_diff;
    
    % Plot
    if doPlot
        legendLabelsV=[repmat('V_{',length(Y_bus),1) num2str(transpose(1:length(Y_bus))) repmat('}',length(Y_bus),1)];
        legendLabelsP=[repmat('P_{',length(Y_bus),1) num2str(transpose(1:length(Y_bus))) repmat('}',length(Y_bus),1)];
        legendLabelsQ=[repmat('Q_{',length(Y_bus),1) num2str(transpose(1:length(Y_bus))) repmat('}',length(Y_bus),1)];
        figure;
        plot(abs(V_hist));
        title('Voltage history');
        xlabel('Number of iterations');
        ylabel('Voltage [p.u.]');
        legend(legendLabelsV);
        figure;
        plot(abs(P_hist));
        title('Active power history');
        xlabel('Number of iterations');
        ylabel('Active power [p.u.]');
        legend(legendLabelsP);
        figure;
        plot(abs(Q_hist));
        title('Reactive power history');
        xlabel('Number of iterations');
        ylabel('Reactive power [p.u.]');
        legend(legendLabelsQ);
    end
end