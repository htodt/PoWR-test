C***  MAIN PROGRAM ADAPTER  ****************************************************
      SUBROUTINE ADAPTER
C***********************************************************************
C***  THIS PROGRAM IS AN ADAPTER BETWEEN MODEL FILES BASED ON DIFFERENT
C***  NUMBERS OF ATOMIC LEVELS
C***  IT TRANSFORMS POPULATION NUMBERS FROM OLD TO NEW ENERGY LEVELS AS
C***  SPECIFIED IN THE INPUT OPTIONS, THEREBY FILLING UP THE ADDITIONAL
C***  LEVELS WITH POP.NUMBERS CALCULATED FROM BOLTZMANN'S OR SAHA'S EQUATION
C***********************************************************************
      IMPLICIT NONE
 
C***  DEFINE ARRAY DIMENSIONS ******************************************
      INTEGER, PARAMETER :: MAXATOM =          26 
      INTEGER, PARAMETER :: NDIM    =        1560 
      INTEGER, PARAMETER :: NFDIM   = 2*NDIM + 400
      INTEGER, PARAMETER :: MAXKONT =     NFDIM/2 
      INTEGER, PARAMETER :: MAXKODR =        NDIM 
      INTEGER, PARAMETER :: MAXIND  =       20000 
      INTEGER, PARAMETER :: MAXFEIND  =      1500 
      INTEGER, PARAMETER :: NDDIM   =          89 
      INTEGER, PARAMETER :: MAXHIST =        4000 
      INTEGER, PARAMETER :: MAXLEVELCARD =   1000       
 
C***  HANDLING OF DIELECTRONIC RECOMBINATION / AUTOIONIZATION (SUBR. DATOM)
      INTEGER, PARAMETER :: MAXAUTO = 2850 
      COMMON / COMAUTO / LOWAUTO(MAXAUTO),WAUTO(MAXAUTO)
     $                  ,EAUTO(MAXAUTO),AAUTO(MAXAUTO),IONAUTO(MAXAUTO)
     $                  ,KRUDAUT(MAXAUTO)

      INTEGER, DIMENSION(NDIM) :: NCHARG, IONGRND, MAINQN, NOM, NTRANS
      INTEGER, DIMENSION(MAXIND) :: INDLOW, INDNUP
      INTEGER, DIMENSION(MAXKODR) :: KODRNUP, KODRLOW
      INTEGER, DIMENSION(MAXKONT) :: KONTNUP, KONTLOW
      CHARACTER*8 IGAUNT(MAXKONT), KEYCBF(MAXKONT)
      INTEGER, DIMENSION(MAXATOM) :: KODAT, NFIRST, NLAST
      REAL, DIMENSION(NDIM) :: WEIGHT, ELEVEL, EION, ADPWEIGHT
      REAL, DIMENSION(NDIM, NDIM) :: EINST
      REAL, DIMENSION(MAXKONT) :: ALPHA, SEXPO, 
     >                            ADDCON1, ADDCON2, ADDCON3
      REAL, DIMENSION(4, NDIM) :: ALTESUM 
      REAL, DIMENSION(4, MAXIND) :: COCO
      REAL, DIMENSION(MAXATOM) :: ABXYZ, ATMASS, STAGE
      REAL, DIMENSION(NDDIM) :: RNE, RADIUS, ROLD
      REAL, DIMENSION(NDDIM,NDIM) :: POPNUM, POPOLD, POPHELP
      REAL, DIMENSION(MAXATOM,MAXATOM) :: EDGEK, SIGMATHK, SEXPOK

      CHARACTER(MAXHIST*8) :: MODHIST

      CHARACTER(64) :: BUFFER64
      CHARACTER(100) :: MODHEAD, OLDHEAD
      CHARACTER(10), DIMENSION(NDIM) :: LEVEL
      CHARACTER(10), DIMENSION(MAXATOM) :: ELEMENT
      CHARACTER(4) :: KEYCBB(MAXIND)
      CHARACTER(2), DIMENSION(MAXATOM) :: SYMBOL
      LOGICAL :: OLDSTART, NEWATOM, BDEPART, BTAUR
      CHARACTER(80), DIMENSION(MAXLEVELCARD) :: LEVELCARD

      REAL, DIMENSION(NDDIM) :: TAURCONT, TAURCONTOLD
      REAL, DIMENSION(NDDIM,NDIM) :: POPLTE, POPLTE_OLD

      REAL :: WAUTO, EAUTO, AAUTO, VDOPFE, DXFE, XLAM0FE, POPMIN

      INTEGER :: N, ND, NDOLD, NOLD, LAST, IERR, IDUMMY, LASTIND,
     >           NATOM, NAUTO, LOWAUTO, IONAUTO, LASTKON, KRUDAUT,
     >           LASTKDR, LASTFE, NLEVELCARD
  
      INTEGER, EXTERNAL :: IDX

