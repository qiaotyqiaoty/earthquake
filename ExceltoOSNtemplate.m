% Opensees Navigator Template
% For OSN Version 2.5.8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Developed by Tianyang Joe Qiao
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Clean start
clear; clc;

%% Load OSN Model
% Model Directory here:
dirModel = 'E:\Research\UBC MASc\Concrete Core Wall\Opensees Model 180217A\';
dirOpenSees = 'E:\Program Files\';

% Model Name here:
modelName = 'RockingWall180217A.mat';

% Excel file name here:
excelName = 'aa.xlsx';

%% Library Settings
% 0: disabled   1: enabled
Switch.WriteMaterial = 0;
Switch.WriteMPC = 1;
Switch.WriteFiberSection = 0;
Switch.WriteLoad = 0;
Switch.WriteElemType = 1;

%% Run Settings
% Mode 0: do nothing
% Mode 1: plot model only
% Mode 2: run analysis in Navigator, with model plot
% Mode 3: run analysis silently, no need to open Navigator
RunSettings.Mode = 2;       % Type mode number here
RunSettings.CaseNum = 3;    % AnalysisCase number of analysis


%% Load Model
load([dirModel, modelName]);


%% Import excel database
% Find sheets
[Input.ExcelStatus, Input.ExcelName] = xlsfinfo(excelName);
Input.ExcelSheets.NodeOut = 0;
Input.ExcelSheets.ElemOut = 0;
Input.ExcelSheets.patch = 0;
Input.ExcelSheets.layer = 0;
for i=1:size(Input.ExcelName,2)
    Input.ExcelSheets.NodeOut = Input.ExcelSheets.NodeOut + double(isempty(strfind(Input.ExcelName{1,i},'NodeOut')));
    Input.ExcelSheets.ElemOut = Input.ExcelSheets.ElemOut + double(isempty(strfind(Input.ExcelName{1,i},'ElemOut')));
    Input.ExcelSheets.patch = Input.ExcelSheets.patch + double(isempty(strfind(Input.ExcelName{1,i},'patch')));
    Input.ExcelSheets.layer = Input.ExcelSheets.layer + double(isempty(strfind(Input.ExcelName{1,i},'layer')));
end
if Input.ExcelSheets.NodeOut == size(Input.ExcelName,2)
    error('NodeOut sheet not found in excel file');
end
if Input.ExcelSheets.ElemOut == size(Input.ExcelName,2)
    error('ElemOut sheet not found in excel file');
end
if Input.ExcelSheets.patch == size(Input.ExcelName,2)
    % force WriteFiberSection to be disabled if no corresponding sheets are found
    Switch.WriteFiberSection = 0;
    fprintf('WARNING: No fiber section data found in input excel file. WriteFiberSection disabled.\n');
end
        
% Import nodes
Input.Node = xlsread(excelName, 'NodeOut');
Input.nn = size(Input.Node,1);

% Import elements
[Input.ElemNum, Input.ElemTxt, Input.Elem] = xlsread(excelName, 'ElemOut');
Input.ne = size(Input.Elem,1);
Input.ElemNum=[]; Input.ElemT=[]; 

% Fiber section - Patch
if Switch.WriteFiberSection == 1
    [PatchNum,PatchTxt,Input.Patch]= xlsread(excelName,'patch');
    clear PatchNum PatchTxt;
    Input.Patch(1,:)=[];
    Input.np=size(Input.Patch,1);
end

% Fiber section - Layer
if Switch.WriteFiberSection == 1
    [LayerNum,LayerTxt,Input.Layer]= xlsread(excelName,'layer');
    clear LayerNum LayerTxt;
    Input.Layer(1,:)=[];
    Input.nl=size(Input.Layer,1);
end

% Material for Coupling Beams
if Switch.WriteMaterial == 1
    [MatNum,MatTxt,Input.Material]= xlsread(excelName,'material');
    clear MatNum MatTxt;
    Input.Material(1,:)=[];
    Input.nm=size(Input.Material,1);
end

