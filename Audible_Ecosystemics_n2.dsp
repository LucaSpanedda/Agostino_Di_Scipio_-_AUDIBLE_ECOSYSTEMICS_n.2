declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
import("ae2lib.lib");

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

//-----------------------signal flow 1b-----------------------
//Role of the signal flow block: generation of control signals based on mic1 and mic2 input, plus internal signal generators
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

//-----------------------signal flow 2a-----------------------
//Role of the signal flow block: signal processing of audio input from mic1 and mic2, and mixing of all audio signals
signalFlow2a(mic1, mic2, cntrlMic1, cntrlMic2, directLevel, triangle1, triangle2, diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlFeed, cntrlMain) =
sig1,sig2,sig3,sig4,sig5,sig6,sig7
    with{
        sigpre1 = mic1 : HP1(50) : LP1(6000) * (1 - cntrlMic1);
        sigpre2 = mic2 : HP1(50) : LP1(6000) * (1 - cntrlMic2);

        Samplereads = sig3, sig4, sig5, sig6, sig7
            with{
                
                sig1and2Sum = (sigpre1 + sigpre2); 

                    ratio1 = (var2+(diffHL*1000))/261;
                    memchunk1 = (1-memWriteDel2);
                    ratio2 = (var2+(diffHL*1000))/261;
                    memchunk2 = (1-memWriteDel2);
                    ratio3 = (var2+(diffHL*1000))/261;
                    memchunk3 = (1-memWriteDel2);
                    ratio4 = (var2+(diffHL*1000))/261;
                    memchunk4 = (1-memWriteDel2);
                    ratio5 = (var2+(diffHL*1000))/261;
                    memchunk5 = (1-memWriteDel2);

                sampleread1(x) = x : sampleread(var1, ratio1, memchunk1) 
                : HP4(50) : delayfb( (var1 / 2), 0);

                sampleread2(x) = x : sampleread(var1, ratio2, memchunk2) 
                : HP4(50) : delayfb( (var1), 0);

                sampleread3(x) = x : sampleread(var1, ratio3, memchunk3) : 
                HP4(50);
                    sampleread3A(y) = y : sampleread3 
                    : BPsvftpt(diffHL * 400, (var2 / 2) * memWriteDel2);
                    sampleread3B(y) = y : sampleread3 
                    : BPsvftpt( (1-diffHL) * 800, var2 * (1-memWriteDel1) );
                
                sampleread4(x) = x : sampleread(var1, ratio4, memchunk4) : 
                HP4(50) : delayfb(var1 / 3, 0);

                sampleread5(x) = x : sampleread(var1, ratio5, memchunk5) : 
                HP4(50) : delayfb(var1 / 2.5, 0);

                    ReadsLoop(x) = 
                    ( ( x : sampleread1 ), ( x : sampleread2 ),
                    ( x : sampleread3A ), ( x : sampleread3B ) 
                    :> + * (cntrlFeed * memWriteLev) ), 
                    ( x : sampleread3 ), ( x : sampleread4), ( x : sampleread5);

                    Mainloop = ( _ + sig1and2Sum : _* triangle1 : ReadsLoop) ~ _;

                Loop1 = (Mainloop : _,!,!,!);
                sig3pre = Loop1 * memWriteLev;
                sig3 = sig3pre : delayfb(.05 * cntrlMain, 0) * triangle2 * directLevel;
                sig4 = sig3pre * (1-triangle2) * directLevel;
                Loop2 = (Mainloop : !,_,!,!);
                sig7 = Loop2 :  delayfb(var1 / 1.5, 0) * directLevel;
                sig5 = (Mainloop : !,!,_,!);
                sig6 = (Mainloop : !,!,!,_);
                };
        
        sig1 = sigpre1 * directLevel;
        sig2 = sigpre2 * directLevel;
        sig3 = Samplereads : _,!,!,!,!;
        sig4 = Samplereads : !,_,!,!,!;
        sig5 = Samplereads : !,!,_,!,!;
        sig6 = Samplereads : !,!,!,_,!;
        sig7 = Samplereads : !,!,!,!,_;
        };
        /*
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
                */
                
//-----------------------signal flow 2b-----------------------
//Role of the signal flow block: signal processing of audio input from mic1 and mic2, and mixing of all audio signals
signalFlow2b(timeIndex1, timeIndex2, triangle3, graIN, sig1, sig2, sig3, sig4, sig5, sig6, sig7, 
memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2) =
out1, out2, grainOut1, grainOut2
    with{
        grainOut1 = granular_sampling(1,var1,timeIndex1,memWriteDel1,cntrlLev1,21, graIN);
        grainOut2 = granular_sampling(1,var1,timeIndex2,memWriteDel2,cntrlLev2,20, graIN);

        out1 = 
            ( sig5 : delayfb(.04, 0) * (1 - triangle3) ) + 
            ( sig5 * triangle3 ) +
            ( sig6 : delayfb(.036, 0) * (1 - triangle3) )  +
            ( sig6 : delayfb(.036, 0) * triangle3 ) +
            sig1 + sig2 + sig4 +
            grainOut1 * (1 - memWriteLev) + grainOut2 * memWriteLev; 

        out2 = 
            ( sig5 * (1 - triangle3) ) + 
            ( sig5 : delayfb(.040, 0) * triangle3 ) +
            ( sig6 * (1 - triangle3) ) +
            ( sig6 * triangle3 ) + 
            sig2 + sig3 + sig7 +
            grainOut1 * memWriteLev + grainOut2 * (1 - memWriteLev);
        };
        process = 
            ( (abs(noise(60)) -1) * .5, 
              (abs(noise(61)) -1) * .5,
              triangleWave( 1 / var1 ), 
              noise(62) * .1,
              noise(63) * .1, 
              noise(64) * .1,
              noise(65) * .1,
              noise(66) * .1,
              noise(67) * .1,
              noise(68) * .1,
              noise(69) * .1,
              abs(noise(70)),
              abs(noise(71)),
              abs(noise(72)),
              abs(noise(73)),
              abs(noise(74)) )
                :
                signalFlow2b;

//-----------------------signal flow 3-----------------------
//Role of the signal flow block: dispatching of audio signals to output channels
signalFlow3(out1, out2) = out1, out2, 
    ( out2 : delayfb(var4/2/344, 0) ),
    ( out1 : delayfb(var4/2/344, 0) ),
    ( out1 : delayfb(var4/344, 0) ),
    ( out2 : delayfb(var4/344, 0) );
    /*
    process = 
        noise(40),noise(41)  : signalFlow3;
        */
