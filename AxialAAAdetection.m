%% automated detection and quantification of AAA within axial CT scans
% stewart mclennan

%% housekeeping
clear;close all;clc;

%% AAA axial CT images
AAAdir = fullfile(pwd,'.\PNG Images');
% convenient reference for image collection 
imgSet = imageSet(AAAdir) %#ok<*NOPTS>
methods(imgSet)
editorwindow

%% create a display of all AAA images
togglefig('AAA Images')
ax = gobjects(imgSet.Count,1);
for ii = 1:imgSet.Count
	ax(ii) =...
		subplot(floor(sqrt(imgSet.Count)+1),ceil(sqrt(imgSet.Count)+1),ii); 
    % may need to change subplot dimensions depending on no. of images 
	[~,currName] = fileparts(imgSet.ImageLocation{ii});
	imshow(read(imgSet,ii))
	title([num2str(ii),') ' currName],...
		'interpreter','none','fontsize',7)
end
expandAxes(ax);

%% select a target image inorder to develop algorithm
targetImgNum = 15;
togglefig('AAA Images')
[~,imName] = fileparts(imgSet.ImageLocation{targetImgNum});
set(ax,'xcolor','r','ycolor','r',...
	'xtick',[],'ytick',[],'linewidth',2,'visible','off')
set(ax(targetImgNum),'visible','on');

%% read target image
targetImage = getimage(ax(targetImgNum));
togglefig('Target Image')
clf
imshow(targetImage)
title(imName,'interpreter','none','fontsize',12);

%% segmentation
% % distinguish the regions of interest
colorThresholder(targetImage)
imageSegmenter(targetImage) %-> 'segmentImageFcn.m'

%% Apply auto-generated segmenter
AAAmask = segmentImageFcn(targetImage);
togglefig('AAA Mask')
imshow(AAAmask);

%% check how approach generalises with other training images
togglefig('AAA Images',true)
refreshImages
for ii = 1:imgSet.Count
	mask = segmentImageFcn(getimage(ax(ii)));
	showMaskAsOverlay(0.5,mask,'b',[],ax(ii))
	drawnow
end
expandAxes(ax);

%% machine learning
clear;close all;clc; 

%% differentiating presence/severity of aneurym from different images
% create an image set
imgSet = imageSet(fullfile(pwd,'.\PNG Images'),...
	'recursive')  
disp(['Your imageSet contains ', num2str(sum([imgSet.Count])),...
	' images from ' num2str(numel(imgSet)) ' classes.']);

%% check what images look like
subset = select(imgSet,1:2);
subsetNames = [subset.ImageLocation];
subsetLabels = {};
for ii = 1:numel(subset)
	subsetLabels{ii} = repelem({subset(ii).Description},subset(ii).Count,1);
end
subsetLabels = vertcat(subsetLabels{:});
togglefig('Sample Images',1)
[hpos,hdim] = distributeObjects(numel(subset),0.05,0.95,0.01);
[vpos,vdim] = distributeObjects(3,0.95,0.05,0.025);
ax = gobjects(numel(subset),1);
[hind,vind] = meshgrid(1:numel(imgSet),1:subset(1).Count);
for ii = 1:numel(subsetNames)
	ax(ii) = axes('Units','Normalized',...
		'Position',...
		[hpos(hind(ii)) vpos(vind(ii)) hdim vdim]);
	imshow(subsetNames{ii});
	title(subsetLabels{ii},'fontsize',8)
end
expandAxes(ax);

%% partition imageSet into training and test sets
[trainingSets, testSets] = partition(imgSet,0.7,'randomized');

%% create a visual bag of features to describe the training set
bag = bagOfFeatures(trainingSets);
editorwindow;

%% visulise feature vectors
togglefig('Encoding',true)
for ii = 1:numel(imgSet)
	img = read(imgSet(ii), randi(imgSet(ii).Count));
	featureVector = encode(bag, img);
	subplot(numel(imgSet),2,ii*2-1);
	imshow(img);
	title(imgSet(ii).Description)
	subplot(numel(imgSet),2,ii*2);
	bar(featureVector);
	set(gca,'xlim',[0 bag.VocabularySize])
	title('Visual Word Occurrences');
	if ii == numel(imgSet)
		xlabel('Visual Word Index');
	end
	if ii == floor(numel(imgSet)/2)
		ylabel('Frequency of occurrence');
	end
