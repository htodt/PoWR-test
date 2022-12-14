      FUNCTION EXPINT1(U)
C***********************************************************************
C***  EXPONENTIAL INTEGRAL E1 (SOURCE: SIMON-DECK E1)
C***  FUER U.LE.1.078 E1 GENAU AUF ETWA 13 STELLEN
C***  FUER U.GT.1.078 FEHLER VON E1.LT.2.E-8
C***********************************************************************

      REAL CF(16)
      DATA GAMMA / -0.57721566490153 /
      DATA CF
     1/.29871733327421E-14,-.50981091545465E-13
     2,.81933897126640E-12,-.12353110643709E-10
     3,.17397297489890E-09,-.22774643986765E-08
     4,.27557319223986E-07,-.30619243582206E-06
     5,.3100198412698E-05,-.28344671201814E-04
     6,.23148148148148E-03,-.1666666666667E-02
     7,.10416666666667E-01,-.55555555555556E-01
     8,.25000000000000    ,-.10000000000000E+01/

C***  EXPINT1 IS ONLY DEFINED FOR POSITIVE ARGUMENTS
      IF (U .LE. 0.) THEN
         CALL REMARK (' EXPINT1: ARGUMENT OUT OF RANGE')
         PRINT *, 'EXPINT1: ARGUMENT OUT OF RANGE: ',U
         STOP 'ERROR'

C***  ARGUMENT .LE. 1.:
      ELSE IF (U .LE. 1.) THEN
         E1=0.
         DO 1 N=1,16
         E1=(E1+CF(N))*U
1        CONTINUE
         EXPINT1=GAMMA-ALOG(U)-E1

C***  ARGUMENT .GT. 1.:
      ELSE
         E1 =
     1       (  .2677737343+U*
     2       ( 8.6347608925+U*
     3       (18.0590169730+U*
     4       ( 8.5733287401+U))))/
     5       ( 3.9584969228+U*
     6       (21.0996530827+U*
     7       (25.6329561486+U*
     8       ( 9.5733223454+U))))
         EXPINT1 = E1 * EXP(-U) / U
      ENDIF

      RETURN
      END
