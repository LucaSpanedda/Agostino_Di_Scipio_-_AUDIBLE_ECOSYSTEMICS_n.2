import("seam.discipio.lib");

//-----------------------signal flow 1a-----------------------
//Role of the signal flow block: generation of control signals based on mic3 and mic4 input

// TEST VAR
var1 = 10.0;
var2 = 10000.0;

signalFlow1a(mic3, mic4) = no.noise*0.1 : map6Sect // SenstoExt
//, memWriteDel1 , memWriteDel2 , memWriteLev , cntrlLev1 , cntrlLev2 , cntrlFeed , cntrlMain
    with{
        xminy(x,y) = x-y;
        localmaxSub(x) = ( mic3 : localmax(x) ), ( mic4 : localmax(x) ) : xminy;
        map6(x) = 6 + x * 6;
        map05(x) = x * 0.5;
        map6Sect(x) = x : integrator(.01) : delayfb(0.01,0.95);
        map6Sum = (mic3 : map6Sect) + (mic4 : map6Sect) : map6;
        localmaxSect = localmaxSub(map6Sum) : localmax(map6Sum);
        SenstoExt = ( localmaxSect + (localmaxSect : delayfb(12,0)) ) : map05 : LP1(0.5);
        };

process = signalFlow1a;
// first signal: it should be positive but it shows negative values