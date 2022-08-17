declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
import("ae2lib.lib");


//-----------------------signal flow 1a-----------------------
//Role of the signal flow block: generation of control signals based on mic3 and mic4 input
signalFlow1a(mic3, mic4) = 
diffHL, 
memWriteDel1, 
memWriteDel2, 
memWriteLev, 
cntrlLev1, 
cntrlLev2, 
cntrlFeed, 
cntrlMain
    with{
        micSUM = mic3 + mic4;
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
            (micSUM : HP2(var2) : integrator(.05)) , 
                (micSUM : LP2(var2) : integrator(.10)) : 
                    \(x,y).(x-y) * (1 - SenstoExt) : 
                        delayfb(0.01,0.995) : LP4(25.0) : \(x).(.5 + x * .5) : 
                            max(0.0, min(1.0));
        memWriteLev = 
            micSUM : integrator(.1) : delayfb(.01,.9) : 
                LP4(25) : \(x).(1 - (x * x));
        memWriteDel1 = memWriteLev : delayfb(var1 / 2, 0);
        memWriteDel2 = memWriteLev : delayfb(var1 / 3, 0);
        cntrlMain = 
            micSUM * SenstoExt : integrator(.01) : 
                delayfb(.01,.995) : LP4(25);
        cntrlLev1 = cntrlMain : delayfb(var1 / 3, 0);
        cntrlLev2 = cntrlMain : delayfb(var1 / 2, 0);
        cntrlFeed = cntrlMain : \(x).(ba.if(x <= .5, 1.0, (1.0 - x) * 2.0));
    };
testSF1a = 
    ( _*.1 <: _, _@4000 ) 
        : signalFlow1a;
//process = testSF1a;

//-----------------------signal flow 1b-----------------------
//Role of the signal flow block: generation of control signals based on mic1 and mic2 input, plus internal signal generators
signalFlow1b(mic1, mic2, grainOut1, grainOut2, memWriteLev, cntrlMain) = 
cntrlMic1, 
cntrlMic2, 
directLevel, 
timeIndex1, 
timeIndex2, 
triangle1, 
triangle2, 
triangle3
    with{   
        grainSUM = grainOut1 + grainOut2;
        cntrlMic(x) = 
            x : HP1(50) : LP1(6000) : integrator(.01) : delayfb(.01,.999) : LP4(.5);
        cntrlMic1 = mic1 : cntrlMic;
        cntrlMic2 = mic2 : cntrlMic;
        directLevel = 
            grainSUM : integrator(.01) : delayfb(.01,.97) : LP4(.5) 
                <: _, delayfb(var1 * 2, (1 - var3) * 0.5) : +
                    : \(x).(1 - x * .5);
        timeIndex1 = triangleWave( 1 / (var1 * 2) ) : \(x).( (x - 2) * 0.5 );
        timeIndex2 = triangleWave( 1 / (var1 * 2) ) : \(x).( (x + 1) * 0.5 );
        triangle1 = triangleWave( 1 / (var1 * 6) ) * memWriteLev;
        triangle2 = triangleWave( var1 * (1 - cntrlMain) );
        triangle3 = triangleWave( 1 / var1 );
    };
testSF1b = 
    (_*.1 <: _, _@1000, _@2000, _@3000, 
        abs(os.osc(.12))*.9997, abs(os.osc(.14))*.0003) 
            : signalFlow1b;
//process = testSF1b;

