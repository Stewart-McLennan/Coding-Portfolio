%% Creating Finite Element Structural Mesh
% Stewart McLennan

%% Algorithm
% setting up a for loop so this can extended to any number of part meshes
function [] = createstructuralmesh(k1,meshnames)

% setting filenames
datafile01=(['nodeinfo',char(meshnames(k1)),'.txt']);
datafile02=(['SurfaceElementsMeshEL5',char(meshnames(k1)),'.txt']);

% load in the nodes file
s1.nodes = dlmread(datafile01,',');
s1.numNodes = size(s1.nodes,1);

% node shift to take node numbers from 1 to ...
nodeshift=min(s1.nodes(:,1))-1;

% adjusting node numbers
s1.nodes(:,1) = s1.nodes(:,1)-nodeshift;

% load in the surface elements file
s1.triElements = dlmread(datafile02,',');

% element shift to take tri elements numbers from 1 to ...
elemshift=min(s1.triElements(:,1))-1;

% adjusting element and node numebrs
s1.triElements(:,1) = s1.triElements(:,1)-elemshift;
s1.triElements(:,2) = s1.triElements(:,2)-nodeshift;
s1.triElements(:,3) = s1.triElements(:,3)-nodeshift;
s1.triElements(:,4) = s1.triElements(:,4)-nodeshift;

% for each node find the nearest nodes
% avoiding other surface nodes of the surface nodes

s1.allNodes = s1.nodes(:,1)';
s1.externalNodes = unique([s1.triElements(:,2)' s1.triElements(:,3)' s1.triElements(:,4)']);
s1.internalNodes = setdiff(s1.allNodes,s1.externalNodes);
s1.numInternalNodes = size(s1.internalNodes,2);

% set the number of connections for each node
s1.connectivity = 16;

s1.nodeConnectivity = zeros(s1.connectivity,s1.numNodes);

for n=1:s1.numNodes
    if n/100 == round(n/100)
        disp(n);
    end
    %
    clear elemlength sortelemlength
    elemlength=zeros(1,s1.numInternalNodes);
    %
    elemlength(1,:) = sqrt((s1.nodes(s1.internalNodes,2)-s1.nodes(n,2)).^2 + ...
        (s1.nodes(s1.internalNodes,3)-s1.nodes(n,3)).^2 + ...
        (s1.nodes(s1.internalNodes,4)-s1.nodes(n,4)).^2);
    sortelemlength = sort(elemlength);
    sortelemlength(1)=[];
    %
    for m=1:s1.connectivity
        s1.nodeConnectivity(m,n)=s1.internalNodes(find(elemlength==sortelemlength(m),1,'first'));
        s1.elemlengths(m,n)=sortelemlength(m);
    end
    %
end

% sorting out the element definitions
s1.elemNodes = zeros(s1.connectivity.*s1.numNodes,2);
s1.elemNodes(:,1) = (reshape(repmat((1:s1.numNodes),s1.connectivity,1),1,[]))';
s1.elemNodes(:,2) = (reshape(s1.nodeConnectivity,1,[]))';
s1.elemNodesSort = sortrows(sort(s1.elemNodes,2));
s1.elemNodesUnique = unique(s1.elemNodesSort,'rows');

%%%% start writing the Abaqus input file

s1.numCortElem = size(s1.triElements,1);
s1.numTrabElem = size(s1.elemNodesUnique,1);

% adding the the Abaqus input file
file1=fopen('mesoscale_femur_and_tibia.inp','a');
fprintf(file1,'*PART, name=Structural%s\n**\n',char(meshnames(k1)));
fprintf(file1,'*NODE\n');
for n=1:s1.numNodes
    fprintf(file1,'%i, %1.9e, %1.9e, %1.9e\n',s1.nodes(n,1),s1.nodes(n,2),s1.nodes(n,3),s1.nodes(n,4));
end
fprintf(file1,'**\n** CORTICAL SHELL ELEMENTS\n**\n');
fprintf(file1,'*ELEMENT, TYPE=S3, ELSET=ES_CORTICAL_%s\n',char(meshnames(k1)));
for n=1:s1.numCortElem;
    fprintf(file1,'%i, %i, %i, %i\n',s1.triElements(n,1),s1.triElements(n,2),s1.triElements(n,3),s1.triElements(n,4));
end
fprintf(file1,'**\n** TRABECULAR BAR ELEMENTS\n**\n');
fprintf(file1,'*ELEMENT, TYPE=T3D2, ELSET=ES_TRABECULAR_%s\n',char(meshnames(k1)));
for n=1:s1.numTrabElem;
    fprintf(file1,'%i, %i, %i\n',n+s1.numCortElem,s1.elemNodesUnique(n,1),s1.elemNodesUnique(n,2));
end
fclose('all');

%%%% finish writing the Abaqus input file

% write out the original trabecular elements
datafile03=(['trabecularelements',char(meshnames(k1)),'.txt']);
file2=fopen(datafile03,'w');
for n=1:s1.numTrabElem;
    fprintf(file2,'%i, %i, %i\n',n+s1.numCortElem,s1.elemNodesUnique(n,1),s1.elemNodesUnique(n,2));
end
fclose('all');