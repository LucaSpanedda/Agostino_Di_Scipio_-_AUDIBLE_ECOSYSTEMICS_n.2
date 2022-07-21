import("seam.discipio.lib");

//-----------------------signal flow 1b-----------------------
//Role of the signal flow block: generation of control signals based on mic1 and mic2 input, plus internal signal generators

signal_flow_1b(
              var1,
              var3,
              grainOut1,
              grainOut2,
              mic1,
              mic2,
              memWriteLev,
              cntrlMain
              ) =
              (
                  mic1, mic2 : HP1(50), HP1(50) : LP1(6000), LP1(6000) : integrator(0.01), integrator(0.01) : sds.delayfb(0.01,0.999), sds.delayfb(0.01,0.999) : LP5(0.5), LP5(0.5)
              ),
              (
               grainOut1, grainOut2: + : integrator(0.01) : sds.delayfb(0.01, 0.97) : LP5(0.5) <: _+sds.delayfb(var1*(2), (1-var3)*(0.5)) : sds.mapsub(_,1,0.5)
              ),
              (
                  (timeIndex(var1)<: sds.mapmul(_,-2,0.5),sds.mapmul(_,1,0.5)), triangle1(var1, memWriteLev)*memWriteLev,triangle2(var1, cntrlMain), triangle3(var1)
              )
              with{
                  timeIndex(var1) = triangleWave(1/(var1*(2)));
                  triangle1(var1, memWriteLev) = triangleWave(1/(var1*(6)));
                  triangle2(var1, cntrlMain) = triangleWave(var1*(1-cntrlMain));
                  triangle3(var1) = triangleWave(1/var1);
              };

process = signal_flow_1b;