% Element Types
if Switch.WriteElemType == 1
    [ETNum,ETTxt,Input.ElemType]= xlsread(excelName,'elementType');
    clear ETNum ETTxt;
    Input.ElemType(1,:)=[];
    for i=1:size(Input.ElemType,1)
        for j=1:size(Input.ElemType,2)
            if isnan(Input.ElemType{i,j})
                Input.ElemType{i,j} = [];
            end
        end
    end
    Input.net = size(Input.ElemType,1);
end



%% Model - All Nodes
for i=1:Input.nn
    Model.Node(i).Tag  = Input.Node(i,1);
    Model.Node(i).XYZ  = [Input.Node(i,2), Input.Node(i,3)];
    Model.Node(i).NDF = 3;
    Model.Node(i).SPC  = [Input.Node(i,4),Input.Node(i,5),Input.Node(i,6)];
    Model.Node(i).MPC  = [];
    Model.Node(i).Mass = [Input.Node(i,7),Input.Node(i,8),Input.Node(i,9)];
    if Switch.WriteLoad == 1
        Model.Node(i).Load = [];
        Model.Node(i).Disp = [];
    end
    Model.Node(i).ImpM = [];
end
fprintf('Write Nodes: Done\n');
 
% Delete another nodes (overlength)
j=Input.nn+1;
for i=(Input.nn+1):size(Model.Node,2)
    Model.Node(j)=[];
end

%% Model - MP Constraint
if Switch.WriteMPC == 1

% MPC 1-64 (wall-base)
MPCStruct.Name = 'MPC1-64';
MPCStruct.Type = 'Rigid Link';
MPCStruct.sNode = 64;
MPCStruct.linkType = 'beam';
Model.Node(1).MPC = MPCStruct;

% MPC 31-84 (wall-base)
MPCStruct.Name = 'MPC31-84';
MPCStruct.Type = 'Rigid Link';
MPCStruct.sNode = 84;
MPCStruct.linkType = 'beam';
Model.Node(29).MPC = MPCStruct;

fprintf('Write MPC: Done\n');

end

%% Model - All Elements
for j=1:Input.ne
    Model.Element(j).Tag  = Input.Elem{j,1};
    Model.Element(j).Con  = [Input.Elem{j,2}, Input.Elem{j,3}];
    Model.Element(j).Ndf = 3;
    Model.Element(j).Type = 'None';
    Model.Element(j).GeoT = 'None';
    Model.Element(j).Rot = [];
    Model.Element(j).JOff = [];
    if Switch.WriteLoad == 1
        Model.Element(j).Load = [];
    end
    Model.Element(j).Defo = [];

    % Assign Element Type
    if Input.Elem{j,4} == 0
        Model.Element(j).Type = 'None';
    else
        Model.Element(j).Type = Input.Elem{j,4};
    end
    
    % Assign GeoTrans
    if Input.Elem{j,5} == 0
        Model.Element(j).GeoT = 'None';
    else
        Model.Element(j).GeoT = Input.Elem{j,5};
    end
    Model.Element(j).Rot  = 0;
end
fprintf('Write Elements: Done\n');

% Delete another nodes (overlength)
j=Input.ne+1;
for i=(Input.nn+1):size(Model.Node,2)
    Model.Element(j)=[];
end

%% Model - miscellaneous
Model.pathname = dirModel;
Model.name = modelName;
Model.nn = Input.nn;
Model.ne = Input.ne;


%% Library - Loads
if Switch.WriteLoad == 1

% Gravity load
LoadStruct.Pattern = 'Gravity';
LoadStruct.Value = [0,-2379381,0];   % Loads at 3 DOFs
for i=3:28
    Model.Node(i).Load = LoadStruct;
end
for i=31:56
    Model.Node(i).Load = LoadStruct;
end

% Pushover load
LoadStruct.Pattern = 'Push';
LoadStruct.Value = [600000,0,0];   % Loads at 3 DOFs
Model.Node(28).Load = LoadStruct;
Model.Node(56).Load = LoadStruct;

fprintf('Write Library - Load: Done\n');

end

%% Library - Section - Patch
if Switch.WriteFiberSection == 1