//-----------------------signal flow 2a-----------------------
//Role of the signal flow block: signal processing of audio input from mic1 and mic2, and mixing of all audio signals
signalFlow2a(mic1, mic2, cntrlMic1, cntrlMic2, directLevel, triangle1, triangle2, diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlFeed, cntrlMain) = 
    signalFlow2a ~ _ : !,_,_,_,_,_,_,_
        with{
            signalFlow2a(fb) = 
                (
                    (mic1 : HP1(50) : LP1(6000) * (1 - cntrlMic1)),
                        (mic2 : HP1(50) : LP1(6000) * (1 - cntrlMic2)),
                            (sampler(ma.SR*var1, memchunk1, ratio1, fb) : 
                                HP4(50) : delayfb( var1/2, 0)), 
                            (sampler(ma.SR*var1, memchunk2, ratio2, fb) : 
                                HP4(50) : delayfb( var1, 0)), 
                                ( 
                                    sampler(ma.SR*var1, memchunk3, ratio3, fb) : HP4(50) 
                                            <: BPsvftpt(diffHL * 400, (var2 / 2) 
                                                * memWriteDel2), 
                                                BPsvftpt((1-diffHL) * 800, var2 
                                                    * (1-memWriteDel1)
                                ), 
                    delayfb(var1/1.5, 0) * directLevel
                    ),
                (sampler(ma.SR*var1, memchunk4, ratio4, fb) : 
                    HP4(50) : delayfb(var1 / 3, 0)),
                        (sampler(ma.SR*var1, memchunk5, ratio5, fb) : 
                            HP4(50) : delayfb(var1 / 2.5, 0))
                )
            : _,_,( (_,_,_,_ :> +) * (cntrlFeed * memWriteLev) ), _,_,_ 
                : \(micSect1,micSect2,Sumreads123,sig7,sig5,sig6).
                    ( ( (micSect1,micSect2,Sumreads123) :> _ )* triangle1, 
                        micSect1 * directLevel, micSect2 * directLevel, 
                            ( (Sumreads123 * memWriteLev 
                                : delayfb(.05 * cntrlMain, 0) ) 
                                    * triangle2 ) * directLevel, 
                                        ( (Sumreads123 * memWriteLev) 
                                            * (1-triangle2) ) * directLevel, 
                                                sig5,sig6,sig7)
                with{
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
                };
        };
testSF2a = 
    ( (_*100 <: _, _@4000), 
        abs(noise(10))*.05, abs(noise(11))*.05, abs(noise(12))*.97,
            triangleWave( 1 / (var1 * 6) )*.05, 
                triangleWave( var1 * (1 - .1) ),
                    abs(noise(13))*.42, abs(noise(14))*.99, 
                        abs(noise(15))*.99, abs(noise(16))*.99,
                            1, 
                                abs(noise(13))*.0001 )
                                    : signalFlow2a : \(A,B,C,D,E,F,G).(A,B);
                                        //(C+E, D+F+G);
process = testSF2a;
    
//-----------------------signal flow 2b-----------------------
//Role of the signal flow block: signal processing of audio input from mic1 and mic2, and mixing of all audio signals
signalFlow2b(timeIndex1, timeIndex2, triangle3, graIN, sig1, sig2, sig3, sig4, sig5, sig6, sig7, 
memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2) =
out1, 
out2, 
grainOut1, 
grainOut2
    with{
        grainOut1 = granular_sampling(1,var1,timeIndex1,memWriteDel1,cntrlLev1,21,graIN);
        grainOut2 = granular_sampling(1,var1,timeIndex2,memWriteDel2,cntrlLev2,20,graIN);
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
    };
testSF2b = 
    ( (abs(noise(60)) -1) * .5, (abs(noise(61)) -1) * .5,
    triangleWave( 1 / var1 ), 
    noise(62) * .1, noise(63) * .1, noise(64) * .1, noise(65) * .1,
    noise(66) * .1, noise(67) * .1, noise(68) * .1, noise(69) * .1,
    abs(noise(70)), abs(noise(71)), abs(noise(72)),
    abs(noise(73)), abs(noise(74)) )
        : signalFlow2b;
//process = testSF2b;

//-----------------------signal flow 3-----------------------
//Role of the signal flow block: dispatching of audio signals to output channels
signalFlow3(out1, out2) = 
    out1, 
        out2, 
            (out2 : delayfb(var4/2/344, 0)),
                (out1 : delayfb(var4/2/344, 0)),
                    (out1 : delayfb(var4/344, 0)),
                        (out2 : delayfb(var4/344, 0));
testSF3 = 
    noise(40),noise(41)  
        : signalFlow3;
//process = testSF3
