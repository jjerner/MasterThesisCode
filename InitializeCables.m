%% Parameters
cableDBPath='data/Ledningsdata.mat';    % Path to cable database

switch location
    case 'Amundstorp'
        gridCableDataPath = 'T317 Amundstorp.xlsx';
    case 'Hallonvägen'
        gridCableDataPath = 'T085 Hallonvagen.xlsx';
end

j = 1i;
if ~(exist('freq', 'var'))
    freq = 50;
end

disp(['Loading cable database from: "', cableDBPath,'"']);
disp(['Loading grid cable data from: "', gridCableDataPath,'"']);
disp(' ');

load(cableDBPath);                  % Load cable database

% Read grid cable data from file
data = importdata(gridCableDataPath);
data.textdata = data.textdata(4:end, :);        % remove first 3 rows of nonsense in textdata

nCablesInGrid=length(data.textdata(:,2));
nCablesInDB=height(Ledningsdata);
cablesFound=false(nCablesInGrid,1);

for iGridCable = 1:nCablesInGrid
    %compare (find the right cable data)
    cablesFound(iGridCable) = false;
    iDBCable = 1;

    while ~cablesFound(iGridCable) && iDBCable<nCablesInDB
        nameToCompare = Ledningsdata.Name{iDBCable};
        if nameToCompare(end-2) == '/'
            nameToCompare = nameToCompare(1:end-3);
        end

        if length(data.textdata{iGridCable,2}) == length(nameToCompare)
            if data.textdata{iGridCable,2} == nameToCompare
                cablesFound(iGridCable) = true;
            else
                iDBCable = iDBCable + 1;
            end
        else
            iDBCable = iDBCable + 1;
        end
    end
    
    if ~cablesFound(iGridCable)
        disp(['No DB match for cable ' num2str(iGridCable) ', using standard cable.']);
        iDBCable = 4;  % <-- set appropriate index to "standard cable"
    end

    %read data
    CableData(iGridCable).l      = data.data(iGridCable,5);                 % [m]
    CableData(iGridCable).Rpl    = Ledningsdata.R(iDBCable);                % [Ohm / km]
    CableData(iGridCable).R0pl   = Ledningsdata.R0(iDBCable);               % [Ohm / km]
    CableData(iGridCable).RNpl   = Ledningsdata.RN(iDBCable);               % [Ohm / km]
    CableData(iGridCable).Xpl    = Ledningsdata.X(iDBCable);                % [Ohm / km]
    CableData(iGridCable).X0pl   = Ledningsdata.X0(iDBCable);               % [Ohm / km]
    CableData(iGridCable).XNpl   = Ledningsdata.XN(iDBCable);               % [Ohm / km]
    CableData(iGridCable).Bdpl   = Ledningsdata.Bd(iDBCable);               % [uS / km / fas]
    CableData(iGridCable).Imax   = Ledningsdata.Imax(iDBCable);             % [A]

    % assumed data
    CableData(iGridCable).G      = 0;                                       % Shunt conductance [S]

    %formatting + calculations (NOTE: NOT IN PER-UNIT)
    % commented version of R is 3-phased cable (possibly better?)
    %CableData(iCables).R      = (CableData(iCables).l / 1e3) * (2*CableData(iCables).Rpl...
    %                             + CableData(iCables).R0pl + 3*Cabledata(iCables).RNpl);                     % [Ohm]
    CableData(iGridCable).R      = (CableData(iGridCable).l / 1e3) * CableData(iGridCable).Rpl;                        % [Ohm]
    CableData(iGridCable).X      = (CableData(iGridCable).l / 1e3) * CableData(iGridCable).Xpl;                        % [Ohm]
    CableData(iGridCable).L      = (CableData(iGridCable).l / 1e3) * CableData(iGridCable).Xpl / (2*pi*freq);          % [H]
    CableData(iGridCable).C      = (CableData(iGridCable).l / 1e3) * (CableData(iGridCable).Bdpl / (2*pi*freq*1e6));   % [F]
    CableData(iGridCable).Bd     = (CableData(iGridCable).l / 1e3) * CableData(iGridCable).Bdpl;                       % [S]

    CableData(iGridCable).Z_ser=CableData(iGridCable).R+j*CableData(iGridCable).X;             % Series impedance [ohm]
    CableData(iGridCable).Y_shu=CableData(iGridCable).G+j*CableData(iGridCable).Bd;            % Shunt admittance [S]

end

% clear some workspace
clear nameToCompare iDBCable iGridCable