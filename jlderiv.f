
      SUBROUTINE JLDERIV (DJLDNI,IND,DELTAX,XMAX,XRED,XBLUE,
     $   DETAL,DOPAL,SLNEW,OPAL,NFL,PHI,PWEIGHT,OPACIND,SCNEIND,
     $   IBLENDS,MAXLAP,XLAMZERO,BETA,PHIL,NBLENDS,
     $   VDOP,I,INDNUP,INDLOW,ETAX,OPAX)
C***********************************************************************
C***  CALCULATES  DJLDNI := DERIVATIVE OF THE LINE RADIATION FIELD
C***  (SCHARMER APPROXIMATION) WITH RESPECT TO THE POP. NUMBER EN(I)
C***  - NOTE: DJLDNI IS DEFINED AS - DJ/DN  (MINUS!)
C***  - NOTE: DERIVATIVES OF THE CONTINUUM-BACKGROUND ARE NEGLECTED!
C***  - CALLED FROM DERIV AND FROM TEMPEQ
C***  Nota bene: ETAX AND OPAX USE THE SCRATCH ARRAYS ATEST AND BTEST!
C***  CAUTION: OPAX HAS THE MEANING OF 1/OPACITY
C***********************************************************************
 
      DIMENSION XRED(2), XBLUE(2),DETAL(2),DOPAL(2),SLNEW(2),OPAL(2)
      DIMENSION INDNUP(2), INDLOW(2)
      DIMENSION PHI(NFL),PWEIGHT(NFL)
      DIMENSION OPACIND(2),SCNEIND(2)
      DIMENSION IBLENDS(MAXLAP,2),NBLENDS(2),XLAMZERO(2),BETA(MAXLAP)
      DIMENSION PHIL(NFL,MAXLAP),ETAX(NFL),OPAX(NFL)

C***  WPIINV = PI ** (-1/2)
      DATA WPIINV / 0.5641896 /
C***  CLIGHT = LIGHT VELOCITY IN KM/S
      DATA CLIGHT / 2.99792458E5 /

C***  STATEMENT FUNCTION FOR ABBREVIATED NOTATION
      STATFUN(KL) = PHIL(KL,LB) * OPAX(KL) * PWEIGHT(KL)

C***  CONVERT XRED AND XBLUE TO CORRESPONDING LINE FREQUENCY INDICES
C***  NOTE THAT THE LINE FREQUENCIES ARE INDEXED IN FALLING SEQUENCE
      KLMAX=(XMAX-XRED(IND))/DELTAX + 1.
      KLMIN=(XMAX-XBLUE(IND))/DELTAX + 1.999999999

C***  BRANCH FOR SINGLE (I.E. UNBLENDED) LINES ********************
      IF (NBLENDS(IND) .EQ. 1) THEN
      SCNEWKC=SCNEIND(IND)
      OPAKC=OPACIND(IND)
      OPALI=OPAL(IND)
      DOPALI=DOPAL(IND)
      DETALI=DETAL(IND)
      SLNEWI=SLNEW(IND)
      BETA1=OPA  KC /OPALI

C***  SUM = (MINUS) CORE INTEGRAL OVER DERIVATIVE OF SNEW(TOTAL)
      SUM=.0

C***  RATE INTEGRAL OVER LINE CORES
      DO 8 KL = KLMIN, KLMAX
      PK = PHI(KL)
      P = PK / (PK + BETA1)
      S = P * SLNEWI + (1.-P) * SCNEWKC
      OPAT = OPAKC + PK * OPALI
      BRACKET = (DOPALI * S - DETALI) * PK / OPAT
      SUM = SUM + BRACKET * PWEIGHT(KL)
    8 CONTINUE
 
C***  CORRECT FOR THE INTEGRATION STEP XRED,X(KLMAX)
      IF (KLMAX .LT. NFL) THEN
         XKLMAX = XMAX-(KLMAX-1)*DELTAX
         Q = (XKLMAX-XRED(IND))/DELTAX
         PK = PHI(KLMAX)
         P = PK / (PK + BETA1)
         S = P * SLNEWI + (1.-P) * SCNEWKC
         OPAT = OPAKC + PK * OPAL(IND)
         BRACKET = (DOPALI * S - DETALI) * PK / OPAT
         SUM = SUM + BRACKET * PWEIGHT(KLMAX) * 0.5 * (Q-1.)

         PK = PHI(KLMAX+1)
         P = PK / (PK + BETA1)
         S = P * SLNEWI + (1.-P) * SCNEWKC
         OPAT = OPAKC + PK * OPALI
         BRACKET = (DOPALI * S - DETALI) * PK / OPAT
         SUM = SUM + BRACKET * PWEIGHT(KLMAX+1) * 0.5 * Q
         ENDIF


C***  CORRECT FOR THE INTEGRATION STEP X(KLMIN),XBLUE
      IF (KLMIN .GT. 1) THEN
         XKLMIN=XMAX-(KLMIN-1)*DELTAX
         Q=(XBLUE(IND)-XKLMIN)/DELTAX
         PK = PHI(KLMIN)
         P = PK / (PK + BETA1)
         S = P * SLNEWI + (1.-P) * SCNEWKC
         OPAT = OPAKC + PK * OPALI
         BRACKET = (DOPALI * S - DETALI) * PK / OPAT
         SUM = SUM + BRACKET * PWEIGHT(KLMIN) * 0.5 * (Q-1.)

         PK = PHI(KLMIN-1)
         P = PK / (PK + BETA1)
         S = P * SLNEWI + (1.-P) * SCNEWKC
         OPAT = OPAKC + PK * OPALI
         BRACKET = (DOPALI * S - DETALI) * PK / OPAT
         SUM = SUM + BRACKET * PWEIGHT(KLMIN-1) * 0.5 * Q
         ENDIF

      DJLDNI=SUM