C***  IRON: COMMON BLOCK FOR IRON-SPECIFIC DATA
C***  include "dimblock"
      INTEGER, PARAMETER :: INDEXMAX = 1E7, NFEREADMAX = 3E5    !std
C      INTEGER, PARAMETER :: INDEXMAX = 4E7, NFEREADMAX = 5E5     !vd20
C      INTEGER, PARAMETER :: INDEXMAX = 1E8, NFEREADMAX = 6E5     !xxl

      INTEGER, DIMENSION(MAXFEIND) :: INDRB, INDRF, IFRBSTA, IFRBEND,
     >                                IFENUP, IFELOW
      REAL, DIMENSION(MAXFEIND) :: SIGMAINT
      REAL, DIMENSION(NFEREADMAX) :: FEDUMMY
      REAL, DIMENSION(INDEXMAX) :: SIGMAFE
      COMMON /IRON/ FEDUMMY, INDRB, INDRF, SIGMAFE, IFRBSTA, IFRBEND, 
     >              IFENUP, IFELOW, SIGMAINT
      LOGICAL :: BFEMODEL

C***  Operating system:
      COMMON / COMOS / OPSYS
      CHARACTER(8) :: OPSYS

      CHARACTER(10) :: TIM1, TIM2

C***  File and channel handles (=KANAL)
      INTEGER, PARAMETER :: hOUT = 6        !write to wruniqX.out (stdout)
      INTEGER, PARAMETER :: hCPR = 0        !write to wruniqX.cpr (stderr)
      INTEGER, PARAMETER :: hMODEL = 3      !write to MODEL file      
      INTEGER, PARAMETER :: hHIST = 21      !write to MODHIST file

C***  Link data to identify program version
      CHARACTER(30) :: LINK_DATE
      CHARACTER(10) :: LINK_USER
      CHARACTER(60) :: LINK_HOST
      COMMON / COM_LINKINFO / LINK_DATE, LINK_USER, LINK_HOST
C***  Write Link Data (Program Version) to CPR file
      WRITE (hCPR,'(2A)') '>>> ADAPTER started: Program Version from '
     >                 ,LINK_DATE
      WRITE (hCPR,'(4A)') '>>> created by '
     >                 , LINK_USER(:IDX(LINK_USER))
     >     ,' at host ', LINK_HOST(:IDX(LINK_HOST))

      CALL INSTALL

      IF (OPSYS == 'CRAY') THEN
        CALL CLOCK(TIM1)
      ELSE
        CALL TIME(TIM1)
      ENDIF

