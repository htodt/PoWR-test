      SUBROUTINE PRITEQ (L,NRANK,XLAMBDA,TL,
     $   LASTIND,INDLOW,INDNUP,NDIM,ELEVEL,RRATE,EN,N,
     $   NF,ND,XJCAPP,FWEIGHT,LASTKON,KONTNUP,KONTLOW,
     $   NFEDGE,ENLTE,EXPFAC,SIGMAKI,LEVEL,
     $   DRJLW,DRLJW,IONGRND,KODRLOW,LASTKDR,
     $   FT,FT2,RNEL,ENTOTL,SIGMAFF,MAXION,NCHARG,OPAMEAN)
C***********************************************************************
C***  PRINTOUT OF 
C***   - THE MAIN CONTRIBUTORS (CONTINUA [FF,BF], DIEL.REC., LINES)
C***     TO THE TEMPERATURE EQUATION (ENERGY BALANCE FOR 
C***                                         RADIATIVE EQUILIBRIUM)
C***   - THE RESULTING VALUE OF THE ALTERNATIVE FORMULATION
C***   - THE SUM OF BOTH
C*** 
C***  CALLED FROM: SUBROUTINE TEMPEQ
C***********************************************************************

      PARAMETER ( MAXMAIN = 5 )
      PARAMETER ( MAXM1 = MAXMAIN-1 )
      DIMENSION BFMAIN(MAXMAIN), DRMAIN(MAXMAIN), BBMAIN(MAXMAIN)
      DIMENSION MAINDBF(MAXMAIN), MAINDDR(MAXMAIN), MAINDBB(MAXMAIN)
      DIMENSION FFMAIN(MAXMAIN), MAINDFF(MAXMAIN)
      DIMENSION XJCAPP(NF),FWEIGHT(NF),XLAMBDA(NF)
      DIMENSION ELEVEL(NDIM)
      DIMENSION INDLOW(LASTIND),INDNUP(LASTIND)
      DIMENSION RRATE(NDIM,NDIM), EN(NRANK), NCHARG(N)
      DIMENSION KONTNUP(LASTKON), KONTLOW(LASTKON), NFEDGE(LASTKON)
      DIMENSION KODRLOW(LASTKDR),IONGRND(NDIM), SIGMAFF(NF,0:MAXION)
      DIMENSION ENLTE(NDIM), EXPFAC(NF), SIGMAKI(NF,LASTKON)
      DIMENSION DRJLW(NDIM),DRLJW(NDIM)
      CHARACTER*10 LEVEL(NDIM),LEVDR

      SAVE LOLD
      DATA LOLD / 0 /

C***  C2 = 2 * H * C     ( CGS UNITS )
      DATA C2 / 3.9724E-16 /
C***  PI8 = 8*PI
      DATA PI8 /25.1327412288 /

      DO 10 M=1, MAXMAIN
      FFMAIN(M) = 0.0
      BFMAIN(M) = 0.0
      DRMAIN(M) = 0.0
      BBMAIN(M) = 0.0
   10 CONTINUE


C***********************************************************
C***  BRANCH FOR ALL DEPTH POINTS EXCEPT THE INNER BOUNDARY:
C***********************************************************
      IF (L .NE. ND) THEN

C***  CONTINUA: LOOP OVER ALL BOUND-FREE TRANSITIONS
      FTGBF = .0
      FTLBF = .0

      DO 5 KONT=1, LASTKON
      NUP = KONTNUP(KONT)
      LOW = KONTLOW(KONT)
      ENNUP = EN(NUP)
      ENLOW = EN(LOW)
      QNLTE = ENLOW / ENNUP
      NFLOW = NFEDGE(KONT)
      QLTE = ENLTE(LOW)/ENLTE(NUP)

C***  INTEGRATION OVER FREQUENCY
      SUM = .0
      DO 2 K=1,NFLOW
      W = 1.E8 / XLAMBDA(K)
      W3 = W * W * W
      G = QLTE * EXPFAC(K)
      SUM = SUM +
     +      (C2*W3*G - (QNLTE-G)*XJCAPP(K))*SIGMAKI(K,KONT)*FWEIGHT(K)
    2 CONTINUE

      SUM = SUM * ENNUP * ENTOTL / OPAMEAN

      IF (SUM .GE. 0.0) THEN
         FTLBF = FTLBF + SUM
         ELSE
         FTGBF = FTGBF - SUM
         ENDIF

      ASUM=ABS(SUM)
      MAIND = ISRCHFLT(MAXMAIN,BFMAIN,1,ASUM)
      IF (MAIND .GT. MAXMAIN) GOTO 5
      IF (MAIND .LT. MAXMAIN) THEN
         CALL SHIFT (BFMAIN,MAIND,MAXM1)
         CALL SHIFT (MAINDBF,MAIND,MAXM1)
      ENDIF
      BFMAIN(MAIND) = ASUM
      IF (SUM .LE. 0.) THEN
         MAINDBF(MAIND) = KONT
      ELSE
         MAINDBF(MAIND) = -KONT
      ENDIF
    5 CONTINUE
      FTBF = FTLBF - FTGBF 


