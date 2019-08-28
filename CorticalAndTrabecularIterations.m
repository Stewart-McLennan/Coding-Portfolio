%% Cortical and Trabecular Element Iterations
% Stewart McLennan

%% Housekeeping:
clear all
close all

%% Algorithm
% will always start with itnum=1
% and write this to file
itnum=1;
itnumfile=fopen('iteration.txt','w');
fprintf(itnumfile,'%i',itnum);
fclose(itnumfile);
disp(['Iteration Number ',num2str(itnum,'%04i')]);

% remove previous strain data files
% remove *.lck files
% remove abaqus reply files
dos('del strains*bars*.*');
dos('del *.lck');
dos('del abaqus.rpy.*');

stop=0;
trabecularstop=0;
corticalstop=0;

% getting the original trabecular element definitions
s1.originalElements = dlmread('trabecularelements.txt',',');
s1.nodes = dlmread('NodesSolidMeshEL5.txt',',');
s1.nodeCoords = s1.nodes(:,2:end);
s1.nodes(:,2:end)=[];

s1.originalElementNums = s1.originalElements(:,1);
s1.originalElementNodes = s1.originalElements(:,2:3);
s1.originalElementLengths = sqrt(sum((s1.nodeCoords(s1.originalElementNodes(:,2),:)-s1.nodeCoords(s1.originalElementNodes(:,1),:)).^2,2));
s1.numElements = size(s1.originalElements,1);
s1.numNodes = size(s1.nodes,1);

% getting the original cortical element definitions
s1.originalCorticalElements = dlmread('SurfaceElementsMeshEL5.txt',',');

% finding face area for each of the cortical elements
s1.originalCorticalNodes = s1.originalCorticalElements(:,2:end);
% side vectors
s1.faceside01 = [s1.nodeCoords(s1.originalCorticalNodes(:,2),:)-s1.nodeCoords(s1.originalCorticalNodes(:,1),:)];
s1.faceside02 = [s1.nodeCoords(s1.originalCorticalNodes(:,1),:)-s1.nodeCoords(s1.originalCorticalNodes(:,3),:)];
s1.facecross = cross(s1.faceside01,s1.faceside02);
s1.facesize = 0.5.*sqrt(sum((s1.facecross.^2),2));