C***  NEW ENERGY LEVELS FROM NEW MODEL ATOM: 
      CALL       DATOM (NDIM,N,LEVEL,NCHARG,WEIGHT,ELEVEL,EION,MAINQN,
     $                  EINST,ALPHA,SEXPO,
     $                  ADDCON1, ADDCON2, ADDCON3, 
     $                  IGAUNT,COCO,KEYCBB,ALTESUM,
     $                  INDNUP,INDLOW,LASTIND,MAXIND,MAXATOM,NATOM,
     $                  ELEMENT,SYMBOL,NOM,KODAT,ATMASS,STAGE,
     $                  SIGMATHK,SEXPOK,EDGEK,NFIRST,
     $                  NLAST,NAUTO,MAXAUTO,LOWAUTO,WAUTO,EAUTO,AAUTO,
     $                  IONAUTO,KRUDAUT,KONTNUP,KONTLOW,LASTKON,MAXKONT,
     $                  IONGRND,KODRNUP,KODRLOW,LASTKDR,MAXKODR,KEYCBF,
C***  IRON: ADDITIONAL PARAMETERS FOR IRON-GROUP LINE BLANKETING
     >            'ADAPTER', INDEXMAX, NFEREADMAX, MAXFEIND,
     >             LASTFE, SIGMAFE, INDRB, INDRF,
     >             IFENUP, IFELOW, IFRBSTA, IFRBEND, FEDUMMY,
     >             VDOPFE, DXFE, XLAM0FE, SIGMAINT, BFEMODEL)

C***  DECODING INPUT OPTIONS
      CALL DECADP (OLDSTART, BDEPART, BTAUR, POPMIN, 
     >                LEVELCARD, NLEVELCARD, MAXLEVELCARD)

C***  NO OPTION "OLDSTART" DECODED: ADAPTER IS NOT NECESSARY
      IF (.NOT. OLDSTART) GOTO 999
 
C***  READ OLD AND NEW MODEL FILES
      CALL RMODADP (NDDIM, OLDHEAD, N, NOLD, NDIM, 
     >              NATOM, MODHEAD, ND, NDOLD, ABXYZ, LAST, MODHIST,
     >              RADIUS, ROLD, POPHELP, POPNUM, TAURCONT, 
     >              TAURCONTOLD, POPLTE, POPLTE_OLD, BTAUR)

C***  Decoding the LEVEL cards
      CALL ADATRANS (NTRANS, ADPWEIGHT, N, NOLD, NEWATOM, POPMIN,
     >                LEVELCARD, NLEVELCARD, MAXLEVELCARD)

C***  TRANSFORMING THE POP.NUMBERS  ************************************
      CALL ADAPOP (POPNUM, ND, N, POPOLD, NDOLD, NOLD, NCHARG,
     >          NATOM, ABXYZ, NFIRST, NLAST, RNE, NTRANS, POPLTE, 
     >          BDEPART, ADPWEIGHT, RADIUS, ROLD, POPHELP, TAURCONT,
     >          TAURCONTOLD, POPLTE_OLD, BTAUR, POPMIN)

C***  UPDATING THE MODEL HISTORY  **************************************
      WRITE (UNIT=BUFFER64, FMT=60) OLDHEAD(15:32)
   60 FORMAT ('/     1A. ADAPTER:  POPNUMBERS FROM OLD MODEL ',A18)
      CALL ADDHISTENTRY(MODHIST,-1,MAXHIST,64,BUFFER64)

      !write model history entry into explicit history file
      OPEN (hHIST, FILE='MODHIST', STATUS='UNKNOWN',
     >             ACTION='READWRITE', POSITION='APPEND')
      WRITE (hHIST,FMT='(A)') TRIM(ADJUSTL(BUFFER64))
      CLOSE(hHIST)


C***  PRINTOUT  *******************************************************
      CALL PRIADP (MODHEAD, OLDHEAD, NEWATOM, LEVEL, NTRANS, 
     >   ADPWEIGHT, N, NOLD)

C***  UPDATING THE MODEL FILE  *****************************************
      CALL WRITMS (3,POPNUM,ND*N,'POPNUM  ',-1, IDUMMY, IERR)
      CALL WRITMS (3,RNE,ND,'RNE     ',-1, IDUMMY, IERR)
      CALL WRITMS (3,MODHIST,MAXHIST,'MODHIST ',-1, IDUMMY, IERR)
      CALL CLOSMS (3, IERR)
 

  999 CALL JSYMSET ('G0','0')
 
      CALL STAMP (OPSYS, 'ADAPTER', TIM1)

      STOP 'O.K.'
      END
