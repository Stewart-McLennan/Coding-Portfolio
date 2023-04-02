%% General notes

% Delete all PNG images in current folder before running script

% Script creator: SMC (OpSens Medical, Inc)
% Date: 2022-05-05

%% Clean

clear all;
clc;                                                                        % All PNG files should be automatically deleted when cleaning

%% Read All Frames in DICOM File

% x = dicomread('1_Se08XA000000.dcm');                                        % Issue: DICOM file should be read without having to use its name
% info = dicominfo('1_Se08XA000000.dcm');
% Number_of_Frames = info.(dicomlookup('0028', '0008'));
% 
% for a = 1:Number_of_Frames
%     imshow(x(:,:,a), []);
%     File_Name = [num2str(a),'.png'];
%     saveas(gca,File_Name);
% end
% 
% %% Apply Hessian Based Tubular Filter to All Frames
% 
% files = dir('*.png');
% 
% for i = 1:numel(files)
%     filename = files(i).name;
%     image = imread(filename);
%     Filtered_Image = vesselness2D(image, 0.5:0.5:2.5, [1;1], 0.5, false);
%     imshow(Filtered_Image);
%     saveas(gca,filename);    
% end
% 
% %% Measure Segmented Area of Each Frame
% 
% files = dir('*.png');
% 
% for i = 1:numel(files)
%     filename = files(i).name;
%     image = imread(filename);
%     Two_Dimensional_Image = rgb2gray(image);
%     Binarized_Image = imbinarize(Two_Dimensional_Image);
%     Area(i) = bwarea(Binarized_Image);
% end
% 
% Area_Corrected = Area - Area(1);                                            % Remove white pixel area of catheter, surrounding black box, guide wire, and unwanted noise.
% 
% %% Plot Segmented Area versus Time
% 
% info = dicominfo('1_Se08XA000000.dcm');
% Time_Between_Frames = info.(dicomlookup('0018', '1063'));
% 
% x = linspace(0,Time_Between_Frames * Number_of_Frames,Number_of_Frames);
% 
% plot(x,Area_Corrected);
% p = polyfit(x,Area_Corrected,7);
% f1 = polyval(p,x);
% plot(x,Area_Corrected,'o');
% hold on
% plot(x,f1,'r--');
% axis equal
% xlabel('Time, miliseconds');
% ylabel('White Vessel Area, pixels^2');
% 
% %% Find The Time for Contrast Agent to Pass through Artery
% 
% [~,mxi] = max(Area_Corrected);
% End_Time = x(mxi);
% Start_Time = x(20);                                                         % Contrast is released at frame 20. Should be found automatically. fix.
% Time = End_Time - Start_Time;

%% Find the Flow Rate

info = dicominfo('1_Se08XA000000.dcm');
Time_Between_Frames = info.(dicomlookup('0018', '1063'));

prompt = "Enter frame number before the frame at which dye begins to propogate in the LAD ";
Start_Frame = input(prompt);

prompt = "Enter frame number before the frame at which dye reaches the guidewire tip ";
End_Frame = input(prompt);

Start_Time = Time_Between_Frames * Start_Frame + 0.5 * Time_Between_Frames;

End_Time = Time_Between_Frames * End_Frame + 0.5 * Time_Between_Frames;

Time = End_Time - Start_Time;

Model = createpde;
importGeometry(Model,'Vessel Wall - Millimetres - Smoothed - No noise.stl');
pdegplot(Model);

Mesh = generateMesh(Model,'Hmax',0.1);
pdemesh(Mesh);
Volume = volume(Mesh);

Hyperaemia_Factor = 3.5;                                                    % Scaling factor to account for increased flow due to induced hyperaemia during FFR

Flowrate = Volume / Time * Hyperaemia_Factor;                               % Flowrate given in mL/s.
