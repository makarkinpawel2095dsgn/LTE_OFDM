
%fix width
bitFix = 8;
shift = 13;
phaseWidth = 20;

%reference phase
phRef = fix(pi/4*2^phaseWidth)/2^phaseWidth; 

fltr = [226
409
-2957
-22
18727
18727
-22
-2957
409
226];

%phases on channels
CRS_Phases1=CRS_Phases(:,1);
CRS_Phases2=CRS_Phases(:,2);
CRS_Phases3=CRS_Phases(:,3);
CRS_Phases4=CRS_Phases(:,4);
CRS_Phases5=CRS_Phases(:,5);
CRS_Phases6=CRS_Phases(:,6);
CRS_Phases7=CRS_Phases(:,7);
CRS_Phases8=CRS_Phases(:,8);
CRS_Phases9=CRS_Phases(:,9);
CRS_Phases10=CRS_Phases(:,10);
CRS_Phases11=CRS_Phases(:,11);
CRS_Phases12=CRS_Phases(:,12);

%phases on channels fix
Ph1 = fix(CRS_Phases1*2^phaseWidth)/2^phaseWidth;
Ph2 = fix(CRS_Phases2*2^phaseWidth)/2^phaseWidth;
Ph3 = fix(CRS_Phases3*2^phaseWidth)/2^phaseWidth;
Ph4 = fix(CRS_Phases4*2^phaseWidth)/2^phaseWidth;
Ph5 = fix(CRS_Phases5*2^phaseWidth)/2^phaseWidth;
Ph6 = fix(CRS_Phases6*2^phaseWidth)/2^phaseWidth;
Ph7 = fix(CRS_Phases7*2^phaseWidth)/2^phaseWidth;
Ph8 = fix(CRS_Phases8*2^phaseWidth)/2^phaseWidth;
Ph9 = fix(CRS_Phases9*2^phaseWidth)/2^phaseWidth;
Ph10 = fix(CRS_Phases10*2^phaseWidth)/2^phaseWidth;
Ph11 = fix(CRS_Phases11*2^phaseWidth)/2^phaseWidth;
Ph12 = fix(CRS_Phases12*2^phaseWidth)/2^phaseWidth;

averagePh(1) = fix(((Ph1(1)+Ph2(1)+Ph3(1)+Ph4(1)+Ph5(1)+Ph6(1)+Ph7(1)+Ph8(1)+Ph9(1)+Ph10(1)+Ph11(1)+Ph12(1))/12)*2^phaseWidth)/2^phaseWidth;
averagePh(2) = fix(((Ph1(2)+Ph2(2)+Ph3(2)+Ph4(2)+Ph5(2)+Ph6(2)+Ph7(2)+Ph8(2)+Ph9(2)+Ph10(2)+Ph11(2)+Ph12(2))/12)*2^phaseWidth)/2^phaseWidth;

%signal constellation
figure(1)
plot(Ph2)
title('Phase')

rho1=zeros(1,length(Ph1));
for i=2:1:length(Ph1)
    rho1(i)=rho1(i-1)+1/length(Ph1);
end
figure(2)
polarplot(Ph1,rho1,'-o');

%initial
discreteFix = 0;
discreteOld =0; 
discreteFixOld = 0;
PhInterp(1) = averagePh(1);  
PhInterpDFix(1) = averagePh(1);
i=1;
j=1;
r=0;
rOld=0;
jj=5;
gg=0;
cor=zeros(1,length(Ph1)*5);
pointNOld=0;


