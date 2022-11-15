declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
declare author "Luca Spanedda";
declare version "alpha";
declare description " 2022 version - Realised on composer's instructions
of the year 2017 edited in L’Aquila, Italy";


// import faust standard library
import("stdfaust.lib");


//-------  -------------   -----  -----------
//-- AE2 -----------------------------------------------------------------------
//-------  --------

// Variables that are to be initialized prior to performance
var1 = 1;
var2 = 2000;
var3 = .2;
var4 = 1;
tabInt = 1; // tables interpolation order (Lagrange)
grainsPAR = 8; // parallel granulator Instances (for 2 granulators)
/*
var1 =  distance (in meters) between the two farthest removed loudspeakers 
        on the left-right axis.
var2 =  rough estimate of the center frequency in the spectrum of the room’s 
        background noise (spectral centroid): to evaluate at rehearsal time, 
        in a situation of "silence".
var3 =  subjective estimate of how the room revereberance, 
        valued between 0 ("no reverb") and 1 (“very long reverb”).
var4 =  distance (in meters) between the two farthest removed loudspeakers 
        on the front-rear axis.
*/

// Digital Mixer
Mic1G = ( hslider("Mic 1", 1,0,1,.001) : si.smoo );
Mic2G = ( hslider("Mic 2", 1,0,1,.001) : si.smoo );
Mic3G = ( hslider("Mic 3", 1,0,1,.001) : si.smoo );
Mic4G = ( hslider("Mic 4", 1,0,1,.001) : si.smoo );

// Audible Ecosystemics 2
process =  _,_@(ma.SR/4) :
                \(M1,M2).( M1 * Mic1G, M2 * Mic2G, M1 * Mic3G, M2 * Mic4G ) :
                                        (
                                          signalflow1a
                                        : signalflow1b
                                        : signalflow2a
                                        : signalflow2b
                                        :  signalflow3
                                                        ) ~ si.bus(2) :

                                                            // AE2 outs

                                                            si.block(2),
                                                            si.bus(2),
                                                            si.block(28);


                                                            // Granulator outs
                                                            /*
                                                            si.bus(2),
                                                            si.block(30);
                                                            */

                                                            // Direct Mics outs
                                                            /*
                                                            si.block(4),
                                                            _,_,_,_,
                                                            si.block(24);
                                                            */

                                                            // sf1a
                                                            /*
                                                            si.block(8),
                                                            si.bus(8),
                                                            si.block(16);
                                                            */

                                                            // sf1b
                                                            /*
                                                            si.block(16),
                                                            si.bus(8),
                                                            si.block(8);
                                                            */

                                                            // sf2a
                                                            /*
                                                            si.block(24),
                                                            si.bus(8);
                                                            */
//
signalflow1a( grainOut1, grainOut2, mic1, mic2, mic3, mic4 ) =
                            grainOut1, grainOut2, mic1, mic2, mic3, mic4,
                            diffHL, memWriteDel1, memWriteDel2, memWriteLev,
                            cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain
    with{
        outFromSixPlusSixTimesX =
            (mic3 : integrator(.01) : delayfb(.01,.95)) +
                (mic4 : integrator(.01) : delayfb(.01,.95)) :
                    limit(1,0) : \(x).(6 + x * 6);
        localMaxDiff =
            ((outFromSixPlusSixTimesX, mic3) : localmax) ,
                ((outFromSixPlusSixTimesX, mic4) : localmax) :
                    \(x,y).(x-y);
        SenstoExt =
            (outFromSixPlusSixTimesX, localMaxDiff) : localmax
                <: _ , @(ba.sec2samp(12)) : + : * (.5) : LPButterworthN(1, .5);
        diffHL =
            ((mic3 + mic4) : HPButterworthN(3, var2) : integrator(.05)) ,
                ((mic3 + mic4) : LPButterworthN(3, var2) : integrator(.10)) :
                    \(x,y).(x-y) * (1 - SenstoExt) :
                        delayfb(0.01,0.995) : LPButterworthN(5, 25.0) : 
                        \(x).(.5 + x * .5) : limit(1,0);
        memWriteLev =
            (mic3 + mic4) : integrator(.1) : delayfb(.01,.9) :
                LPButterworthN(5, 25) : \(x).(1 - (x * x)) : limit(1,0);
        memWriteDel1 = memWriteLev : @(ba.sec2samp(var1 / 2));
        memWriteDel2 = memWriteLev : @(ba.sec2samp(var1 / 3));
        cntrlMain =
            (mic3 + mic4) * SenstoExt : integrator(.01) :
                delayfb(.01,.995) : LPButterworthN(5, 25) : limit(1,0);
        cntrlLev1 = cntrlMain : @(ba.sec2samp(var1 / 3));
        cntrlLev2 = cntrlMain : @(ba.sec2samp(var1 / 2));
        cntrlFeed = cntrlMain : \(x).(ba.if(x <= .5, 1.0, (1.0 - x) * 2.0));
    };
