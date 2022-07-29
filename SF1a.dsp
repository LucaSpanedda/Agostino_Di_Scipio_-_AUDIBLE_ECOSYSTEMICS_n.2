import("seam.discipio.lib");

//-----------------------signal flow 1a-----------------------
//Role of the signal flow block: generation of control signals based on mic3 and mic4 input

signalFlow1a(mic3, mic4) = 
diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
mic3, mic4
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
        /*
        process = 
            ( noise(1), 
              noise(2) )
                :
                signalFlow1a;
                */
            // OUTS
            diffHL = signalFlow1a : _,!,!,!,!,!,!,!,!,!;
            memWriteDel1 = signalFlow1a : !,_,!,!,!,!,!,!,!,!;
            memWriteDel2 = signalFlow1a : !,!,_,!,!,!,!,!,!,!;
            memWriteLev = signalFlow1a : !,!,!,_,!,!,!,!,!,!;
            cntrlLev1 = signalFlow1a : !,!,!,!,_,!,!,!,!,!;
            cntrlLev2 = signalFlow1a : !,!,!,!,!,_,!,!,!,!;
            cntrlFeed = signalFlow1a : !,!,!,!,!,!,_,!,!,!;
            cntrlMain = signalFlow1a : !,!,!,!,!,!,!,_,!,!;
            mic3 = signalFlow1a : !,!,!,!,!,!,!,!,_,!;
            mic4 = signalFlow1a : !,!,!,!,!,!,!,!,!,_;


signalFlow1b(mic1, mic2, grainOut1, grainOut2, memWriteLev, cntrlMain) = 
cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3,
mic1, mic2
    with{   
        cntrlMic(x) = x : HP1(50) : LP1(6000) : integrator(.01) : delayfb(.01,.999) : LP4(.5);
        cntrlMic1 = mic1 : cntrlMic;
        cntrlMic2 = mic2 : cntrlMic;

        grainSUM = grainOut1 + grainOut2 : integrator(.01) : delayfb(.01,.97) : LP4(.5);
        map1minX05(x) = 1 - x * .5;
        directLevel = grainSUM <: _, delayfb(var1 * 2, (1 - var3) * 0.5) :> + : map1minX05;

        triangleWaveA = triangleWave( 1 / ( var1 * 2 ) ); 
        triangleWaveB = triangleWave( 1 / ( var1 * 6 ) );
        triangleWaveC = triangleWave( var1 * (1 - cntrlMain) );
        triangleWaveD = triangleWave( 1 / var1 );
        mapXmin2by05(x) = (x - 2) * 0.5;
        mapXplus1by05(x) = (x + 1) * 0.5;

        timeIndex1 = triangleWaveA : mapXmin2by05;
        timeIndex2 = triangleWaveA : mapXplus1by05;
        triangle1 = triangleWaveB * memWriteLev;
        triangle2 = triangleWaveC;
        triangle3 = triangleWaveD;
        };
        /*
        process = 
            ( noise(10), 
              noise(11), 
              noise(12), 
              noise(13), 
              abs(noise(13))*0.333, 
              abs(noise(13))*0.92 )
                :
                signalFlow1b;
                */
            cntrlMic1 = signalFlow1b : _,!,!,!,!,!,!,!,!,!;
            cntrlMic2 = signalFlow1b : !,_,!,!,!,!,!,!,!,!;
            directLevel = signalFlow1b : !,!,_,!,!,!,!,!,!,!;
            timeIndex1 = signalFlow1b : !,!,!,_,!,!,!,!,!,!;
            timeIndex2 = signalFlow1b : !,!,!,!,_,!,!,!,!,!;
            triangle1 = signalFlow1b : !,!,!,!,!,_,!,!,!,!;
            triangle2 = signalFlow1b : !,!,!,!,!,!,_,!,!,!;
            triangle3 = signalFlow1b : !,!,!,!,!,!,!,_,!,!;
            mic1 = signalFlow1b : !,!,!,!,!,!,!,!,_,!;
            mic2 = signalFlow1b : !,!,!,!,!,!,!,!,!,_;


signalFlow2a(mic1, mic2, cntrlMic1, cntrlMic2, directLevel, triangle1, triangle2, diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlFeed, cntrlMain) = 
sig1, sig2
    with{
        sigpre1 = mic1 : HP1(50) : LP1(6000) * (1 - cntrlMic1);
        sigpre2 = mic2 : HP1(50) : LP1(6000) * (1 - cntrlMic2);
        sig1 = sigpre1 * directLevel;
        sig2 = sigpre2 * directLevel;
        sig1SUM2 = (sigpre1 + sigpre2) * triangle1;

        };
        ///*
        process = 
            ( noise(20), 
              noise(21), 
              abs(noise(22))*0.350, 
              abs(noise(23))*0.350,
              abs(noise(24))*0.180, 
              triangleWave(10),
              triangleWave(0.2),
              .4+abs(noise(25))*0.11,
              .3+abs(noise(26))*0.21,
              .3+abs(noise(27))*0.22,
              .3+abs(noise(28))*0.23,
              1-abs(noise(29))*0.10,
              abs(noise(30))*0.1 )
                :
                signalFlow2a;
                //*/
                

//process = _<: signal_flow_2a(mic1, mic2, cntrlMic1, cntrlMic2, directLevel, triangle1, triangle2, diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlFeed, cntrlMain);
//process = noise(20) <: signalFlow1b( _@300, _@400, _@500, _@600, memWriteLev, cntrlMain);