n = 2;     % Number of the section where patch is assigned
Library.Section(n).Patch=[];
for i=1:Input.np
    Library.Section(n).Patch(i).Type = Input.Patch{i,1};
    Library.Section(n).Patch(i).Name = Input.Patch{i,2}; 
    Library.Section(n).Patch(i).MatName = Input.Patch{i,3};
    Library.Section(n).Patch(i).Iy = Input.Patch{i,4};
    Library.Section(n).Patch(i).Iz = Input.Patch{i,5};
    Library.Section(n).Patch(i).Jy = Input.Patch{i,6};
    Library.Section(n).Patch(i).Jz = Input.Patch{i,7};
    Library.Section(n).Patch(i).Ky = Input.Patch{i,8};
    Library.Section(n).Patch(i).Kz = Input.Patch{i,9};
    Library.Section(n).Patch(i).Ly = Input.Patch{i,10};
    Library.Section(n).Patch(i).Lz = Input.Patch{i,11};
    Library.Section(n).Patch(i).NSIJ = Input.Patch{i,12};
    Library.Section(n).Patch(i).NSJK = Input.Patch{i,13};
    Library.Section(n).Patch(i).Theta = Input.Patch{i,14};
end

fprintf('Write Library - Section Patch: Done\n');

end


%% Library - Section - Layer
if Switch.WriteFiberSection == 1
n = 2;     % Number of the section where layer is assigned
Library.Section(n).Layer=[];
for i=1:Input.nl
    Library.Section(n).Layer(i).Type = Input.Layer{i,1};
    Library.Section(n).Layer(i).Name = Input.Layer{i,2}; 
    Library.Section(n).Layer(i).MatName = Input.Layer{i,3};
    Library.Section(n).Layer(i).yStart= Input.Layer{i,4};
    Library.Section(n).Layer(i).zStart = Input.Layer{i,5};
    Library.Section(n).Layer(i).yEnd = Input.Layer{i,6};
    Library.Section(n).Layer(i).zEnd = Input.Layer{i,7};
    Library.Section(n).Layer(i).numBars = Input.Layer{i,8};
    Library.Section(n).Layer(i).areaBar = Input.Layer{i,9}; 
end

fprintf('Write Library - Section Layer: Done\n');

end


%% Library - Material
if Switch.WriteMaterial == 1

j = 1;
for i=9:(Input.nm+8)
    Library.Material(i).Type = Input.Material{j,1};
    Library.Material(i).Name = Input.Material{j,2}; 
    Library.Material(i).E = Input.Material{j,3};
    Library.Material(i).eta= [];
    Library.Material(i).Fy = Input.Material{j,4};
    Library.Material(i).b = Input.Material{j,5};
    Library.Material(i).R0 = [];
    Library.Material(i).cR1 = [];
    Library.Material(i).cR2 = [];
    Library.Material(i).sig0 = [];
    Library.Material(i).a1 = 0;
    Library.Material(i).a2 = 1;
    Library.Material(i).a3 = 0;
    Library.Material(i).a4 = 1;
    Library.Material(i).fpc = [];
    Library.Material(i).epsc0 = [];
    Library.Material(i).fpcu= [];
    Library.Material(i).epsU = [];
    Library.Material(i).ratio= [];
    Library.Material(i).ft = [];
    Library.Material(i).Ets = [];
    Library.Material(i).Eneg = [];
    j=j+1;
end

fprintf('Write Library - Material: Done\n');

end