//
signalflow1b(
                grainOut1, grainOut2,
                mic1, mic2, mic3, mic4,
                diffHL, memWriteDel1, memWriteDel2, memWriteLev,
                cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain
                    ) =
                        mic1, mic2, mic3, mic4,
                        diffHL, memWriteDel1, memWriteDel2, memWriteLev,
                        cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
                        cntrlMic1, cntrlMic2, directLevel, timeIndex1,
                        timeIndex2, triangle1, triangle2, triangle3
    with{
        cntrlMic(x) =
            x : HPButterworthN(1, 50) : LPButterworthN(1, 6000) : 
                integrator(.01) : delayfb(.01,.9) : LPButterworthN(5, .5) : 
                limit(1,0);
                // delayfb(.01,.999) too much: block .9 better
        cntrlMic1 = mic1 : cntrlMic;
        cntrlMic2 = mic2 : cntrlMic;
        directLevel =
              (grainOut1+grainOut2) : integrator(.01) : delayfb(.01,.97) : 
              LPButterworthN(5, .5)
                <: _, delayfb(var1 * 2, (1 - var3) * 0.5) : +
                    : \(x).(1 - x * .5) : limit(1,0);
        timeIndex1 = triangleWave( 1 / (var1 * 2) ) : \(x).( (x - 2) * 0.5 );
        timeIndex2 = triangleWave( 1 / (var1 * 2) ) : \(x).( (x + 1) * 0.5 );
        triangle1 = triangleWave( 1 / (var1 * 6) ) * memWriteLev;
        triangle2 = triangleWave( var1 * (1 - cntrlMain) );
        triangle3 = triangleWave( 1 / var1 );
    };
//
signalflow2a(
                mic1, mic2, mic3, mic4,
                diffHL, memWriteDel1, memWriteDel2, memWriteLev,
                cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
                cntrlMic1, cntrlMic2, directLevel, timeIndex1,
                timeIndex2, triangle1, triangle2, triangle3
                    ) =
                        mic1, mic2, mic3, mic4,
                        diffHL, memWriteDel1, memWriteDel2, memWriteLev,
                        cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
                        cntrlMic1, cntrlMic2, directLevel, timeIndex1,
                        timeIndex2, triangle1, triangle2, triangle3,
                        sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7
    with{
        micIN1 =  mic1 : HPButterworthN(1, 50) : 
                  LPButterworthN(1, 6000) * (1 - cntrlMic1);
        micIN2 =  mic2 : HPButterworthN(1, 50) : 
                  LPButterworthN(1, 6000) * (1 - cntrlMic2);
        SRSect1(x) = x : sampler( var1,
                                 (1 - memWriteDel2),
                                 (var2 + (diffHL * 1000))/261
                                ) : HPButterworthN(4, 50) : 
                                  @(ba.sec2samp(var1/2));
        SRSect2(x) = x : sampler( var1,
                                  (memWriteLev + memWriteDel1)/2,
                                  ( 290 - (diffHL * 90))/261
                                ) : HPButterworthN(4, 50) : 
                                  @(ba.sec2samp(var1));
        SRSect3(x) = x : sampler( var1, (1 - memWriteDel1),
                                  ((var2 * 2) - (diffHL * 1000))/261
                                ) : HPButterworthN(4, 50);
            SRSectBP1(x) = x : SRSect3 : BPsvftpt( diffHL
                                                   * 400 : limit(1,20000),
                                                   (var2 / 2) * memWriteDel2
                                                   : limit(1,20000) );
            SRSectBP2(x) = x : SRSect3 : BPsvftpt( (1 - diffHL)
                                                    * 800 : limit(1,20000),
                                                    var2 * (1 - memWriteDel1)
                                                    : limit(1,20000) );
        SRSect4(x) = x : sampler(var1, 1, (250 + (diffHL * 20))/261);
        SRSect5(x) = x : sampler(var1, memWriteLev, .766283);
        fbG = 1; // normalization for SampleWriteLoop Feedback
        SampleWriteLoop = loop ~ _ * fbG
            with{
                loop(fb) =
                (
                    ( SRSect1(fb),
                    SRSect2(fb),
                    SRSectBP1(fb),
                    SRSectBP2(fb) :> + ) * (cntrlFeed * memWriteLev)
                )   <:
                        ( _ + (micIN1+micIN2) : _ * triangle1 ),
                          _,
                          SRSect4(fb),
                          SRSect5(fb),
                          SRSect3(fb);
            };
        sig1 = micIN1 * directLevel;
        sig2 = micIN2 * directLevel;
        sampWOut = SampleWriteLoop : \(A,B,C,D,E).(A);
        sig3 = SampleWriteLoop : \(A,B,C,D,E).(B) :
                                                  _ * memWriteLev :
                                                  delayfb(.05 * cntrlMain, 0)
                                                  * triangle2 * directLevel;
        sig4 = SampleWriteLoop : \(A,B,C,D,E).(B) :
                                                  _ * memWriteLev
                                                  * (1-triangle2) * directLevel;
        sig5 = SampleWriteLoop : \(A,B,C,D,E).(C) :
                                                  HPButterworthN(4, 50) :
                                                  @(ba.sec2samp(var1 / 3));
        sig6 = SampleWriteLoop : \(A,B,C,D,E).(D) :
                                                  HPButterworthN(4, 50) :
                                                  @(ba.sec2samp(var1 / 2.5));
        sig7 = SampleWriteLoop : \(A,B,C,D,E).(E) :
                                                  @(ba.sec2samp(var1 / 1.5))
                                                  * directLevel;
    };
