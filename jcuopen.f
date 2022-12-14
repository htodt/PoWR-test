
      SUBROUTINE JCUOPEN (IADR9, MAXIND, MODHEAD, JOBNUM)
C**********************************************************************
C***  OPEN THE BACKJCU-FILE AND
C***  CHECK WHETHER THESE DATA EXIST AND BELONG TO THE PRESENT MODEL
C***  CALLED FROM: CMF
C**********************************************************************

      CHARACTER MODHEAD*100,MODEL*100
      DIMENSION IADR9(1)

      CALL OPENMS (9,IADR9,4*MAXIND+4,1, IERR)
      IERR=1
      CALL READMS (9,MODEL,13,'MODEL   ',IERR)
      IF (IERR .LT. 0 .AND. IERR. NE. -10) THEN
            CALL REMARK ('ERROR WHEN READING MODHEAD FROM TAPE 9')
            STOP 'ERROR'
            ENDIF
      IF (IERR .EQ. -10 .OR. MODEL .NE. MODHEAD) THEN
C***     FILE IS NOT APPROPRIATE - CLEAR THE INDEX ARRAY
         DO 6 I=1,4*MAXIND+4
    6    IADR9(I)=0
         CALL WRITMS (9,MODHEAD,13,'MODEL   ',-1, IDUMMY, IERR)
         CALL WRITMS (9,JOBNUM,1,'LASTUPD ',-1, IDUMMY, IERR)
         ELSE
         CALL READMS (9,LASTUPD,1,'LASTUPD ', IERR)
         IF (LASTUPD .GE. JOBNUM) PRINT *,
     $     ' CMF: WARNING - BACKGROUND DATA YOUNGER THAN PRESENT MODEL'
         IF (LASTUPD .LT. JOBNUM-60) PRINT *,
     $     ' CMF: WARNING - BACKGROUND DATA OLDER THAN 60 JOBS'
         ENDIF

      RETURN
      END