%% Library - Element Type
if Switch.WriteElemType == 1
j=1;
Library.Element = [];
for i=1:Input.net
    Library.Element(i).Type = Input.ElemType{j,1};
    Library.Element(i).Name = Input.ElemType{j,2};
    Library.Element(i).E = Input.ElemType{j,3};
    Library.Element(i).G = Input.ElemType{j,4};
    Library.Element(i).A = Input.ElemType{j,5};
    Library.Element(i).Iz = Input.ElemType{j,6};
    Library.Element(i).Iy = Input.ElemType{j,7};
    Library.Element(i).J = Input.ElemType{j,8};
    Library.Element(i).alpha = Input.ElemType{j,9};
    Library.Element(i).d = Input.ElemType{j,10};
    Library.Element(i).massDens = Input.ElemType{j,11};
    Library.Element(i).corotTrans = Input.ElemType{j,12};
    if isempty(Input.ElemType{j,13}) && isempty(Input.ElemType{j,14}) && isempty(Input.ElemType{j,15})
        Library.Element(i).MatName = [];
    elseif isempty(Input.ElemType{j,14}) && isempty(Input.ElemType{j,15})
        Library.Element(i).MatName = Input.ElemType{j,13};
    else
    Library.Element(i).MatName{1,1} = Input.ElemType{j,13};
    Library.Element(i).MatName{1,2} = Input.ElemType{j,14};
    Library.Element(i).MatName{1,3} = Input.ElemType{j,15};
    end
    Library.Element(i).doRayleigh = Input.ElemType{j,16};
    Library.Element(i).sDratios = Input.ElemType{j,17};
    Library.Element(i).NIP = Input.ElemType{j,18};
    Library.Element(i).SecName = Input.ElemType{j,19};
    Library.Element(i).maxIters = Input.ElemType{j,20};
    Library.Element(i).tol = Input.ElemType{j,21};
    Library.Element(i).massType = Input.ElemType{j,22};
    Library.Element(i).intType = Input.ElemType{j,23};
    Library.Element(i).mass = Input.ElemType{j,24};
    j=j+1;
end
end


%% Generate Load Pattern
% Generate load pattern
LoadAmp = [0.001 0.002 0.005 0.01 0.015 0.02 0.03 0.04]*100.263;
LoadCycle = 2;
LoadIncre = 0.0002*100.263;  % Load increment per step
LoadVect = [];
for n=1:length(LoadAmp)
    i=1; LoadVectTemp(i)=0;
    while LoadVectTemp(i) <= LoadAmp(n)
        LoadVectTemp(i+1) = LoadVectTemp(i) + LoadIncre;
        i = i + 1;
    end
    while LoadVectTemp(i) >= -1*LoadAmp(n)
        LoadVectTemp(i+1) = LoadVectTemp(i) - LoadIncre;
        i = i + 1;
    end
    while LoadVectTemp(i) < 0
        LoadVectTemp(i+1) = LoadVectTemp(i) + LoadIncre;
        i = i + 1;
    end
    for j=1:(LoadCycle-1)
        LoadVectTemp = [LoadVectTemp, LoadVectTemp];
    end
    LoadVect = [LoadVect, LoadVectTemp];
    clear LoadVectTemp;
end
LoadVect = LoadVect';
%}


%% UserDef
UserDef=[];


%% Save MAT-file
save ([dirModel, modelName], 'Library', 'Model', 'UserDef');
fprintf('Model Saved...\n');
load ([dirModel, modelName]);


%% Run in OSN
if RunSettings.Mode == 2

RunSettings.PlotModel = 0;
    
handleResults = findobj('Tag','OpenSeesNavigator');
if ~isempty(handleResults)
    figure(findobj('Tag','OpenSeesNavigator'));
else
    RunOpenSeesNavigator;
end
ClearModel;
PlotModel(Model,Library,0);
% Write TCL files
WriteTCLfiles(Model,Library,UserDef,RunSettings.CaseNum);
% Run OpenSees
RunOpenSees(Model,Library,RunSettings.CaseNum);

end

%% Run in OpenSees silently
if RunSettings.Mode == 3
    
RunSettings.PlotModel = 0;
% Write TCL files
WriteTCLfiles(Model,Library,UserDef,RunSettings.CaseNum);
% Run OpenSees silently
cd([Model.pathname,'TCLFiles\']);
tic             % get time
Command = ['@ "',dirOpenSees,'OpenSees.exe" "',[Model.filename(1:end-4) '.tcl'],'"'];
system(Command,'-echo');
toc

end


%% Plot model only
if RunSettings.Mode == 1
    
handleResults = findobj('Tag','OpenSeesNavigator');
if ~isempty(handleResults)
    figure(findobj('Tag','OpenSeesNavigator'));
else
    RunOpenSeesNavigator;
end

ClearModel;
PlotModel(Model,Library,0);

end


%{
% Change directory
cd([dirModel,'\OutPutFiles\PushOver\']);
figure(2);
Out.BaseShear = load('PushOver_Node_BaseShear_RFrc.out');
Out.RoofDrift = load('PushOver_Node_RoofDrift_Dsp.out');
plot(Out.RoofDrift(:,2),Out.BaseShear(:,2));
%}