C***  BRANCH FOR BLENDED LINES ***************************************
      ELSE

      KLA = MAX (KLMIN-1,1)
      KLB = MAX (KLMAX+1,NFL)

C**** Prepare FOR ALL OVERLAPPING LINES THE DISPLACED PROFILE FUNCTION
      DO 100 LB=1,NBLENDS(IND)
      IND1=IBLENDS(LB,IND)
      IF (XRED(IND1) .GE. XBLUE(IND1)) GOTO 100
C***  - PHIL = DISPLACED PROFILE FUNCTIONS
      IF (IND .EQ. IND1) THEN
         DO 250 KL=KLA, KLB
         PHIL(KL,LB) = PHI(KL)
  250    CONTINUE
         ELSE
C***     SHIFT OF CONSIDERED LINE RELATIVE TO BLENDING LINE, IN DOPPLER UNITS
         XSHIFT = (XLAMZERO(IND1)/XLAMZERO(IND) - 1. ) * CLIGHT / VDOP
     $            + XMAX
C***     CAUTION: THE FOLLOWING LOOP IS VERY TIME-CONSUMING!
         DO 220 KL=KLA, KLB
         XREL = XSHIFT - (KL-1) * DELTAX
         PHIL(KL,LB) = EXP(-XREL*XREL) * WPIINV
  220    CONTINUE
         ENDIF
100   CONTINUE

C***  STORE ETA and KAPPA AS FUNCTION OF FREQUENCY
      DO 235 KL=KLA,KLB
        OPACI=OPACIND(IND)
        ETAX(KL)=SCNEIND(IND) * OPACI
        OPAX(KL)=OPACI
235   CONTINUE

      DO 240 LB=1, NBLENDS(IND)
      IND1 = IBLENDS(LB,IND)
      IF (XRED(IND1) .GE. XBLUE(IND1)) GOTO 240
        DO 230 KL=KLA, KLB
          PROD = PHIL(KL,LB) * OPAL(IND1)
          ETAX(KL) = ETAX(KL) + PROD * SLNEW(IND1)
          OPAX(KL) = OPAX(KL) + PROD
  230     CONTINUE
  240   CONTINUE

C***    Note !!!!!!!! OPAX := 1/OPA(X)
      DO 245 KL=KLA,KLB
        OPAX(KL)=1./OPAX(KL)
245   CONTINUE


C****** Loop over all lines
      SUM = 0.
      DO 200 LB=1,NBLENDS(IND)
      IND1 = IBLENDS(LB,IND)
      IF (XRED(IND1) .GE. XBLUE(IND1)) GOTO 200

C***  SHORT EXIT FOR BLEND COMPONENTS WHICH DO NOT INVOLVE N(I)
      IF (INDNUP(IND1) .NE. I  .AND.  INDLOW(IND1) .NE. I) GOTO 200

C***  INTEGRAL OVER LINE CORES
      SUMDETA=0.
      SUMDOPA=0.
      DO 300 KL = KLMIN, KLMAX
      PROD = STATFUN(KL)
      SUMDETA = SUMDETA + PROD
      SUMDOPA = SUMDOPA + PROD * ETAX(KL) * OPAX(KL)
  300 CONTINUE

C***  CORRECT FOR THE INTEGRATION STEP XRED,X(KLMAX)
      IF (KLMAX .LT. NFL) THEN
         XKLMAX = XMAX-(KLMAX-1)*DELTAX
         Q = (XKLMAX-XRED(IND))/DELTAX
         PROD0 = STATFUN(KLMAX)
         PROD1 = STATFUN(KLMAX+1)
         SUMDETA = SUMDETA + PROD0 * 0.5 * (Q-1.)
     $                     + PROD1 * 0.5 * Q
         SUMDOPA = SUMDOPA 
     $        + PROD0 * ETAX(KLMAX)   * OPAX(KLMAX)   * 0.5 * (Q-1.)
     $        + PROD1 * ETAX(KLMAX+1) * OPAX(KLMAX+1) * 0.5 * Q
         ENDIF


C***  CORRECT FOR THE INTEGRATION STEP X(KLMIN),XBLUE
      IF (KLMIN .GT. 1) THEN
         XKLMIN=XMAX-(KLMIN-1)*DELTAX
         Q=(XBLUE(IND)-XKLMIN)/DELTAX
         PROD0 = STATFUN(KLMIN)
         PROD1 = STATFUN(KLMIN-1)
      SUMDETA = SUMDETA + PROD0 * 0.5 * (Q-1.)
     $                  + PROD1 * 0.5 * Q
      SUMDOPA = SUMDOPA 
     $        + PROD0 * ETAX(KLMIN)   * OPAX(KLMIN)   * 0.5 * (Q-1.)
     $        + PROD1 * ETAX(KLMIN-1) * OPAX(KLMIN-1) * 0.5 * Q
      ENDIF
     
      SUM = SUM + DETAL(IND1) * SUMDETA - DOPAL(IND1) * SUMDOPA

200   CONTINUE

      DJLDNI=-SUM
      
      ENDIF
C***  END OF BRANCH FOR BLENDING LINES  =============================

      RETURN
      END
