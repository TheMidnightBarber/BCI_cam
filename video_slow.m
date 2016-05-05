% Implement manual frame selection

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
    return
    
end

% Combine the videos

outObj = VideoWriter('output.mp4','MPEG-4');
outObj.FrameRate=2;
open(outObj)

for vidNo = 1%:length(nearVids)

    inObjNear = VideoReader(['cam-near/' char(nearVids(vidNo))]);
    inObjFar = VideoReader(['cam-far/' char(farVids(vidNo))]);
    
    % Set the videos to begin at the same time
    
    tNear = inObjNear.Duration;
    tFar = inObjFar.Duration;
    
    if tNear < tFar, inObjFar.CurrentTime = tFar - tNear; end
    if tFar < tNear, inObjNear.CurrentTime = tNear - tFar; end
    
    nearStart = inObjNear.CurrentTime;
    nearEnd = inObjNear.Duration;
    
    while inObjFar.Duration - inObjFar.CurrentTime > 1.5
        
        badframe = 1;
        while badframe == 1
            frameTop = readFrame(inObjFar);
            if length(unique(frameTop)) > 3, badframe = 0; end
        end
        
        badframe = 1;
        while badframe == 1
            frameBottom = readFrame(inObjNear);
            if length(unique(frameBottom)) > 3, badframe = 0; end
        end

        frameBottomCrop = frameBottom(181:end,:,:);
        newFrame = vertcat(frameTop,frameBottomCrop);
        writeVideo(outObj,newFrame);
        
        nearNow = inObjNear.CurrentTime;
        percent = (nearNow - nearStart) / (nearEnd - nearStart) * 100;
        bar(percent); ylim([0 100]); title('Progress'); pause(1/1000);

    end
    
end

close(outObj)