//
signalflow2b(
                mic1, mic2, mic3, mic4,
                diffHL, memWriteDel1, memWriteDel2, memWriteLev,
                cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
                cntrlMic1, cntrlMic2, directLevel, timeIndex1,
                timeIndex2, triangle1, triangle2, triangle3,
                sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7
                    ) =
                        mic1, mic2, mic3, mic4,
                        diffHL, memWriteDel1, memWriteDel2, memWriteLev,
                        cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
                        cntrlMic1, cntrlMic2, directLevel, timeIndex1,
                        timeIndex2, triangle1, triangle2, triangle3,
                        sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7,
                        grainOut1, grainOut2, out1, out2
    with{
        grainOut1 = sampWOut <:
                        granular_sampling(  grainsPAR,var1,timeIndex1,
                                            memWriteDel1,cntrlLev1,21  );
        grainOut2 = sampWOut <:
                        granular_sampling(  grainsPAR,var1,timeIndex2,
                                            memWriteDel2,cntrlLev2,20  );
        out1 =
                (
                          ( sig5 : @(ba.sec2samp(.04)) * (1 - triangle3) ),
                                                      ( sig5 * triangle3 ),
                         ( sig6 : @(ba.sec2samp(.036)) * (1 - triangle3) ),
                               ( sig6 : @(ba.sec2samp(.036)) * triangle3 ),
                                                                      sig1,
                                                                      sig2,
                                                                      sig4,
                    grainOut1 * (1 - memWriteLev) + grainOut2 * memWriteLev
                ) :> +;
        out2 =
                (
                                                ( sig5 * (1 - triangle3) ),
                               ( sig5 : @(ba.sec2samp(.040)) * triangle3 ),
                                                ( sig6 * (1 - triangle3) ),
                                                      ( sig6 * triangle3 ),
                                                                      sig2,
                                                                      sig3,
                                                                      sig7,
                    grainOut1 * memWriteLev + grainOut2 * (1 - memWriteLev)
                ) :> +;
    };
//
signalflow3 (
                mic1, mic2, mic3, mic4,
                diffHL, memWriteDel1, memWriteDel2, memWriteLev,
                cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
                cntrlMic1, cntrlMic2, directLevel, timeIndex1,
                timeIndex2, triangle1, triangle2, triangle3,
                sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7,
                grainOut1, grainOut2, out1, out2
                    ) =
                        grainOut1,
                        grainOut2,
                        out1,
                        out2,
                        mic1, mic2, mic3, mic4,
                        diffHL, memWriteDel1, memWriteDel2, memWriteLev,
                        cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
                        cntrlMic1, cntrlMic2, directLevel, timeIndex1,
                        timeIndex2, triangle1, triangle2, triangle3,
                        sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7;


//-------  -------------   -----  -----------
//-- LIBRARY -------------------------------------------------------------------
//-------  --------

//----------------------------------------------------------------- CONSTANTS --
// var 4 and 1 max comparation (max in out)
varMax = max(var1,var4);

