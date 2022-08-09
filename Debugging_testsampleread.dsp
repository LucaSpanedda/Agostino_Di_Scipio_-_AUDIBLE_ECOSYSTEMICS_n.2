import("ae2lib.lib");

sampler(bufferLengthSamples, memChunk, ratio, x) = it.frwtable(3, bufferLengthSamples, .0, ba.period(bufferLengthSamples), x, rIdx)
    with {
        readingLength = si.smoo(memChunk) * bufferLengthSamples;
        readingRate = ma.SR / readingLength;
        rIdx = os.phasor(readingLength * si.smoo(ratio), readingRate);
    };

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

signalFlow2a = loop ~ _
    with{
        loop(fb) = fb+0, 1, 2, 3, 4, 5, 6, 7;
    };

process = signalFlow2a;
