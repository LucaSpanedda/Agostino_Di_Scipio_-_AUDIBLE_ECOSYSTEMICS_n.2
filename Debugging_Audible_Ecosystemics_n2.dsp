declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
import("ae2lib.lib");

//------------------------------------------------------------------------------
audibleecosystemics2(mic1, mic2, mic3, mic4) =
diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain
    with{
        // ------------------------------------------------------ SIGNAL FLOW 1A
        outFromSixPlusSixTimesX = 
            (mic3 : integrator(.01) : delayfb(.01,.95)) + 
                (mic4 : integrator(.01) : delayfb(.01,.95)) : 
                    max(0.0, min(1.0)) : \(x).(6 + x * 6);
        localMaxDiff = 
            ((outFromSixPlusSixTimesX, mic3) : localmax) , 
                ((outFromSixPlusSixTimesX, mic4) : localmax) :
                    \(x,y).(x-y);
        SenstoExt = 
            (outFromSixPlusSixTimesX, localMaxDiff) : localmax
                <: _ , delayfb(12, 0) : + : * (.5) : LP1(.5);
        diffHL = 
            ((mic3 + mic4) : HP2(var2) : integrator(.05)) , 
                ((mic3 + mic4) : LP2(var2) : integrator(.10)) : 
                    \(x,y).(x-y) * (1 - SenstoExt) : 
                        delayfb(0.01,0.995) : LP4(25.0) : \(x).(.5 + x * .5) : 
                            max(0.0, min(1.0));
        memWriteLev = 
            (mic3 + mic4) : integrator(.1) : delayfb(.01,.9) : 
                LP4(25) : \(x).(1 - (x * x));
        memWriteDel1 = memWriteLev : delayfb(var1 / 2, 0);
        memWriteDel2 = memWriteLev : delayfb(var1 / 3, 0);
        cntrlMain = 
            (mic3 + mic4) * SenstoExt : integrator(.01) : 
                delayfb(.01,.995) : LP4(25);
        cntrlLev1 = cntrlMain : delayfb(var1 / 3, 0);
        cntrlLev2 = cntrlMain : delayfb(var1 / 2, 0);
        cntrlFeed = cntrlMain : \(x).(ba.if(x <= .5, 1.0, (1.0 - x) * 2.0));

    };
    
process = _ <: _@0000, _@1000, _@2000, _@3000 : audibleecosystemics2;