// Prime Numbers List
primes =
(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73,
79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163,
167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251,
257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439, 443,
449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521, 523, 541, 547, 557,
563, 569, 571, 577, 587, 593, 599, 601, 607, 613, 617, 619, 631, 641, 643, 647,
653, 659, 661, 673, 677, 683, 691, 701, 709, 719, 727, 733, 739, 743, 751, 757,
761, 769, 773, 787, 797, 809, 811, 821, 823, 827, 829, 839, 853, 857, 859, 863,
877, 881, 883, 887, 907, 911, 919, 929, 937, 941, 947, 953, 967, 971, 977, 983,
991, 997, 1009, 1013, 1019, 1021, 1031, 1033, 1039, 1049, 1051, 1061, 1063,
1069, 1087, 1091, 1093, 1097, 1103, 1109, 1117, 1123, 1129, 1151, 1153, 1163,
1171, 1181, 1187, 1193, 1201, 1213, 1217, 1223, 1229, 1231, 1237, 1249, 1259,
1277, 1279, 1283, 1289, 1291, 1297, 1301, 1303, 1307, 1319, 1321, 1327, 1361,
1367, 1373, 1381, 1399, 1409, 1423, 1427, 1429, 1433, 1439, 1447, 1451, 1453,
1459, 1471, 1481, 1483, 1487, 1489, 1493, 1499, 1511, 1523, 1531, 1543, 1549,
1553, 1559, 1567, 1571, 1579, 1583, 1597, 1601, 1607, 1609, 1613, 1619, 1621,
1627, 1637, 1657, 1663, 1667, 1669, 1693, 1697, 1699, 1709, 1721, 1723, 1733,
1741, 1747, 1753, 1759, 1777, 1783, 1787, 1789, 1801, 1811, 1823, 1831, 1847,
1861, 1867, 1871, 1873, 1877, 1879, 1889, 1901, 1907, 1913, 1931, 1933, 1949,
1951, 1973, 1979, 1987, 1993, 1997, 1999, 2003, 2011, 2017, 2027, 2029, 2039,
2053, 2063, 2069, 2081, 2083, 2087, 2089, 2099, 2111, 2113, 2129, 2131, 2137,
2141, 2143, 2153, 2161, 2179, 2203, 2207, 2213, 2221, 2237, 2239, 2243, 2251,
2267, 2269, 2273, 2281, 2287, 2293, 2297, 2309, 2311, 2333, 2339, 2341, 2347,
2351, 2357, 2371, 2377, 2381, 2383, 2389, 2393, 2399, 2411, 2417, 2423, 2437,
2441, 2447, 2459, 2467, 2473, 2477, 2503, 2521, 2531, 2539, 2543, 2549, 2551,
2557, 2579, 2591, 2593, 2609, 2617, 2621, 2633, 2647, 2657, 2659, 2663, 2671,
2677, 2683, 2687, 2689, 2693, 2699, 2707, 2711, 2713, 2719, 2729, 2731, 2741,
2749, 2753, 2767, 2777, 2789, 2791, 2797, 2801, 2803, 2819, 2833, 2837, 2843,
2851, 2857, 2861, 2879, 2887, 2897, 2903, 2909, 2917, 2927, 2939, 2953, 2957,
2963, 2969, 2971, 2999, 3001, 3011, 3019, 3023, 3037, 3041, 3049, 3061, 3067,
3079, 3083, 3089, 3109, 3119, 3121, 3137, 3163, 3167, 3169, 3181, 3187, 3191,
3203, 3209, 3217, 3221, 3229, 3251, 3253, 3257, 3259, 3271, 3299, 3301, 3307,
3313, 3319, 3323, 3329, 3331, 3343, 3347, 3359, 3361, 3371, 3373, 3389, 3391,
3407, 3413, 3433, 3449, 3457, 3461, 3463, 3467, 3469, 3491, 3499, 3511, 3517,
3527, 3529, 3533, 3539, 3541, 3547, 3557, 3559, 3571, 3581, 3583, 3593, 3607,
3613, 3617, 3623, 3631, 3637, 3643, 3659, 3671, 3673, 3677, 3691, 3697, 3701,
3709, 3719, 3727, 3733, 3739, 3761, 3767, 3769, 3779, 3793, 3797, 3803, 3821,
3823, 3833, 3847, 3851, 3853, 3863, 3877, 3881, 3889, 3907, 3911, 3917, 3919,
3923, 3929, 3931, 3943, 3947, 3967, 3989, 4001, 4003, 4007, 4013, 4019, 4021,
4027, 4049, 4051, 4057, 4073, 4079, 4091, 4093, 4099, 4111, 4127, 4129, 4133,
4139, 4153, 4157, 4159, 4177, 4201, 4211, 4217, 4219, 4229, 4231, 4241, 4243,
4253, 4259, 4261, 4271, 4273, 4283, 4289, 4297, 4327, 4337, 4339, 4349, 4357,
4363, 4373, 4391, 4397, 4409, 4421, 4423, 4441, 4447, 4451, 4457, 4463, 4481,
4483, 4493, 4507, 4513, 4517, 4519, 4523, 4547, 4549, 4561, 4567, 4583, 4591,
4597, 4603, 4621, 4637, 4639, 4643, 4649, 4651, 4657, 4663, 4673, 4679, 4691,
4703, 4721, 4723, 4729, 4733, 4751, 4759, 4783, 4787, 4789, 4793, 4799, 4801,
4813, 4817, 4831, 4861, 4871, 4877, 4889, 4903, 4909, 4919, 4931, 4933, 4937,
4943, 4951, 4957, 4967, 4969, 4973, 4987, 4993, 4999, 5003, 5009, 5011, 5021,
5023, 5039, 5051, 5059, 5077, 5081, 5087, 5099, 5101, 5107, 5113, 5119, 5147,
5153, 5167, 5171, 5179, 5189, 5197, 5209, 5227, 5231, 5233, 5237, 5261, 5273,
5279, 5281, 5297, 5303, 5309, 5323, 5333, 5347, 5351, 5381, 5387, 5393, 5399,
5407, 5413, 5417, 5419, 5431, 5437, 5441, 5443, 5449, 5471, 5477, 5479, 5483,
5501, 5503, 5507, 5519, 5521, 5527, 5531, 5557, 5563, 5569, 5573, 5581, 5591,
5623, 5639, 5641, 5647, 5651, 5653, 5657, 5659, 5669, 5683, 5689, 5693, 5701,
5711, 5717, 5737, 5741, 5743, 5749, 5779, 5783, 5791, 5801, 5807, 5813, 5821,
5827, 5839, 5843, 5849, 5851, 5857, 5861, 5867, 5869, 5879, 5881, 5897, 5903,
5923, 5927, 5939, 5953, 5981, 5987, 6007, 6011, 6029, 6037, 6043, 6047, 6053,
6067, 6073, 6079, 6089, 6091, 6101, 6113, 6121, 6131, 6133, 6143, 6151, 6163,
6173, 6197, 6199, 6203, 6211, 6217, 6221, 6229, 6247, 6257, 6263, 6269, 6271,
6277, 6287, 6299, 6301, 6311, 6317, 6323, 6329, 6337, 6343, 6353, 6359, 6361,
6367, 6373, 6379, 6389, 6397, 6421, 6427, 6449, 6451, 6469, 6473, 6481, 6491,
6521, 6529, 6547, 6551, 6553, 6563, 6569, 6571, 6577, 6581, 6599, 6607, 6619,
6637, 6653, 6659, 6661, 6673, 6679, 6689, 6691, 6701, 6703, 6709, 6719, 6733,
6737, 6761, 6763, 6779, 6781, 6791, 6793, 6803, 6823, 6827, 6829, 6833, 6841,
6857, 6863, 6869, 6871, 6883, 6899, 6907, 6911, 6917, 6947, 6949, 6959, 6961,
6967, 6971, 6977, 6983, 6991, 6997, 7001, 7013, 7019, 7027, 7039, 7043, 7057,
7069, 7079, 7103, 7109, 7121, 7127, 7129, 7151, 7159, 7177, 7187, 7193, 7207,
7211, 7213, 7219, 7229, 7237, 7243, 7247, 7253, 7283, 7297, 7307, 7309, 7321,
7331, 7333, 7349, 7351, 7369, 7393, 7411, 7417, 7433, 7451, 7457, 7459, 7477,
7481, 7487, 7489, 7499, 7507, 7517, 7523, 7529, 7537, 7541, 7547, 7549, 7559,
7561, 7573, 7577, 7583, 7589, 7591, 7603, 7607, 7621, 7639, 7643, 7649, 7669,
7673, 7681, 7687, 7691, 7699, 7703, 7717, 7723, 7727, 7741, 7753, 7757, 7759,
7789, 7793, 7817, 7823, 7829, 7841, 7853, 7867, 7873, 7877, 7879, 7883, 7901,
7907, 7919, 7927, 7933, 7937, 7949, 7951, 7963, 7993, 8009, 8011, 8017, 8039,
8053, 8059, 8069, 8081, 8087, 8089, 8093, 8101, 8111, 8117, 8123, 8147, 8161,
8167, 8171, 8179, 8191, 8209, 8219, 8221, 8231, 8233, 8237, 8243, 8263, 8269,
8273, 8287, 8291, 8293, 8297, 8311, 8317, 8329, 8353, 8363, 8369, 8377, 8387,
8389, 8419, 8423, 8429, 8431, 8443, 8447, 8461, 8467, 8501, 8513, 8521, 8527,
8537, 8539, 8543, 8563, 8573, 8581, 8597, 8599, 8609, 8623, 8627, 8629, 8641,
8647, 8663, 8669, 8677, 8681, 8689, 8693, 8699, 8707, 8713, 8719, 8731, 8737,
8741, 8747, 8753, 8761, 8779, 8783, 8803, 8807, 8819, 8821, 8831, 8837, 8839,
8849, 8861, 8863, 8867, 8887, 8893, 8923, 8929, 8933, 8941, 8951, 8963, 8969,
8971, 8999, 9001, 9007, 9011, 9013, 9029, 9041, 9043, 9049, 9059, 9067, 9091,
9103, 9109, 9127, 9133, 9137, 9151, 9157, 9161, 9173, 9181, 9187, 9199, 9203,
9209, 9221, 9227, 9239, 9241, 9257, 9277, 9281, 9283, 9293, 9311, 9319, 9323,
9337, 9341, 9343, 9349, 9371, 9377, 9391, 9397, 9403, 9413, 9419, 9421, 9431,
9433, 9437, 9439, 9461, 9463, 9467, 9473, 9479, 9491, 9497, 9511, 9521, 9533,
9539, 9547, 9551, 9587, 9601, 9613, 9619, 9623, 9629, 9631, 9643, 9649, 9661,
9677, 9679, 9689, 9697, 9719, 9721, 9733, 9739, 9743, 9749, 9767, 9769, 9781,
9787, 9791, 9803, 9811, 9817, 9829, 9833, 9839, 9851, 9857, 9859, 9871, 9883,
9887, 9901, 9907, 9923, 9929, 9931, 9941, 9949, 9967, 9973, 10007, 10009, 10037,
10039, 10061, 10067, 10069, 10079, 10091, 10093, 10099, 10103, 10111, 10133,
10139, 10141, 10151, 10159, 10163, 10169, 10177, 10181, 10193, 10211, 10223,
10243, 10247, 10253, 10259, 10267, 10271, 10273, 10289, 10301, 10303, 10313,
10321, 10331, 10333, 10337, 10343, 10357, 10369, 10391, 10399, 10427, 10429,
10433, 10453, 10457, 10459, 10463, 10477, 10487, 10499, 10501, 10513, 10529,
10531, 10559, 10567, 10589, 10597, 10601, 10607, 10613, 10627, 10631, 10639,
10651, 10657, 10663, 10667);

