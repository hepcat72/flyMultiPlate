% find the first time at which the duration of nans implies probable death

% probableDeathTime_sec
probableDeathTime_frames = probableDeathTime_sec/(nanmean(outCentroids(:,1)));

% append the opposite state at the end in case something continues to be "dead" forever
isCentroidNans = double([isnan(outCentroids);not(isnan(outCentroids(end,:)))]); 

for iiWell = 1:size(wellCoordinates,1)
    fromNumericToNanIndex = find(diff(isCentroidNans(2*iiWell-1,:))~=0);
    timeBetweenNanSwitching = diff(fromNumericToNanIndex);
    firstSwitch = find(timeBetweenNanSwitching>probableDeathTime_frames,1,'first');
    timeOfFirstSwitch(iiWell) = fromNumericToNanIndex(firstSwitch);
end