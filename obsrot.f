      SUBROUTINE OBSROT  (LTOT,CORE,XMAX,EMINT,BCORE,DBDR,TAUMAX,PJPJ,
     $          ZFINE,OPAFINE,OPALFIN,ETAFINE,ETALFIN,SFINE,
     $            RRAY,OPARAY,OPALRAY,ETARAY,ETALRAY,ZRAY,XCMF,S,XN )
C***********************************************************************
C***  INTEGRATION OF THE EMERGENT INTENSITY IN THE OBSERVER'S FRAME
C***  VECTOR-OPTIMIZED CRAY VERSION ---
C***********************************************************************
 
      DIMENSION XCMF(LTOT),OPARAY(LTOT),OPALRAY(LTOT),ZRAY(LTOT)
      LOGICAL CORE
      DIMENSION XHEL(300)
      IF (LTOT+5  .GT. 300) STOP ' OBSFR'
C***  WPI = SQRT(PI)
      DATA WPI /1.772454/
 
C***  INITIALIZATION
      EMINT=.0
      TAUSUM=.0
 
C***  FIND THE POSITION OF THE SCATTERING ZONE AND ADD ADDITIONAL DEPTH
C***  POINTS AT LRED, LBLUE
      LLOW=1
      LBLUE=1
      IADD=0
C***  LOOP FOR EACH SCATTERING ZONE
   10 CONTINUE
      LADD=LLOW+IADD
      DO 1 L=LADD,LTOT
    1 XHEL(L-LADD+1)=XCMF(L)
      LHTO=LTOT-LADD+1
      IF (XCMF(LADD) .GE. XMAX ) THEN
         I=ISRCHFLT (LHTO,XHEL,1,XMAX)
         I=I+LADD-1
         IF (I.LE.LTOT) THEN
C***  RED BOUNDARY OF THE SCATTERING ZONE
            LRED=I
            CALL ADDROT  (XMAX,LRED,
     $         LTOT,ZRAY,XCMF,OPARAY,ETARAY,OPALRAY,ETALRAY,S,RRAY,PJPJ)
      IADD=1
         ELSE
C***        NO SCATTERING ZONE CROSSED BY THAT RAY
            LRED=LTOT
      IADD=0
         ENDIF
      ELSE IF (XCMF(LADD) .GT. -XMAX) THEN
C***        SCATTERING ZONE TOUCHES OUTER BOUNDARY
         LRED=LLOW
      IADD=0
      ELSE
         I=ISRCHFGT(LHTO,XHEL,1,-XMAX)
         I=I+LADD-1
         IF (I.LE.LTOT) THEN
C***  RED BOUNDARY OF THE SCATTERING ZONE
            LRED=I
            CALL ADDROT  (-XMAX,LRED,
     $         LTOT,ZRAY,XCMF,OPARAY,ETARAY,OPALRAY,ETALRAY,S,RRAY,PJPJ)
      IADD=1
         ELSE
C***        NO SCATTERING ZONE CROSSED BY THAT RAY
            LRED=LTOT
      IADD=0
         ENDIF
      ENDIF
 
      IF (LRED.GT.LLOW) THEN
C***     INTEGRATE CONTINUUM FROM OUTER BOUNDARY TO LRED
         CALL CONTINT (LLOW,LRED,EMINT,TAUSUM,ZRAY,OPARAY,S,LTOT)
         IF (TAUSUM .GT. TAUMAX) RETURN
      ENDIF
 
      IF (LRED.LT.LTOT) THEN
         LLOW=LRED
      LADD=LLOW+IADD
         DO 11 L=LADD,LTOT
   11    XHEL(L-LADD+1)=ABS(XCMF(L))
         LHTO=LTOT-LADD+1
         I=ISRCHFGT(LHTO,XHEL,1,XMAX)
         I=I+LADD-1
         IF (I.GT.LTOT) THEN
C***        SCATTERING ZONE TOUCHES BACKWARD BOUNDARY
            LBLUE=LTOT
      IADD=0
         ELSE IF (XCMF(I).GT.XMAX) THEN
C***  BLUE BOUNDARY OF THE SCATTERING ZONE
            LBLUE=I
            CALL ADDROT  (XMAX,LBLUE,
     $         LTOT,ZRAY,XCMF,OPARAY,ETARAY,OPALRAY,ETALRAY,S,RRAY,PJPJ)
      IADD=1
         ELSE
C***  BLUE BOUNDARY OF THE SCATTERING ZONE
            LBLUE=I
            CALL ADDROT  (-XMAX,LBLUE,
     $         LTOT,ZRAY,XCMF,OPARAY,ETARAY,OPALRAY,ETALRAY,S,RRAY,PJPJ)
      IADD=1
         ENDIF
 
C***  INTEGRATE ACROSS THE SCATTERING ZONE, I.E. FROM LRED TO LBLUE
         CALL    ZONEROT (LRED,LBLUE,EMINT,TAUSUM,PJPJ,
     $          ZFINE,OPAFINE,OPALFIN,ETAFINE,ETALFIN,SFINE,RRAY,
     $          ZRAY,XCMF,OPARAY,OPALRAY,ETARAY,ETALRAY,XN,LTOT)
         IF (TAUSUM .GT. TAUMAX) RETURN
         LLOW=LBLUE
      ELSE
         LLOW=LTOT
         IADD=0
      ENDIF
 
C***  BACKWARD BOUNDARY REACHED ;
      IF (LLOW.LT.LTOT) GOTO 10
 
C***  FOR CORE RAYS, ADD INCIDENT RADIATION
   40 IF (CORE) THEN
            X=OPARAY(LTOT)
            IF (LBLUE .EQ. LTOT) THEN
               PHI=EXP(-XCMF(LTOT)*XCMF(LTOT))/WPI
               X=X+PHI*OPALRAY(LTOT)
               ENDIF
            PLUSI=BCORE+DBDR*ZRAY(LTOT)/X
            EMINT=EMINT+PLUSI*EXP(-TAUSUM)
            ENDIF
 
      RETURN
      END
