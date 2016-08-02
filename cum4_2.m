function Cum4 = cum4_2(P)

Cum4 = mean(P.^4) - 4*mean(P)*mean(P.^3) - 3*mean(P.^2)^2 +12*mean(P)^2*mean(P.^2)- 6*mean(P)^4;