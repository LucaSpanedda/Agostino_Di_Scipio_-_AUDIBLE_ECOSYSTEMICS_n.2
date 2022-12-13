// import faust standard library
import("stdfaust.lib");

// PERFORMANCE SYSTEM VARIABLES
SampleRate = 44100;
var1 = 2;
var2 = 2000;
var3 = 0.5;
var4 = 2;

/*
ratio ranges (following from the given values):
sample read 1: for var2 = 2000, ratio varies between 7.66283 (diffHL= 0) and 11.4943 (diffHL = 1)
sample read 2: ratio varies between 1.11111 (diffHL = 0) and 0.766283 (diffHL = 1)
sample read 3: for var2 = 2000, ratio varies between 15.3257 (diffHL = 0) and 11.4943 (diffHL = 1)
sample read 4: ratio varies between 0.957854 (diffHL = 0) and 1.03448 (diffHL = 1)
sample read 5: ratio = 0.766283
*/
diffHL = hslider("diffHL", 0,0,1,.001);
memWriteLev = hslider("memWriteLev", 0,0,1,.001);
memWriteDel1 = memWriteLev@(var1 / 2);
memWriteDel2 = memWriteLev@(var1 / 3);
ratioRanges = ( (var2 + (diffHL * 1000))/261,  (290 - (diffHL * 90))/261, ((var2 * 2) - (diffHL * 1000))/261, (250 + (diffHL * 20))/261, .766283);
//process = ratioRanges;

sampler(bufferLength, memChunk, ratio, x) = y
    with {
        y = it.frwtable(3, L, .0, writePtr, x, readPtr * memChunkLock * L) * trapezoidal(.95, readPtr)
            with {
                memChunkLimited = memChunk; //limit(1, .010, memChunk);
                L = bufferLength * SampleRate; // hard-coded: change this to match your samplerate
                writePtr = ba.period(L);
                readPtr = phasor : _ , !;
                memChunkLock = phasor : ! , _;
                phasor = loop ~ si.bus(3) : _ , ! , _
                    with {
                        loop(phState, incrState, chunkLenState) = ph , incr , chunkLen
                            with {
                                ph = ba.if(phState < 1.0, phState + incrState, 0.0);
                                unlock = phState < phState' + 1 - 1';
                                incr = ba.if(   unlock, 
                                                ma.T * max(.1, min(10.0, ratio)) / 
                                                    max(ma.T, (memChunkLimited * bufferLength)), 
                                                incrState);
                                chunkLen = ba.if(unlock, memChunkLimited, chunkLenState);
                            };
                    };
                trapezoidal(width, ph) = 
                    min(1.0, 
                        abs(ma.decimal(ph + .5) * 2.0 - 1.0) / 
                            max(ma.EPSILON, 1.0 - width));
            };
    };

SRSect1(x) = x : sampler( var1, (1 - memWriteDel2), (var2 + (diffHL * 1000))/261);
SRSect2(x) = x : sampler( var1, (memWriteLev + memWriteDel1)/2, ( 290 - (diffHL * 90))/261);
SRSect3(x) = x : sampler( var1, (1 - memWriteDel1), ((var2 * 2) - (diffHL * 1000))/261);
SRSect4(x) = x : sampler( var1, 1, (250 + (diffHL * 20))/261);
SRSect5(x) = x : sampler( var1, memWriteLev, .766283);
process = os.osc(400) * .1 <: (SRSect1,SRSect2,SRSect3,SRSect4,SRSect5,0) :> + <: _,_;
