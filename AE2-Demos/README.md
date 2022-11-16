# About AE2 Demos

## 15-11-2022 - Demo 1
fbG = 0.1; // normalization for SampleWriteLoop Feedback
cntrlMic(x) = 
            x : HP1(50) : LP1(6000) : integrator(.01) : 
                delayfb(.01,.9) : LP4(.5) : limit(1,0); 
                // delayfb(.01,.999) too much: block .9 better
without Butterworth filters (Orders Approximation)

## 15-11-2022 - Demo 2
fbG = 1; // normalization for SampleWriteLoop Feedback
cntrlMic(x) = 
            x : HP1(50) : LP1(6000) : integrator(.01) : 
                delayfb(.01,.9) : LP4(.5) : limit(1,0); 
                // delayfb(.01,.999) too much: block .9 better
without Butterworth filters (Orders Approximation)

## 16-11-2022 - Demo 1
// delayfb(.01,.999)
with Butterworth filters 
everything like the score

## 16-11-2022 - Demo 2
// delayfb(.01,.999)
with Butterworth filters 
everything like the score

## 16-11-2022 - Demo 3
// delayfb(.01,.999)
with Butterworth filters 
without Granular Sampling and Samplers = NAN (could be bandpass filter)