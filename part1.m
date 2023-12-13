folder = './DB1';
files = dir(fullfile(folder, '*.jpg'));

% Initialize cell arrays
allImages = cell(1, numel(files));
modifiedImages = cell(1, numel(files));
simplemodifiImages = cell(1, numel(files));
eyeMaps = cell(1, numel(files));
mouthMaps = cell(1, numel(files));
skinMaps = cell(1, numel(files));
combinedMaps = cell(1, numel(files));
skinEyeMaps = cell(1, numel(files));  % Added for storing combined skin and eye maps

% New initialize cell arrays
eyeMaps2 = cell(1, numel(files));
mouthMaps2 = cell(1, numel(files));

figure;

for i = 1:numel(files)
    filename = fullfile(folder, files(i).name);
    image = imread(filename);

    % Size of current image in folder (for alignment function)
    imageSize = size(image);
    imageSize = imageSize(1:2);
    
    image_corr = colorCorrectionRGB(image);
    allImages{i} = image_corr; % save corrected image to array

    RGB = allImages{i};
    YCrCb = ConvertRGB2YCrCb(RGB); 

    % detectioncalls
    skinMask = skinDetection(image_corr); 
    eyeMap = eyeDetection(YCrCb);
    mouthMap = mouthDetection(YCrCb);

    % Combine all maps into one map of the face
    skinmask_in = imcomplement(skinMask); % complement of the skinMap
    eyeSkinMap =  skinmask_in + eyeMap;
    mouthSkinMap =  skinMask - mouthMap;

    eyeMaps{i} = eyeMap;
    mouthMaps{i} = mouthMap;
    skinEyeMaps{i} = eyeSkinMap;
    skinMaps{i} = skinMask;
   
    % Insert markers into the image
    [leftEyePos, rightEyePos, mouthPos] = drawLine(eyeMap, mouthMap);

    % Concatenate eye and mouth positions into a 2D array
    if isempty(leftEyePos) || isempty(rightEyePos) || isempty(mouthPos)
         % Handle the case where positions are empty or detection failed
         disp(['Processing failed for image ', num2str(i)]);
         continue; % Skip to the next iteration
    end

    % alignment for the eyes (stright line) of every image and crops image
    % into [400, 300] size
    rotatedImage = rotateImage(RGB, leftEyePos, rightEyePos);

    % Calc the locations of the eye and mouth coordinates again
    fixedImage = ConvertRGB2YCrCb(rotatedImage);

    % Secound eyedetection for gathering the new coordinates after rotation
    eyeMap2 = eyeDetection2(fixedImage);
    mouthMap2 = mouthDetection2(fixedImage);

    eyeMaps2{i} = eyeMap2;
    mouthMaps2{i} = mouthMap2;

    %  % ONLY FOR DEBUGGING! Check if the eyes are approximately horizontal
    % horizontalThreshold = 0.2; 
    % areEyesHorizontal = abs(leftEyePos(2) - rightEyePos(2)) < horizontalThreshold;
    % 
    % if ~areEyesHorizontal
    %     disp('Eyes are not horizontal.');
    %     abs(leftEyePos(2) - rightEyePos(2))
    % end
    
    % Markings on the output image for debugging
    [updatedLeftEyePos, updatedRightEyePos, updatedMouthPos] = drawLine(eyeMap2, mouthMap2);
    markerPositions = [updatedLeftEyePos; updatedRightEyePos; updatedMouthPos];
    endImage = insertMarker(rotatedImage, markerPositions, 'color', 'red', size = 20);
    
    %Store modified image in cell array
    modifiedImages{i} = endImage;
end

% Display images
for i = 1:numel(files)

    % Display the combined skin eyemap
    subplot(2, 3, 1);
    imshow(eyeMaps{i});
    title('Eye Map');
    
    % Display the combined skin mouthmap
    subplot(2, 3, 2);
    imshow(mouthMaps{i});
    title('Mouth Map');

    % Display modified image with the red crosses
    subplot(2, 3, 3);
    imshow(modifiedImages{i});
    title('Modified Rotated and translated Image with Red Crosses');

    % Add a pause between each image
    pause(3);
end