// index of the primes numbers
primeNumbers(index) = ba.take(index , list)
  with{
    list = primes;
};

// limit function
limit(maxl,minl,x) = x : max(minl, min(maxl));

//---------------------------------------------------------------- SAMPLEREAD --
/*
sampler(memSeconds, memChunk, ratio, x) =
it.frwtable(tabInt, 192000 * (var1), .0, ba.period(memSeconds * ma.SR), x, rIdx)
    with {
        readingLength = si.smoo(memChunk : limit(1,.001)) * memSeconds * ma.SR;
        readingRate = ma.SR / readingLength;
        rIdx = os.phasor(readingLength, readingRate * si.smoo(ratio));
    };
*/
sampler(memBuffer, maxChunk, ratio, x) =
it.frwtable(  tabInt, 192000 * (memBuffer), .0, 
              ba.period(memBuffer * ma.SR), x, rIdx )
    with {
    //clip the smallest chunk
    memChunk(maxChunk) = (maxChunk  : max(0.001, min(1))) * memBuffer * ma.SR;
    rIdx =  os.phasor(memChunk(maxChunk), 
            (ma.SR / memChunk  (maxChunk)) * ratio);
    };

//-------------------------------------------------------------------- DELAY ---
// FB delay line - w min and max
delayfb(del,fb) = (+ : de.delay(varMax * 2, ba.sec2samp(del) ))~ _ * (fb);