while i<length(Ph1)-1

    k = CRS_Addr(i+1) - CRS_Addr(i) + r;
    pointN = fix(k/128); %number of point
    r = mod(k,128); %remainder

    %delta of piecewise linear 
    if (CRS_Addr(i+1) - CRS_Addr(i)) == 548
        discrete = (averagePh(i+1)-averagePh(i))/548;
    end
    if (CRS_Addr(i+1) - CRS_Addr(i)) == 412
        discrete = (averagePh(i+1)-averagePh(i))/412;
    end
    discreteFix = fix((discrete*2^shift)*2^bitFix)/2^bitFix;

    %first point on piece
    if j == 1
        PhInterp(j+1) = PhInterp(j) + discrete*128;
        PhInterpDFix(j+1) = PhInterpDFix(j) + discreteFix*128/2^shift;
    else
        PhInterp(j+1) = PhInterp(j) + discreteOld*rOld + discrete*(128-rOld);
        PhInterpDFix(j+1) = PhInterpDFix(j) + discreteFixOld*rOld/2^shift + discreteFix*(128-rOld)/2^shift;
    end   
    
    %next points on piece
    PhInterp(j+2) = PhInterp(j+1) + discrete*128;
    PhInterp(j+3) = PhInterp(j+2) + discrete*128;

    PhInterpDFix(j+2) = PhInterpDFix(j+1) + discreteFix*128/2^shift;
    PhInterpDFix(j+3) = PhInterpDFix(j+2) + discreteFix*128/2^shift;

    if pointN > 3 
        PhInterp(j+4) = PhInterp(j+3) + discrete*128;
        PhInterpDFix(j+4) = PhInterpDFix(j+3) + discreteFix*128/2^shift;
    end
    if pointN==5  
        PhInterp(j+5) = PhInterp(j+4) + discrete*128;
        PhInterpDFix(j+5) = PhInterpDFix(j+4) + discreteFix*128/2^sift;
    end
    
    for gg=j:1:j+pointN-1
        deltaPh(gg) = PhInterp(gg) + phRef;
        deltaPhFix(gg) = PhInterpDFix(gg) + phRef;
    end

    %filter 
    if (j+pointN)>10
        while jj<(j+pointN-9)
            cor(jj) = fltr'*deltaPh(jj+(0:9))';
            corFix(jj) = fltr'*deltaPhFix(jj+(0:9))';
            cor(jj) = cor(jj)/(2^15); 
            jj=jj+1;
        end
    end
    i=i+1;
    %correction data for next step
    if jj>1
        Ph1(i+1) = Ph1(i+1) - cor(jj-1); 
        Ph2(i+1) = Ph2(i+1) - cor(jj-1); 
        Ph3(i+1) = Ph3(i+1) - cor(jj-1); 
        Ph4(i+1) = Ph4(i+1) - cor(jj-1); 
        Ph5(i+1) = Ph5(i+1) - cor(jj-1); 
        Ph6(i+1) = Ph6(i+1) - cor(jj-1); 
        Ph7(i+1) = Ph7(i+1) - cor(jj-1); 
        Ph8(i+1) = Ph8(i+1) - cor(jj-1); 
        Ph9(i+1) = Ph9(i+1) - cor(jj-1); 
        Ph10(i+1) = Ph10(i+1) - cor(jj-1); 
        Ph11(i+1) = Ph11(i+1) - cor(jj-1); 
        Ph12(i+1) = Ph12(i+1) - cor(jj-1); 
    end 
    
    averagePh(i+1) = fix(((Ph1(i+1)+Ph2(i+1)+Ph3(i+1)+Ph4(i+1)+Ph5(i+1)+Ph6(i+1)+Ph7(i+1)+Ph8(i+1)+Ph9(i+1)+Ph10(i+1)+Ph11(i+1)+Ph12(i+1))/12)*2^phaseWidth)/2^phaseWidth;
    j=j+pointN;
    rOld = r;
    discreteOld = discrete;
    discreteFixOld = discreteFix;
    pointNOld = pointN;
end

% figure(3)
% plot(PhInterpDFix)
%  title('Phase interpolation')

figure(4)
plot(deltaPh)
title('Delta phase interpolation')
figure(5)
plot(cor)
title('Corection coefficient')
figure(6)
plot(Ph1)

%signal constellation
title('Rotated phase')
figure(7)
polarplot(Ph2,rho1,'r-o')