while itnum<100 && stop==0
    
    if itnum==1
        % using a dos command to run the input file
        abaquscommand01=['abaqus job=CorticalAndTrabecularIteration',num2str(itnum,'%04i'),' int ask_delete=OFF cpus=2'];
        disp(['   Number of Trabecular Elements: ', num2str(s1.numElements)]);
        disp('   Running the Input file...');
        [~,~]=dos(abaquscommand01,'-echo');
        
        % using a dos command to extract the strain data
        abaquscommand02=['abaqus cae noGUI=trabeculariterations.py'];
        disp('   Extracting information from the Output Database...');
        [~,~]=dos(abaquscommand02);
    end
    
    % load in the trabecular strain information
    strainfile = ['strains_trab_bars_iteration',num2str(itnum,'%04i'),'.txt'];
    s1.elementStrains = dlmread(strainfile,',');
    s1.elementNums = s1.elementStrains(:,1);
    s1.elementRefs = s1.elementNums-min(s1.originalElementNums)+1;
    
    % load in the cortical strain information
    % can be cleverer with what to do with this in the future...
    cortstrainfile01 = ['strains_cortSP1_bars_iteration',num2str(itnum,'%04i'),'.txt'];
    cortstrainfile02 = ['strains_cortSP2_bars_iteration',num2str(itnum,'%04i'),'.txt'];
    s1.elementcortStrains01 = dlmread(cortstrainfile01,',');
    s1.elementcortStrains02 = dlmread(cortstrainfile02,',');
    s1.elementCorticalNums = s1.elementcortStrains01(:,1);
    s1.numCorticalElements=size(s1.elementcortStrains01,1);
    s1.corticalStrain = max(abs([s1.elementcortStrains01(:,2:3) s1.elementcortStrains02(:,2:3)]),[],2);
    %
    s1.corticalStrainTC = zeros(s1.numCorticalElements,1);
    for n=1:s1.numCorticalElements
        if s1.corticalStrain(n) == max([s1.elementcortStrains01(n,2:3) s1.elementcortStrains02(n,2:3)]);
            s1.corticalStrainTC(n) = s1.corticalStrain(n);
        elseif s1.corticalStrain(n)*-1 == min([s1.elementcortStrains01(n,2:3) s1.elementcortStrains02(n,2:3)]);
            s1.corticalStrainTC(n) = s1.corticalStrain(n)*-1;
        end
    end
    
    % finding the nodes assocaited with the existing trabecular elements
    % can be used when elements are removed
    s1.elementNodes = zeros(size(s1.elementRefs,1),2);
    for n=1:size(s1.elementRefs,1)
        s1.elementNodes(n,1:2) = s1.originalElements(s1.elementRefs(n),2:3);
    end
    
    % setting up a reference set of absolute strains
    % zero values for elements that have been deleted
    s1.axialStrain = zeros(s1.numElements,1);
    for n=1:size(s1.elementNums,1);
        clear a1; a1=find(s1.originalElementNums==s1.elementNums(n));
        s1.axialStrain(a1)=abs(s1.elementStrains(n,2));
        s1.axialStrainTC(a1)=s1.elementStrains(n,2);
    end
    
    disp('   Performing Matlab calculations...');
    
    % load in the previous input file
    oldinputfile = ['CorticalAndTrabecularIteration',num2str(itnum,'%04i'),'.inp'];
    inputfile=fopen(oldinputfile);
    
    %read into one long string
    A=fscanf(inputfile,'%c',inf);
    fclose(inputfile);
    
    % Convert into cell array, where rows=lines
    B=strread(A,'%s','delimiter','\n');
    
    %store first set of invariable lines
    location1=find(strcmp(B,'**** Start of trabecular elements')==true);
    C1=B(1:location1+2);
    
    %store second set of invariable lines
    location2=find(strcmp(B,'**** End of section data')==true);
    C2=B(location2-1:size(B,1));
    
    % setting it up so that the trabecular and cortical elements are arranged into different sections
    if itnum==1;
        s1.previousRadii = 0.1.*ones(s1.numElements,1);
        s1.previousThickness = 0.1*ones(s1.numCorticalElements,1);
    else
        location3=find(strcmp(B,'**** Trabecular Cross-Sectional Radii')==true);
        C3=B{location3+1};
        s1.previousRadii = (str2num(C3(1,6:end)))';
        location4=find(strcmp(B,'**** Cortical Thicknesses')==true);
        C4=B{location4+1};
        s1.previousThickness = (str2num(C4(1,6:end)))';
    end
    
    s1.previousArea = pi.*s1.previousRadii.^2;
    
    target = 1250e-6;
    range = 250e-6;
    % increase dead zone over a number of increments
    deadzone = min([250e-6 250e-6*itnum/5]);
    
    numtrabsections = 256;
    numcortsections = 256;
    
    bonedensity=1600/(1000^3); % kg/m^3 to kg/mm^3
    
    %%%% start of trabecular elements
    
    nearzeroRadius=1e-3;
    nearzeroArea=pi*nearzeroRadius^2;
    
    % setting an upper limit
    maxradius = 2.0;
    % setting a lower limit
    minradius = 0.1;
    
    s1.sectionRadius = [linspace(minradius, maxradius, numtrabsections-1)];
    %
    s1.sectionArea = pi.*s1.sectionRadius.^2;
    
    s1.newArea=zeros(1,s1.numElements);
    for n=1:s1.numElements
        if (s1.axialStrain(n) > (target+range) || s1.axialStrain(n) < (target-range)) ...
            && s1.previousRadii(s1.elementRefs(n)) > nearzeroRadius
            s1.newArea(n) = s1.previousArea(n).*s1.axialStrain(n)./target;
        % allowing near zero high strain elements to 'regrow'
        elseif s1.axialStrain(n) > deadzone*(minradius/nearzeroRadius)^2 && s1.previousRadii(s1.elementRefs(n)) == nearzeroRadius
            s1.newArea = s1.sectionArea(1);
        else
            s1.newArea(n) = s1.previousArea(n);
        end
    end
    
    % total volume of trabecular bone
    trabecularVolume = sum(s1.originalElementLengths.*s1.newArea');
    
    % works when elements are not being eliminated
    s1.elementNonZeroAreaNodes=zeros(s1.numElements,2);
    for n=1:s1.numElements
        if s1.previousRadii(n) > nearzeroRadius
            s1.elementNonZeroAreaNodes(n,1:2) = s1.originalElementNodes(n,1:2);
        end
    end
    s1.elementNonZeroAreaNodes(s1.elementNonZeroAreaNodes==0) = [];
    
    % deriving a connectivity matrix for the nodes
    s1.nodeConnectivity=zeros(s1.numNodes,1);
    for n=1:s1.numNodes
        s1.nodeConnectivity(n)=sum(sum(s1.elementNonZeroAreaNodes==s1.nodes(n)));
    end
    s1.nodeConnectivitymean = mean(s1.nodeConnectivity(s1.nodeConnectivity~=0));
    s1.nodeConnectivitystdev = std(s1.nodeConnectivity(s1.nodeConnectivity~=0));
    s1.nodeConnectivitymin = min(s1.nodeConnectivity(s1.nodeConnectivity~=0));
    s1.nodeConnectivitymax = max(s1.nodeConnectivity(s1.nodeConnectivity~=0));
    
    % finding the nearest section area value
    s1.trabecularSection=zeros(1,s1.numElements);
    for n=1:size(s1.elementNums,1);
        [~,s1.trabecularSection(s1.elementRefs(n))]=min(abs(s1.sectionArea-s1.newArea(s1.elementRefs(n))));
        % getting rid of low radius, low strain elements
        if s1.trabecularSection(s1.elementRefs(n))==1 && s1.axialStrain(s1.elementRefs(n))<deadzone
%                 && s1.nodeConnectivity(s1.originalElementNodes(s1.elementRefs(n),1)) > 4 ...
%                 && s1.nodeConnectivity(s1.originalElementNodes(s1.elementRefs(n),2)) > 4
%             s1.nodeConnectivity(s1.originalElementNodes(s1.elementRefs(n),1))=s1.nodeConnectivity(s1.originalElementNodes(s1.elementRefs(n),1))-1;
%             s1.nodeConnectivity(s1.originalElementNodes(s1.elementRefs(n),2))=s1.nodeConnectivity(s1.originalElementNodes(s1.elementRefs(n),2))-1;
            s1.trabecularSection(s1.elementRefs(n))=0;
        end
        % this if statement could be removed to allow elements to 'regrow'
        if s1.newArea(s1.elementRefs(n))==nearzeroArea
            s1.trabecularSection(s1.elementRefs(n))=0;
        end
    end
    
    s1.trabecularSection=s1.trabecularSection+1;
    
    s1.sectionArea = [nearzeroArea s1.sectionArea];
    s1.sectionRadius = [nearzeroRadius s1.sectionRadius];
    s1.newArea = s1.sectionArea(s1.trabecularSection);
    s1.newRadii = s1.sectionRadius(s1.trabecularSection);
    trabecularsimilarity = sum(abs(s1.newArea - s1.previousArea') < 1e-6)/s1.numElements;
    trabecularelementratio = sum(s1.newRadii>nearzeroRadius)/sum(s1.previousRadii>nearzeroRadius);
    if trabecularsimilarity > 0.99 && abs(1-trabecularelementratio) < 0.001;
        trabecularstop=1;
    end
    
    %%%% end of trabecular elements
    
    %%%% start of cortical elements
    
    s1.newThickness=zeros(1,s1.numCorticalElements);
    % only updateing cortical thickness every second iteration
    % as cortical bone does not respond as quickly as trabecular bone
%     if itnum/2 == round(itnum/2)
        for n=1:s1.numCorticalElements      
            if s1.corticalStrain(n) > (target+range) || s1.corticalStrain(n) < (target-range)
                s1.newThickness(n) = s1.previousThickness(n).*s1.corticalStrain(n)./target;
            else
                s1.newThickness(n) = s1.previousThickness(n);
            end      
        end
%     else
%         s1.newThickness = s1.previousThickness;
%     end
    
    % setting an upper limit
    upperthicknesslimit=10;
    % setting a lower limit
    lowerthicknesslimit=0.1;
    
    s1.sectionThickness = [linspace(lowerthicknesslimit, upperthicknesslimit, numcortsections)];
    
    % finding the nearest section area value
    s1.corticalSection=zeros(1,s1.numCorticalElements);
    for n=1:s1.numCorticalElements
        [~,s1.corticalSection(n)]=min(abs(s1.sectionThickness-s1.newThickness(n)));
    % unlike trabecular elements, no cortical elements are removed
    end
    
    s1.newThickness = s1.sectionThickness(s1.corticalSection);
    
    % total volume of cortical bone
    corticalVolume = sum(s1.facesize.*s1.newThickness');
    
    corticalsimilarity = sum(abs(s1.newThickness - s1.previousThickness') < 1e-6)./s1.numCorticalElements;
    if corticalsimilarity >= 0.99;
        corticalstop=1;
    end
    
    %%%% end of cortical elements
    
    % write trabecular information to another file
    % as well as the Abaqus input file
    % leaving out nearzeroRadius elements (s1.trabecularSection(n)==1);
    trabinfo=['trabecularelementsiteration',num2str(itnum,'%04i'),'.txt'];
    trabfile=fopen(trabinfo,'w');
    for n=1:s1.numElements
        if s1.trabecularSection(n)~=1
            fprintf(trabfile,'%i, %i, %i, %1.9e, %+1.9e\n',s1.originalElements(n,1),s1.originalElements(n,2),s1.originalElements(n,3),...
                s1.sectionRadius(s1.trabecularSection(n)),s1.axialStrainTC(n));
        end
    end
    fclose(trabfile);
    
    % write cortical information to another file
    % as well as the Abaqus input file
    cortinfo=['corticalelementsiteration',num2str(itnum,'%04i'),'.txt'];
    cortfile=fopen(cortinfo,'w');
    for n=1:s1.numCorticalElements
        fprintf(trabfile,'%i, %i, %i, %i, %1.9e, %+1.9e\n',s1.originalCorticalElements(n,1),s1.originalCorticalElements(n,2),...
            s1.originalCorticalElements(n,3),s1.originalCorticalElements(n,4),...
            s1.sectionThickness(s1.corticalSection(n)),s1.corticalStrainTC(n));
    end
    fclose(cortfile);
    
%     if trabecularstop == 1 && corticalstop == 1 && itnum/2 == round(itnum/2)
    if trabecularstop == 1 && corticalstop == 1
        stop=1;
    end
    
    % update the iteration number
    % and write to file
    itnum=itnum+1;
    itnumfile=fopen('iteration.txt','w');
    fprintf(itnumfile,'%i',itnum);
    fclose(itnumfile);
    
    disp(['Iteration Number ',num2str(itnum,'%04i')]);
    disp(['   Number of Trabecular Elements: ', num2str(sum(s1.newRadii>nearzeroRadius))]);
    disp(['   Node Connectivity']);
    disp(['   Mean: ', num2str(s1.nodeConnectivitymean), ' SD: ', num2str(s1.nodeConnectivitystdev),...
    ' Min: ', num2str(s1.nodeConnectivitymin), ' Max: ', num2str(s1.nodeConnectivitymax)]);
    disp(['   Convergence']);
    disp(['   Trabecular: ', num2str(trabecularsimilarity), ' Cortical: ', num2str(corticalsimilarity)]);
    disp(['   Trabecular Element Number Ratio: ', num2str(trabecularelementratio)]);
    disp(['   Mass']);
    disp(['   Trabecular: ', num2str(trabecularVolume), 'mm^3 Cortical: ', num2str(corticalVolume), 'mm^3']);
    
    infomatrix = [itnum sum(s1.newRadii>nearzeroRadius) s1.nodeConnectivitymean s1.nodeConnectivitystdev...
        s1.nodeConnectivitymin s1.nodeConnectivitymax trabecularsimilarity corticalsimilarity trabecularelementratio...
        trabecularVolume corticalVolume {datestr(now-floor(now))} {datestr(floor(now))}];
    aa1=['A', num2str(itnum+2)];
    aa2=['M', num2str(itnum+2)];
    aa3=[aa1,':',aa2];
    xlswrite('iterationinfo.xls',infomatrix,aa3);
    
    %%%%
    %%%% Writing the NEW Abaqus input file
    %%%%
    
    newinputfile=['CorticalAndTrabecularIteration',num2str(itnum,'%04i'),'.inp'];
    outputfile=fopen(newinputfile,'w');
    
    % Print first set of invariable lines
    for i=1:1:size(C1,1)
        fprintf(outputfile,'%s\n',C1{i,1});
    end
    
    % writing trabecular element data out to the Abaqus input file
    for n=1:s1.numElements
        %if s1.trabecularSection(n)~=0
            fprintf(outputfile,'%i, %i, %i\n',s1.originalElements(n,1),s1.originalElements(n,2),s1.originalElements(n,3));
        %end
    end
    
    % writing the bit between element and section definitions
    fprintf(outputfile,'****\n**** End of trabecular elements\n****\n');
    fprintf(outputfile,'****\n**** Start of section data\n****\n');
    
    % writing section data out to the Abaqus input file
    fprintf(outputfile,'*Elset, elset=ES_CORTICAL, generate\n');
    fprintf(outputfile,'1, 10410, 1\n');
    % fprintf(outputfile,'*Shell Section, elset=ES_CORTICAL, material=BONE\n');
    % fprintf(outputfile,'1., 5\n');
    fprintf(outputfile,'*Elset, elset=ES_TRABECULAR, generate\n');
    fprintf(outputfile,'10411,229127,1\n');
    
    % defining the cortical element sets
    for n=1:numcortsections
        if sum(s1.corticalSection==n)>0;
            fprintf(outputfile,'*Elset, elset=ES_CORTICAL_%04i\n',n);
            clear a1; a1=find(s1.corticalSection==n);
            for m=1:sum(s1.corticalSection==n);
                fprintf(outputfile,'%i, ',s1.elementCorticalNums(a1(m)));
                % listed 8 elements per row
                if m/8 == round(m/8)
                    fprintf(outputfile,'\n');
                end
            end
            fprintf(outputfile,'\n');
        end
    end
    % defining the trabecular element sets
    for n=1:numtrabsections
        if sum(s1.trabecularSection==n)>0;
            fprintf(outputfile,'*Elset, elset=ES_TRABECULAR_%04i\n',n);
            clear a1; a1=find(s1.trabecularSection==n);
            for m=1:sum(s1.trabecularSection==n);
                fprintf(outputfile,'%i, ',s1.originalElementNums(a1(m)));
                % listed 8 elements per row
                if m/8 == round(m/8)
                    fprintf(outputfile,'\n');
                end
            end
            fprintf(outputfile,'\n');
        end
    end
    
    % defining the cortical sections
    for n=1:numcortsections
        if sum(s1.corticalSection==n)>0;
            fprintf(outputfile,'*Shell Section, elset=ES_CORTICAL_%04i, material=BONE\n',n);
            fprintf(outputfile,'%1.9e, 5 \n',s1.sectionThickness(n));
        end
    end
    % defining the trabecular sections
    for n=1:numtrabsections
        if sum(s1.trabecularSection==n)>0;
            fprintf(outputfile,'*Solid Section, elset=ES_TRABECULAR_%04i, material=BONE\n',n);
            fprintf(outputfile,'%1.9e\n',s1.sectionArea(n));
        end
    end
    
    % putting a comment in so the cortical thicknesses can be found next time round 
    fprintf(outputfile,'**** Cortical Thicknesses\n**** ');
    fprintf(outputfile,'%1.9e, ',s1.sectionThickness(s1.corticalSection));
    fprintf(outputfile,'\n');
    % putting a comment in so the trabecular areas can be found next time round
    fprintf(outputfile,'**** Trabecular Cross-Sectional Radii\n**** ');
    for n=1:s1.numElements
        if s1.trabecularSection(n)~=0
            fprintf(outputfile,'%1.9e, ',s1.sectionRadius(s1.trabecularSection(n)));
        else
            fprintf(outputfile,'0.0, ');
        end
    end
    fprintf(outputfile,'\n');
    
    % Print second set of invariable lines
    for i=1:1:size(C2,1)
        fprintf(outputfile,'%s\n',C2{i,1});
    end
    
    fclose(outputfile);
    
    %%%%
    %%%% Finished writing the NEW Abaqus input file
    %%%%
    
    % using a dos command to run the new input file
    abaquscommand01=['abaqus job=CorticalAndTrabecularIteration',num2str(itnum,'%04i'),' int ask_delete=OFF cpus=2'];
    disp('   Running the Input file...');
    [~,~]=dos(abaquscommand01,'-echo');
    
    % using a dos command to extract the strain data for the
    % NEW output database
    abaquscommand02=['abaqus cae noGUI=trabeculariterations.py'];
    disp('   Extracting information from the Output Database...');
    [~,~]=dos(abaquscommand02);
    
    fclose('all');
    
end

matlabsendmail