end
                                                                                                      editorwindow;
%% train category classifier on the training set
classifier = trainImageCategoryClassifier(trainingSets,bag);

%% evaluate the classifier on the test set
[confMat,knownLabelIdx,predictedLabelIdx,predictionScore] = ...
	evaluate(classifier,testSets);
avgAccuracy = mean(diag(confMat));
togglefig('Prediction')
imagesc(confMat)
colorbar

%% use the classifier to predict class membership
togglefig('Prediction')
ii = randi(size(imgSet,2));
img = read(imgSet(ii),randi(imgSet(ii).Count));
[labelIdx, predictionScore] = predict(classifier,img);
bestGuess = classifier.Labels(labelIdx);
actual = imgSet(ii).Description;
imshow(img)
t = title(['Best Guess: ',bestGuess{1},'; Actual: ',actual]);                                                          editorwindow
if strcmp(bestGuess{1},actual)
	set(t,'color',[0 0.7 0])
else
	set(t,'color','r')
end

%% try other classifiers using the classificationLearner
% here we recreate the bag of features from all images, and cast it to a
% table to facilitate working with the classificationLearner app
bag = bagOfFeatures(imgSet)
aneurysmData = double(encode(bag, imgSet));
AneurysmImageData = array2table(aneurysmData);
aneurysmType = categorical(repelem({imgSet.Description}',...
	[imgSet.Count], 1));
AneurysmImageData.aneurysmType = aneurysmType;                                                                           editorwindow;

%% use the new features to train a model and assess its performance using 
classificationLearner

%% if in-sufficient, try again with a 2D-class model and custom extractor
clear('trainedClassifier*')
% create a single-source of non-aneurysmal images:
nonAneurysmal = imgSet(~strcmp({imgSet.Description},'AAA PNG Images'));
nonAneurysmal = imageSet([nonAneurysmal.ImageLocation]);
nonAneurysmal.Description = 'nonAAA PNG Images';
% create a aneurysmal/non-aneurysmal source:
twoClassSet = cat(1,nonAneurysmal,...
	imgSet(strcmp({imgSet.Description},'AAA PNG Images')))
% re-learn bag of features representation
extractorFcn = @customAneurysmFcn;
% use:
%  custom extractor
%  all features
%  larger vocabularly
bag = bagOfFeatures(twoClassSet,...
	'CustomExtractor',extractorFcn,...
	'StrongestFeatures',1,...
	'VocabularySize',1000);
aneurysmData = double(encode(bag, twoClassSet));
AneurysmImageData = array2table(aneurysmData);
aneurysmType = categorical(repelem({twoClassSet.Description}',...
	[twoClassSet.Count], 1));
AneurysmImageData.aneurysmType = aneurysmType;
classificationLearner

%% export model -> trainedModel
trainedClassifier

%% use the classifier to predict class membership
% predict anuerysmal/non-aneruysmal state in a randomly selected test image
% or...
% plug in patient specific image here to find aneurysm region and
% mechanical properties
ii = randi(size(twoClassSet,1));
jj = randi(twoClassSet(ii).Count);
img = read(twoClassSet(ii),jj);
togglefig('Test Image'); set(gcf,'color','w');
imshow(img)
% adding code to invoke the trained classifier
imagefeatures = double(encode(bag, img));
% find two closest matches for each feature
[bestGuess, predictionScore] = predict(trainedClassifier,imagefeatures);
% display the string label for img
if strcmp(char(bestGuess),twoClassSet(ii).Description)
	titleColor = [0 0.8 0];
else
	titleColor = 'r';
end
title(sprintf('Best Guess: %s;\nActual: %s',...
	char(bestGuess),twoClassSet(ii).Description),...
	'color',titleColor)
editorwindow;
