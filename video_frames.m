% Implement manual frame selection
% Some frames are inexplicably bad
% Many frames are just green

clear all

subject = 'BCI15-01';
session = 's1';

cd(['/Volumes/HDD/data/BCI/footage/' subject '/' session]);

% Get all the video files

contents = dir('cam-near');
nearVids = {};
for fileno = 3:length(contents)
    if strcmp(contents(fileno).name(end-2:end),'mp4')
        nearVids{end+1} = contents(fileno).name;
    end
end

contents = dir('cam-far');
farVids = {};
for fileno = 3:length(contents)
    if strcmp(contents(fileno).name(end-2:end),'mp4')
        farVids{end+1} = contents(fileno).name;
    end
end

if length(nearVids) ~= length(farVids)
    
    fprintf(1,'Error: Different number of videos for each camera\n')
    
end

% Combine the videos

outObj = VideoWriter('output.mp4','MPEG-4');
outObj.FrameRate=2;
open(outObj)

for vidNo = 1%:length(nearVids)

    inObjNear = VideoReader(['cam-near/' char(nearVids(vidNo))]);
    inObjFar = VideoReader(['cam-far/' char(farVids(vidNo))]);
    [~] = read(inObjNear,inf);
    [~] = read(inObjFar,inf);
    nFramesNear = inObjNear.NumberOfFrames;
    nFramesFar = inObjFar.NumberOfFrames;
    minFrames = min(nFramesNear,nFramesFar);
    
    % Find the pattern of good frames

    goodFramesNear = [];
    goodFramesFar = [];
    for fNo = 100:250
        tempN = read(inObjNear,49);
        tempF = read(inObjFar,48);
        if length(unique(tempN)) > 3, goodFramesNear = [goodFramesNear fNo]; end
        if length(unique(tempF)) > 3, goodFramesFar = [goodFramesFar fNo]; end
    end
           
    % Fix these
    
    firstGoodFrameNear = find(diff(goodFramesNear)==30);
    firstGoodFrameNear = goodFramesNear(firstGoodFrameNear(1));
    
    firstGoodFrameFar = find(diff(goodFramesFar)==30);
    firstGoodFrameFar = goodFramesFar(firstGoodFrameFar(1));
    
    % manual frame selection
    
    nFramesNear = (inObjNear.Duration - inObjNear.CurrentTime) * 30;%inObjNear.FrameRate;
    nFramesFar = (inObjFar.Duration - inObjFar.CurrentTime) * 30;%inObjFar.FrameRate;
    goodFramesNear = firstGoodFrameNear:30:nFramesNear;
    goodFramesFar = firstGoodFrameFar:30:nFramesFar;
    minFrames = min(length(goodFramesNear),length(goodFramesFar));
    goodFramesNear = goodFramesNear(1:minFrames);
    goodFramesFar = goodFramesFar(1:minFrames);

    for frameNo = 1:minFrames
        
%         inObjFar.CurrentTime = tFarPad + (goodFramesFar(frameNo)/inObjFar.FrameRate) - (1/inObjFar.FrameRate); image(readFrame(inObjFar))
%         frameTop = readFrame(inObjFar);
        frameTop = read(inObjFar,goodFramesFar(frameNo));
        
%         inObjNear.CurrentTime = tNearPad + (goodFramesNear(frameNo)/inObjNear.FrameRate) - (1/inObjNear.FrameRate); image(readFrame(inObjNear))
%         frameBottom = readFrame(inObjNear);
        frameBottom = read(inObjNear,goodFramesFar(frameNo));

        frameBottomCrop = frameBottom(181:end,:,:);
        newFrame = vertcat(frameTop,frameBottomCrop);
        writeVideo(outObj,newFrame);
        
        if mod(frameNo,2) == 1, bar(frameNo/minFrames*100); ylim([0 100]); title('Progress'); pause(1/1000); end

    end
    
end

close(outObj)