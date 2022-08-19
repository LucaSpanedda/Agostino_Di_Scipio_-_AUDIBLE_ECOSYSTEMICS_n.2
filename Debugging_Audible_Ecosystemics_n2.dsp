declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
import("ae2lib.lib");

//------------------------------------------------------------------------------
audibleecosystemics2(mic1, mic2, mic3, mic4) =
//diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain
//cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3
//sig1, sig2, sig3, sig4, sig5, sig6, sig7
//out1, out2
//sf3
sig5, sig6
    with{
        // ------------------------------------------------------ Signal Flow 1a
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
        
        // ------------------------------------------------------ Signal Flow 1b
        cntrlMic(x) = 
            x : HP1(50) : LP1(6000) : integrator(.01) : 
                delayfb(.01,.999) : LP4(.5);
        cntrlMic1 = mic1 : cntrlMic;
        cntrlMic2 = mic2 : cntrlMic;
        directLevel = 
        // change 0.04 with (grainOut1 + grainOut2) (Faust FB loop)
            0.04 : integrator(.01) : delayfb(.01,.97) : LP4(.5) 
                <: _, delayfb(var1 * 2, (1 - var3) * 0.5) : +
                    : \(x).(1 - x * .5);
        timeIndex1 = triangleWave( 1 / (var1 * 2) ) : \(x).( (x - 2) * 0.5 );
        timeIndex2 = triangleWave( 1 / (var1 * 2) ) : \(x).( (x + 1) * 0.5 );
        triangle1 = triangleWave( 1 / (var1 * 6) ) * memWriteLev;
        triangle2 = triangleWave( var1 * (1 - cntrlMain) );
        triangle3 = triangleWave( 1 / var1 );

        // ------------------------------------------------------ Signal Flow 2a
        // for Sample Reads:
        ratio1 = (var2+(diffHL*1000))/261; memchunk1 = (1-memWriteDel2);
        ratio2 = (var2+(diffHL*1000))/261; memchunk2 = (1-memWriteDel2);
        ratio3 = (var2+(diffHL*1000))/261; memchunk3 = (1-memWriteDel2);
        ratio4 = (var2+(diffHL*1000))/261; memchunk4 = (1-memWriteDel2);
        ratio5 = (var2+(diffHL*1000))/261; memchunk5 = (1-memWriteDel2);

        micIN1 = mic1 : HP1(50) : LP1(6000) * (1 - cntrlMic1);
        micIN2 = mic2 : HP1(50) : LP1(6000) * (1 - cntrlMic2);
        SRSect1(x) = x : sampler(var1, memchunk1, ratio1) : 
            HP4(50) : delayfb(var1/2, 0);
        SRSect2(x) = x : sampler(var1, memchunk2, ratio2) : 
            HP4(50) : delayfb(var1, 0);
        SRSect3(x) = x : sampler(var1, memchunk3, ratio3) : 
            HP4(50);
            SRSectBP1(x) = x : SRSect3 : 
                BPsvftpt(diffHL * 400, ma.EPSILON+(var2 / 2) * memWriteDel2);
            SRSectBP2(x) = x : SRSect3 : 
                BPsvftpt((1-diffHL) * 800, ma.EPSILON+var2 * (1-memWriteDel1));
        SRSect4(x) = x : sampler(var1, memchunk4, ratio4);
        SRSect5(x) = x : sampler(var1, memchunk5, ratio5);
        SRLoopSect = 
        \(fb).
        (
            (
                (SRSect1(fb), SRSect2(fb), SRSectBP1(fb), SRSectBP2(fb) :> +)
                    * (cntrlFeed * memWriteLev) 
            ) <: (_ + (micIN1 + micIN2) : _ * triangle1), _,
            SRSect4(fb), SRSect5(fb), SRSect3(fb)
        ) ~ _ ;
        sig1 = micIN1 * directLevel;
        sig2 = micIN2 * directLevel;
        sampWOut = SRLoopSect : \(A,B,C,D,E).(A);
        sig3 = SRLoopSect : \(A,B,C,D,E).(B) : 
            _ * memWriteLev : delayfb(.05 * cntrlMain, 0) 
                * triangle2 * directLevel;
        sig4 = SRLoopSect : \(A,B,C,D,E).(B) : 
            _ * memWriteLev * (1-triangle2) * directLevel;
        sig5 = SRLoopSect : \(A,B,C,D,E).(C) : 
            HP4(50) : delayfb(var1 / 3, 0);
        sig6 = SRLoopSect : \(A,B,C,D,E).(D) : 
            HP4(50) : delayfb(var1 / 2.5, 0);
        sig7 = SRLoopSect : \(A,B,C,D,E).(E) : 
            delayfb(var1 / 1.5, 0) * directLevel;
        
        // ------------------------------------------------------ Signal Flow 2b
        grainOut1 = granular_sampling
            (1,var1,timeIndex1,memWriteDel1,cntrlLev1,21,sampWOut);
        grainOut2 = granular_sampling
            (1,var1,timeIndex2,memWriteDel2,cntrlLev2,20,sampWOut);
        out1 = 
            (
                ( sig5 : delayfb(.04, 0) * (1 - triangle3) ),
                    ( sig5 * triangle3 ),
                        ( sig6 : delayfb(.036, 0) * (1 - triangle3) ),
                            ( sig6 : delayfb(.036, 0) * triangle3 ),
                                sig1, sig2, sig4,
                                    grainOut1 * (1 - memWriteLev) + 
                                        grainOut2 * memWriteLev 
                                            ) :> +;
        out2 = 
            (
                ( sig5 * (1 - triangle3) ),
                    ( sig5 : delayfb(.040, 0) * triangle3 ),
                        ( sig6 * (1 - triangle3) ),
                            ( sig6 * triangle3 ),
                                sig2 + sig3 + sig7,
                                    grainOut1 * memWriteLev + 
                                        grainOut2 * (1 - memWriteLev)
                                            ) :> +; 

        // ------------------------------------------------------ Signal Flow 3-
        sf3 = out1, out2, 
            (out2 : delayfb(var4/2/344, 0)), (out1 : delayfb(var4/2/344, 0)),
                (out1 : delayfb(var4/344, 0)), (out2 : delayfb(var4/344, 0));
    };
    
//process = _ <: _@0, _@4000, _@6000, _@10000 : audibleecosystemics2;
process = _*.5 <: 
    _*(noise(1):LP1(1000)), 
        _*(noise(2):LP1(1000)), 
            _*(noise(3):LP1(1000)), 
                _*(noise(4):LP1(1000)) : 
                    audibleecosystemics2;