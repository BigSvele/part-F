%%
clc
clear
%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 5);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["sepal_length", "sepal_width", "petal_length", "petal_width", "species"];
opts.VariableTypes = ["double", "double", "double", "double", "categorical"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "species", "EmptyFieldRule", "auto");

% Import the data
irisData = readtable("/Users/herman/Downloads/IRIS.csv", opts);

%% Clear temporary variables
clear opts

%% Partition the Dataset into Training and Testing Sets
cv = cvpartition(irisData.species, 'HoldOut', 0.3);

% training and test sets
trainIdx = training(cv);
testIdx = test(cv);

% Create training and test data tables
trainData = irisData(trainIdx, :);
testData = irisData(testIdx, :);

%% Verifying split
fprintf('Training set proportion: %.2f%%\n', sum(trainIdx) / numel(trainIdx) * 100);
fprintf('Testing set proportion: %.2f%%\n', sum(testIdx) / numel(testIdx) * 100);

%% Assume trainData is your training dataset
inputs = trainData{:, 1:4}; %  first four columns as input
outputs = grp2idx(trainData.species);  

%%
% Number of membership functions
numMFs = 3;
% Type of membership functions
mfType = 'gaussmf';


%% Generate FIS using genfis
fisOptions = genfisOptions('GridPartition');
fisOptions.NumMembershipFunctions = numMFs;
fisOptions.InputMembershipFunctionType = mfType;
fis = genfis(inputs, outputs, fisOptions);
paramset = getTunableSettings(fis);

%%
% Display the generated FIS
disp(fis)

% Plot the membership functions for an input 
figure;
plotmf(fis, 'input', 1)

%% Tune FIS using tunefis and tunefisOptions
optimizationMethod = 'particleswarm'; % Change as needed

switch optimizationMethod
    case 'ga'
        options = tunefisOptions('Method','ga');
        options.MethodOptions.PopulationSize = 50;  
        options.MethodOptions.MaxGenerations = 100;
        options.MethodOptions.PlotFcn = {@gaplotbestf};
        options.MethodOptions.Display = 'iter';
    case 'particleswarm'
        options = tunefisOptions('Method','particleswarm');
        options.MethodOptions.SwarmSize = 50;  
        options.MethodOptions.MaxIterations = 100;  
        options.MethodOptions.Display = 'iter';
    case 'anfis'
        options = tunefisOptions('Method','anfis');
        options.MethodOptions.EpochNumber = 50;  %
        options.MethodOptions.InitialFIS = 3;
        options.Display = 'tuningonly';
    otherwise
        error('Unsupported optimization method.');
end

% Apply tuning
tunedFIS = tunefis(fis, paramset, inputs, outputs, options);

%% results 

figure;
subplot(2,1,1);
plotmf(tunedFIS, 'input', 1);
title('Tuned Membership Functions for First Input');


disp(tunedFIS);