//--------------------------------------------------------------- INTEGRATOR ---
// returns the average absolute value over a specific time frame
// (one may use RMS measures, instead, or other amplitude-following methods);
// output range is [0, 1]
movingAverage(seconds, x) = x - (x @ N) : fi.pole(1.0) / N
    with {
        N = seconds * ma.SR;
    };

RMSRectangular(seconds, x) = sqrt(max(0, movingAverage(seconds, x * x)));

integrator(seconds, x) = RMSRectangular(seconds, x);

//----------------------------------------------------------------- LOCALMAX ---
// returns the maximum signal amplitude (absolute value) in a given time frame;
// frame duration is dynamically adjusted: the next frame duration is set at the
// end of the previous frame
/*
peakHolder(secondsPeriod, x) = y
    letrec {
        'y = ba.if(reset, abs(x), max(y, abs(x)));
    }
        with {
            reset = os.phasor(1, 1.0 / secondsPeriod) : \(x).(x < x');
        };
*/
// holdTime in Seconds
peakHolder(holdTime, x) = loop ~ si.bus(2) : ! , _
    with {
        loop(timerState, outState) = timer , output
            with {
                isNewPeak = abs(x) >= outState;
                isTimeOut = timerState >= (holdTime * ma.SR - 1);
                bypass = isNewPeak | isTimeOut;
                timer = ba.if(bypass, 0, timerState + 1);
                output = ba.if(bypass, abs(x), outState);
            };
    };