C*** CONTINUA: LOOP OVER ALL LEVELS  ==>  FREE-FREE CONTRIBUTIONS
      FTLFF = 0.0
      FTGFF = 0.0

      DO 4 I=1,N

C*** INTEGRAL OVER FREQUENCY
      SUM = 0.0
      DO 20 K=1,NF
      W=1.E8/XLAMBDA(K)
      W3=W*W*W
      SUM = SUM +
     +      ( C2*W3*EXPFAC(K) - (1.-EXPFAC(K))*XJCAPP(K) ) *
     *      SIGMAFF(K,NCHARG(I))*FWEIGHT(K)
   20 CONTINUE

      SUM = SUM * RNEL * ENTOTL * EN(I) * ENTOTL / OPAMEAN

      IF (SUM .GE. 0.0) THEN
         FTLFF = FTLFF + SUM
         ELSE
         FTGFF = FTGFF - SUM
         ENDIF

      ASUM = ABS(SUM)
      MAIND = ISRCHFLT(MAXMAIN,FFMAIN,1,ASUM)
      IF (MAIND .GT. MAXMAIN) GOTO 4
      IF (MAIND .LT. MAXMAIN) THEN
         CALL SHIFT (FFMAIN,MAIND,MAXM1)
         CALL SHIFT (MAINDFF,MAIND,MAXM1)
      ENDIF
      FFMAIN(MAIND) = ASUM
      IF (SUM .LE. 0.) THEN
         MAINDFF(MAIND) = I
      ELSE
         MAINDFF(MAIND) = -I
      ENDIF
    4 CONTINUE
      FTFF = FTLFF - FTGFF

C***  DIEL. RECOMBINATION/AUTOIONIZATION: LOOP OVER ALL CONTINUA
      FTGDR = .0
      FTLDR = .0

      DO 33 KDR=1, LASTKDR
      LOW = KODRLOW(KDR)
      NUP = IONGRND(LOW)
      ZRATE = ( EN(NUP) * DRJLW(LOW) - EN(LOW) * DRLJW(LOW) ) 
     *        * ENTOTL * C2 / PI8 / OPAMEAN

      IF (ZRATE .GE. 0.) THEN 
         FTLDR = FTLDR + ZRATE
      ELSE
         FTGDR = FTGDR - ZRATE
      ENDIF

      ARATE=ABS(ZRATE)
      MAIND = ISRCHFLT(MAXMAIN,DRMAIN,1,ARATE)
      IF (MAIND .GT. MAXMAIN) GOTO 33
      IF (MAIND .LT. MAXMAIN) THEN
         CALL SHIFT (DRMAIN,MAIND,MAXM1)
         CALL SHIFT (MAINDDR,MAIND,MAXM1)
      ENDIF
      DRMAIN(MAIND) = ARATE
      IF (ZRATE .LE. 0.) THEN
         MAINDDR(MAIND) = KDR
      ELSE
         MAINDDR(MAIND) = -KDR
      ENDIF
   33 CONTINUE
      FTDR = FTLDR - FTGDR


C***  LINES: LOOP OVER ALL BOUND-BOUND TRANSITIONS
      FTGBB = .0
      FTLBB = .0

      DO 3 IND=1, LASTIND
      LOW = INDLOW(IND)
      NUP = INDNUP(IND)
      W = ELEVEL(NUP) - ELEVEL(LOW)
      ZRATE = EN(NUP) * RRATE(NUP,LOW) - EN(LOW) * RRATE(LOW,NUP)

      WZRATE = W * ZRATE * ENTOTL * C2 / PI8 / OPAMEAN

      IF (WZRATE .GE. 0.) THEN 
         FTLBB = FTLBB + WZRATE
      ELSE
         FTGBB = FTGBB - WZRATE
      ENDIF

      ARATE=ABS(WZRATE)
      MAIND = ISRCHFLT(MAXMAIN,BBMAIN,1,ARATE)
      IF (MAIND .GT. MAXMAIN) GOTO 3
      IF (MAIND .LT. MAXMAIN) THEN
         CALL SHIFT (BBMAIN,MAIND,MAXM1)
         CALL SHIFT (MAINDBB,MAIND,MAXM1)
      ENDIF
      BBMAIN(MAIND) = ARATE
      IF (WZRATE .LE. 0.) THEN
         MAINDBB(MAIND) = IND
      ELSE
         MAINDBB(MAIND) = -IND
      ENDIF
    3 CONTINUE
      FTBB = FTLBB - FTGBB

