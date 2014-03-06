load('106m.mat')

%% Rescaling and time

% val = val(1500:end); %cutting out the first bit of noise

sampleRate = 1/360;
mvScaling = 1/200;  %rescaling for 200mv
ecg = mvScaling * val(1,:); % scale down for detection
numVals = length(val);
sampleTime = 0.002777777778;

rThreshold = 0.7;
ptThresholdLow = 0.2;
ptThresholdHigh = 0.7;



time = sampleRate:sampleRate:(numVals*sampleTime);
time = time(1:length(ecg));
time = sampleRate:sampleRate:(sampleRate*length(ecg));


% bandpass filter
[B, A] = butter(4, [0.5/180 40/180]);   % bandpass frequencesi at 1 Hz and 40 Hz

freqEcg = filter(B,A,ecg);

%% detection QRS complexes and R waves

qrsThreshold = freqEcg > rThreshold;
qrsValid = zeros(1, length(qrsThreshold));

ptThreshold = freqEcg > ptThresholdLow & freqEcg < ptThresholdHigh;
ptValid = zeros(1, length(ptThreshold));

for i = 2:length(qrsThreshold) - 1
    if (qrsThreshold(i) == 1)
        slope1 = freqEcg(i) - freqEcg(i-1);
        slope2 = freqEcg(i+1) - freqEcg(i);
        if slope1 > 0 && slope2 < 0
            qrsValid(i) = 1;
        end
    end
end

%% All non R waves

for i = 2:length(ptThreshold) - 1
    if (ptThreshold(i) == 1)
        slope1 = freqEcg(i) - freqEcg(i-1);
        slope2 = freqEcg(i+1) - freqEcg(i);
        if slope1 > 0 && slope2 < 0
            ptValid(i) = 1;
        end
    end
end

ptWaves = find(ptValid);

hold on
rWaves = find(qrsValid);
tWavesValid = zeros(1, length(qrsThreshold));

%% Identifying T waves

for i = 1:length(rWaves)-1
    display(rWaves(i))
    validPTWaves = find(ptValid(rWaves(i) + 1:rWaves(i+1) - 1))
    if length(validPTWaves) >= 1
        tWavesValid(rWaves(i) + validPTWaves(1))= 1;
    end
end

tWaves = find(tWavesValid);

%% RR intervals

rrIntervals = zeros(1, length(rWaves) - 1);

for i = 1:length(rrIntervals) - 1
    rrIntervals(i) = time(rWaves(i + 1)) - time(rWaves(i));
end

%% Histogram plot

figure(1)
hist(rrIntervals, 50)

%% premature interval: 0.2 to 0.6 seconds

premIntLow = 0.2;
premIntHigh = 0.6;

prematureRWaves = zeros(1, length(rWaves) - 1);

for i = 1:length(rWaves) - 1
    timeInt = time(rWaves(i + 1)) - time(rWaves(i));
    if timeInt >= 0.3 && timeInt <= 0.7
        prematureRWaves(i+1) = 1;
    end
end

validPrematureRWaves = rWaves(find(prematureRWaves));

firstPrematureContraction = validPrematureRWaves(22)

leftRightTimeRange = 4 / sampleTime

%% Rest of the plots

figure(2)
hold on
plot(time, ecg,'b');

figure(3)
hold on
plot(time,freqEcg,'b');


figure(4)
hold on
plot(time,freqEcg,'b');
plot(time(rWaves), freqEcg(rWaves), 'or');

figure(5)
hold on
plot(time,freqEcg,'b');
plot(time(rWaves), freqEcg(rWaves), 'or');
plot(time(tWaves), freqEcg(tWaves), 'og');
plot(time(validPrematureRWaves), freqEcg(validPrematureRWaves), 'xb');

figure(6)
hold on
plot(time(firstPrematureContraction - leftRightTimeRange:firstPrematureContraction + leftRightTimeRange) ,freqEcg(firstPrematureContraction - leftRightTimeRange:firstPrematureContraction + leftRightTimeRange)*200,'b');
plot(time(rWaves), freqEcg(rWaves)*200, 'or');
plot(time(tWaves), freqEcg(tWaves)*200, 'og');
plot(time(validPrematureRWaves), freqEcg(validPrematureRWaves)*200, 'xk');