localmax(resetPeriod, x) = peakHolder(resetPeriod, x);

//----------------------------------------------------------------- TRIANGLE ---
triangularFunc(x) = abs(ma.frac((x - .5)) * 2.0 - 1.0);
triangleWave(f) = triangularFunc(os.phasor(1,f));

//------------------------------------------------------------------ FILTERS ---
// TPT version of the One Pole and SVF Filter by Vadim Zavalishin
// reference : (by Will Pirkle)
// http://www.willpirkle.com/Downloads/AN-4VirtualAnalogFilters.2.0.pdf

// OnePoleTPT filter function
onePoleTPT(cf, x) = loop ~ _ : ! , si.bus(3)
    with {
        g = tan(cf * ma.PI * (1/ma.SR));
        G = g / (1.0 + g);
        loop(s) = u , lp , hp , ap
            with {
                v = (x - s) * G;
                u = v + lp;
                lp = v + s;
                hp = x - lp;
                ap = lp - hp;
            };
    };
LPTPT(cf, x) = onePoleTPT(cf, x) : (_ , ! , !);
HPTPT(cf, x) = onePoleTPT(cf, x) : (! , _ , !);

// SVFTPT filter function
SVFTPT(K, Q, CF, x) = circuitout : !,!,_,_,_,_,_,_,_,_
    with{
        g = tan(CF * ma.PI / ma.SR);
        R = 1.0 / (2.0 * Q);
        G1 = 1.0 / (1.0 + 2.0 * R * g + g * g);
        G2 = 2.0 * R + g;

        circuit(s1, s2) = u1 , u2 , lp , hp , bp, notch, apf, ubp, peak, bshelf
            with{
                hp = (x - s1 * G2 - s2) * G1;
                v1 = hp * g;
                bp = s1 + v1;
                v2 = bp * g;
                lp = s2 + v2;
                u1 = v1 + bp;
                u2 = v2 + lp;
                notch = x - ((2*R)*bp);
                apf = x - ((4*R)*bp);
                ubp = ((2*R)*bp);
                peak = lp -hp;
                bshelf = x + (((2*K)*R)*bp);
            };
    // choose the output from the SVF Filter (ex. bshelf)
    circuitout = circuit ~ si.bus(2);
    };
// Outs = (lp , hp , bp, notch, apf, ubp, peak, bshelf)
// SVFTPT(K, Q, CF, x) = (Filter-K, Filter-Q, Frequency Cut)

// Filters Bank
LPSVF(Q, CF, x) =   SVFTPT(0, Q, CF, x) : _,!,!,!,!,!,!,!;
HPSVF(Q, CF, x) =   SVFTPT(0, Q, CF, x) : !,_,!,!,!,!,!,!;
BPsvftpt(BW, CF, x) = SVFTPT(0 : ba.db2linear, Q, CF, x )   : !,!,_,!,!,!,!,!
    with{
        Q = CF / BW;
        };

// Butterworth
butterworthQ(order, stage) = qFactor(order % 2)
    with {
        qFactor(0) = 1.0 / (2.0 * cos(((2.0 * stage + 1) *
        (ma.PI / (order * 2.0)))));
        qFactor(1) = 1.0 / (2.0 * cos(((stage + 1) * (ma.PI / order))));
    };

LPButterworthN(1, cf, x) = LPTPT(cf, x);
LPButterworthN(N, cf, x) = cascade(N % 2)
    with {
        cascade(0) = x : seq(i, N / 2, LPSVF(butterworthQ(N, i), cf));
        cascade(1) = x : LPTPT(cf) : seq(i, (N - 1) / 2,
        LPSVF(butterworthQ(N, i), cf));
    };

HPButterworthN(1, cf, x) = HPTPT(cf, x);
HPButterworthN(N, cf, x) = cascade(N % 2)
    with {
        cascade(0) = x : seq(i, N / 2, HPSVF(butterworthQ(N, i), cf));
        cascade(1) = x : HPTPT(cf) : seq(i, (N - 1) /
        2, HPSVF(butterworthQ(N, i), cf));
    };

//------------------------------------------------------------------------ NOISE
// noise generated with prime numbers and index
noise(seed) = (+(primeNumbers(seed + 1)) ~ *(1103515245)) / 2147483647;

