import("seam.discipio.lib");

//-----------------------signal flow 1a-----------------------
//Role of the signal flow block: generation of control signals based on mic3 and mic4 input

signalFlow1a(mic3, mic4) = 
diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain
    with{
        micSUM = mic3 + mic4;

        xminy(x,y) = x-y;
        localmaxSub(x) = ( mic3 : localmax(x) ), ( mic4 : localmax(x) ) : xminy;
        map6(x) = 6 + x * 6;
        map05(x) = x * .5;
        map6Sect(x) = x : integrator(.01) : delayfb(.01,.95);
        map6Sum = (mic3 : map6Sect) + (mic4 : map6Sect) : map6;
        localmaxSect = localmaxSub(map6Sum) : localmax(map6Sum);
        SenstoExt = localmaxSect <: _, delayfb(12,0) :> + : map05 : LP1(.5);
        mapSens = 1 - SenstoExt;

        integrSect005(x) = x : HP2(var2) : integrator(.05);
        integrSect010(x) = x : HP2(var2) : integrator(.10);
        integrSectXY = (micSUM : integrSect005), (micSUM : integrSect010) : xminy;
        integrSectmapSens = integrSectXY * mapSens;
        mapX05Sum05(x) = .5 + x * .5; 
        diffHL = integrSectmapSens : delayfb(0.01,0.995) : LP4(25.0) : mapX05Sum05;

        map1minSQ(x) = 1 - (x * x);
        memWriteLev = micSUM : integrator(.01) : delayfb(.01,.9) : LP4(25) : map1minSQ;
        memWriteDel1 = memWriteLev : delayfb(var1/2,0);
        memWriteDel2 = memWriteLev : delayfb(var1/3,0);

        mapwshape(x) = select2( x > 0.5, 1, ( 1-x ) * 2 );
        cntrlMain = 
            (mic3 + mic4) * SenstoExt : integrator(.01) : delayfb(.01,.995) : LP4(25);
        cntrlLev1 = cntrlMain : delayfb(var1/3,0);
        cntrlLev2 = cntrlMain : delayfb(var1/2,0);
        cntrlFeed = cntrlMain : mapwshape;
        };


process = noise(1), noise(2) : signalFlow1a;