C***  PRINTOUT: PRESENT VERSION FOR CONTINUA(FF,BF) + DIEL.REC. + LINES
      IF (L .NE. LOLD  .AND. L .EQ. 1) PRINT 1
    1 FORMAT (///,20X,'E N E R G Y   B A L A N C E',
     2          /,19X,29('='),
     3         //,7X,'FT_LOC  :  REST OF LOCAL ENERGY EQUATION',
     4          /,7X,'[ LIST OF CONTRIBUTIONS:  + GAIN,  - LOSS,  ',
     >                        '% NETTO PERCENTAGE OF TOTAL (G+L) ]',
     5          /,7X,'FT_FLUX :  DIFFERENCE OF HTOT AND FREQUENCY-',
     >               'INTEGRATED FLUX FROM FIRST MOMENTUM EQUATION',
     6          /,7X,'[ FT_LOC AND FT_FLUX ARE WEIGHTED WITH ',
     >                   '1/OPAMEAN AND WFLUX, RESPECTIVELY ]',
     7          /,7X,'FT      :  SUM OF FT_LOC AND FT_FLUX',
     8         //,1X,'DEPTH',
     >            1X,4('-'),'FREE-FREE',5('-'),
     >            2X,4('-'),'BOUND-FREE',4('-'),
     >            2X,5('-'),'AUTO/DR',6('-'),
     >            2X,12('-'),'LINES',12('-'),
     9          /,1X,'  L  ',3(6X,'+',9X,1X,3X),17X,'+',9X,1X,3X,
     >            6X,'T(RL)',
     >          /,1X,5X,3(6X,'-',9X,'%',3X),17X,'-',9X,'%',3X,
     >            5X,'-FT_LOC',
     >          /,1X,5X,3(6X,1X,9X,1X,3X),17X,1X,9X,1X,3X,5X,'-FT_FLUX',
     >          /,1X,5X,3(6X,1X,9X,1X,3X),17X,1X,9X,1X,3X,7X,'-FT')
      PRINT *,' '
      IF (L .NE. LOLD .AND. L .NE. 1) PRINT 19
   19 FORMAT (55('- '),/)
      LOLD=L
      FFTOT=FTGFF+FTLFF
      BFTOT=FTGBF+FTLBF
      DRTOT=FTGDR+FTLDR
      BBTOT=FTGBB+FTLBB
      FTTOT=FFTOT+BFTOT+DRTOT+BBTOT
      FTFFREL=FTFF/FTTOT
      FTBFREL=FTBF/FTTOT
      FTDRREL=FTDR/FTTOT
      FTBBREL=FTBB/FTTOT
      PRINT 11, L, FTGFF, FTGBF, FTGDR, FTGBB, TL
   11 FORMAT (1X,I3,2X,3(1X,1P,E10.3,2X,5X,2X),12X,E10.3,0P,
     >        2X,5X,2X,3X,F10.0)
      PRINT 12, FTLFF, -100.*FTFFREL, FTLBF, -100.*FTBFREL,
     >          FTLDR, -100.*FTDRREL, FTLBB, -100.*FTBBREL, -(FT-FT2)
   12 FORMAT (1X,3X,2X,3(1X,1P,E10.3,0P,2X,F5.1,2X),
     >        12X,1P,E10.3,0P,2X,F5.1,2X,3X,1P,E10.3,0P)
      PRINT 13,-FT2
      PRINT 13, -FT
   13 FORMAT (1X,3X,2X,3(1X,10X,2X,5X,2X),
     >        12X,10X,2X,5X,2X,3X,1P,E10.3,0P)
      DO 100 M=1,MAXMAIN
      MFF=MAINDFF(M)
      LEV=IABS(MFF)
      FFREL=FLOAT(ISIGN(1,MFF))*FFMAIN(M)/FFTOT
      MBF=MAINDBF(M)
      KONT=IABS(MBF)
      BFREL=FLOAT(ISIGN(1,MBF))*BFMAIN(M)/BFTOT
      MDR=MAINDDR(M)
      KDR=IABS(MDR)
      IF (DRTOT .EQ. .0) THEN
         DRREL=0.0
         ELSE
         DRREL=FLOAT(ISIGN(1,MDR))*DRMAIN(M)/DRTOT
         ENDIF
      IF (LASTKDR .EQ. 0) THEN
         LEVDR='          '
         ELSE
         LEVDR=LEVEL(KODRLOW(KDR))
         ENDIF
      MBB=MAINDBB(M)
      IND=IABS(MBB)
      BBREL=FLOAT(ISIGN(1,MBB))*BBMAIN(M)/BBTOT
      PRINT 111, LEVEL(LEV),100.*FFREL,
     >           LEVEL(KONTLOW(KONT)),100.*BFREL,
     2           LEVDR,100.*DRREL,
     3           LEVEL(INDNUP(IND)),LEVEL(INDLOW(IND)),100.*BBREL
  111 FORMAT (1X,3X,2X,3(2X,A10,1X,F5.1,2X),2X,A10,1X,A10,1X,F5.1)
  100 CONTINUE

      ELSE
C******************************************************
C***  BRANCH FOR INNER BOUNDARY POINT ONLY
C******************************************************

C***  PRINTOUT:
      PRINT *, ' '
      IF (L .NE. LOLD) PRINT 19
      LOLD=L
      PRINT 15, L, TL
   15 FORMAT (2X,I3,96X,F10.0)
      PRINT 16, -FT
   16 FORMAT (101X,1P,E10.3,0P)

      ENDIF

      RETURN
      END