//-------------------------------------------------------- GRANULAR SAMPLING ---
/*
read sample sequences off subsequent buffer memory chunks, and envelopes the
signal chunk with a pseudo-Gaussian envelope curve; the particular
implementation should allow for time-stretching (slower memory pointer
increments at grain level), as well as for "grain density" controls and
slight random deviations ("jitter") on grain parameters; no frequency shift
necessary
Granular Sampling -
version with - Overlap Add To One - Granulator
for:
Agostino Di Scipio - AUDIBLE ECOSYSTEMICS
n.2a / Feedback Study (2003)
n.2b / Feedback Study, sound installation (2004).
- mem.pointer is the pointer to the next location in the memory
    buffer; in the present notation, it varies between -1 (beginning
    of buffer) and 1 (end of buffer)
- mem.pointer : timeIndex1 - a signal between -1 and -0.5
- mem.pointer.jitter is a random deviation of the current
    mem.pointer value; any viable method can be used to
    calculate the current actual value of mem.pointer
- mem.pointer.jitter: (1 - memWriteDel1) / 100
- memWriteDel1 = a signal between 0 and 1
- grain.duration: 0.023 + ((1 - memWriteDel1) / 21) s
- grain.dur.jitter is a random deviation of the current
    grain.duration value: the current actual grain duration =
    grain.duration + (rnd ⋅ grain.dur.jitter(0.1) ⋅ grain.duration)
- with rnd = random value in the interval [-1, 1]
- grain.dur.jitter: 0.1 - constant value
- density: cntrlLev: a signal between 0 and 1 (1 max, 0 no grains)
*/


/*
declare name "granular_sampling for AUDIBLE ECOSYSTEMICS n.2";
declare author "Luca Spanedda";
declare author "Dario Sanfilippo";
declare version "alpha";
declare description "Realised on composer's instructions 
of the year 2017 edited in L’Aquila, Italy";
*/
grain(seed,var1,timeIndex,memWriteDel,cntrlLev,divDur,x) =
hann(readingSegment) * buffer(bufferSize, readPtr, x) : vdelay
    with{
        // density
        _grainRate = (cntrlLev*(100-1))+1;
        // target grain duration in seconds
        _grainDuration = 0.023 + ((1 - memWriteDel) / divDur);
        // target grain position in the buffer
        _grainPosition = ((timeIndex)+1)/2;
        // make sure to have decorrelated noises
        // grain.dur.jitter: 0.1 - constant value
        durationJitter = noise(2 * seed) * .1 + .1;
        positionJitter = noise(2 * seed + 1) * (1 - memWriteDel) / 100;

        // buffer size
        bufferSize = var1 * ma.SR;
        // hann window
        hann(x) = sin(ma.PI * x) ^ 2.0;

        // a phasor that read new params only when: y_1 < y_2
        phasorLocking = loop ~ _
            with {
                loop(y_1) = ph , unlock
                    with{
                        y_2 = y_1';
                        ph = os.phasor(1, ba.sAndH(unlock, _grainRate));
                        unlock = (y_1 < y_2) + 1 - 1';
                    };
            };

        // two outputs of the phasor: phasor, trigger(y_1<y_2)
        phasor = phasorLocking : _ , !;
        unlocking = phasorLocking : ! , _;

        // new param with lock function based on the phasor
        lock(param) = ba.sAndH(unlocking, param);

        // TO DO: wrap & receive param from AE2
        grainPosition = lock(_grainPosition * positionJitter);
        // TO DO: wrap & receive param from AE2
        grainRate = lock(_grainRate);
        // TO DO: wrap & receive param from AE2
        grainDuration = lock(_grainDuration * durationJitter);

        // maximum allowed grain duration in seconds
        maxGrainDuration = 1.0 / grainRate;
        // phase segment multiplication factor to complete a 
        // Hann cycle in the target duration
        phasorSlopeFactor = maxGrainDuration / 
                            min(maxGrainDuration, grainDuration);
        readingSegment = min(1.0, phasor * phasorSlopeFactor);

        // read pointer
        readPtr = grainPosition * bufferSize + readingSegment
            * (ma.SR / (grainRate * phasorSlopeFactor));

        // decorrelation delay. Instead of 1 control w: 
        // hslider("decorrelation", 1, 0, 1, .001)
        noisePadding = 1 * lock(noise(seed+3)) : abs;
            vdelay(x) = x : de.sdelay(ma.SR, 1024, noisePadding * ma.SR);

        buffer(length, readPtr, x) = it.frwtable( tabInt, 1920000, .0, 
                                                  writePtr, x, readPtr  )
            with{
                writePtr = ba.period(length);
            };
    };

// par (how much grains/instances do you want?)
grainN(voices,var1,timeIndex,memWriteDel,cntrlLev,divDur,x) =
par(i, voices, grain(i,var1,timeIndex,memWriteDel,cntrlLev,divDur,(x/voices)));
granular_sampling(nVoices,var1,timeIndex,memWriteDel,cntrlLev,divDur,x) =
grainN(nVoices,var1,timeIndex,memWriteDel,cntrlLev,divDur,x) :> _ ;
