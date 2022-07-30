import("ae2lib.lib");

sampleread1(x) = 
x : sampleread(var1, ratio1, memchunk1) : HP4(50) : delayfb( (var1 / 2), 0);

            diffHL = .4+abs(noise(25))*0.11;
            memWriteDel2 = .3+abs(noise(27))*0.22;

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

process = no.noise : sampleread(var1, ratio1, memchunk1);