%% 3D DICE Coefficient Calculator from STL Files

% Notes:
% Author - Stewart McLennan
% Date - 2023-03-07
% Company - Opsens Medical

% Command for producing figure
figure

% Importing Ground Truth STL file
Ground_Truth_Geometry = importGeometry('Ground Truth Mesh.stl');

% Plotting Ground Truth geometry
pdegplot(Ground_Truth_Geometry, "FaceAlpha", 0.5);

% Assigning axis labels to plot
xlabel('X-direction, mm');
ylabel('Y-direction, mm');
zlabel('z-direction, mm');

% Reverse Z-axis direction
set(gca, 'YDir','reverse'); 

% Hold on figure to plot the Predicted Geometry within the same figure
hold on

% Importing Predicted Geometry STL file
Predicted_Geometry = importGeometry('Predicted Mesh.stl');

% Plotting Predicted Geometry
pdegplot(Predicted_Geometry, "FaceAlpha", 0.5);

% Assigning axis labels to plot
xlabel('X-direction, mm');
ylabel('Y-direction, mm');
zlabel('z-direction, mm');

% Reverse Z-axis direction
set(gca, 'YDir','reverse'); 

% Get the voxelization of both geometries
[v1] = VOXELISE(100, 100, 100, 'Ground Truth Mesh.stl', 'xyz');
[v2] = VOXELISE(100, 100, 100, 'Predicted Mesh.stl', 'xyz');

% Finding the intersection volume between the two geometries
intersection = sum(v1(:) & v2(:));

% Finding the union volume between the two geometries
union = sum(v1(:) | v2(:));

% Calculating the 3D DICE coefficient
dice_coeff = 2 * intersection / union;

% Display 3D DICE coefficient in command window
disp(['3D Dice coefficient = ' num2str(dice_coeff)]);

% Listing toolboxes and licenses needed to run the code
license('inuse') % Get list of ToolBoxes needed to run code
