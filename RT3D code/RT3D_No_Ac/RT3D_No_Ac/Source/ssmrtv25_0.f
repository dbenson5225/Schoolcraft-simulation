C
      SUBROUTINE SSM3AL(INSSM,IOUT,ISUM,ISUM2,NCOL,NROW,NLAY,NCOMP,
     & LCIRCH,LCRECH,LCCRCH,LCIEVT,LCEVTR,LCCEVT,MXSS,LCSS,IVER,LCSSMC)
C **********************************************************************
C THIS SUBROUTINE ALLOCATES SPACE FOR ARRAYS NEEDED IN THE SINK & SOURCE
C MIXING (SSM) PACKAGE.
C **********************************************************************
C last modified: 06-23-98
C
      IMPLICIT	NONE
      INTEGER   INSSM,IOUT,ISUM,ISUM2,NCOL,NROW,NLAY,NCOMP,
     &		LCIRCH,LCRECH,LCCRCH,LCIEVT,LCEVTR,LCCEVT,
     &          MXSS,LCSS,ISUMX,ISUMIX,NCR,I,ISOLD,ISOLD2,IVER,LCSSMC
      LOGICAL	FWEL,FDRN,FRCH,FEVT,FRIV,FGHB,LTMP(6)
      COMMON   /FC/FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
C
C--PRINT PACKAGE NAME AND VERSION NUMBER
      WRITE(IOUT,1000) INSSM
 1000 FORMAT(1X,'SSM3 -- SINK & SOURCE MIXING PACKAGE,',
     & ' VER DoD_3.0, JUNE 1998, INPUT READ FROM UNIT',I3)
C
C--READ AND PRINT FLAGS INDICATING WHICH SINK/SOURCE OPTIONS
C--ARE USED IN FLOW MODEL
      IF(IVER.EQ.1) THEN
	READ(INSSM,'(6L2)') FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
      ELSEIF(IVER.EQ.2) THEN
	READ(INSSM,'(6L2)') (LTMP(I),I=1,6)
	IF((LTMP(1).NEQV.FWEL).OR.(LTMP(2).NEQV.FDRN).OR.
     &	   (LTMP(3).NEQV.FRCH).OR.(LTMP(4).NEQV.FEVT).OR.
     &	   (LTMP(5).NEQV.FRIV).OR.(LTMP(6).NEQV.FGHB)) THEN
	  WRITE(*,1010)
	ENDIF
      ENDIF
      IF(FWEL.OR.FDRN.OR.FRCH.OR.FEVT.OR.FRIV.OR.FGHB)
     & WRITE(IOUT,1020)
      I=0
      IF(FWEL) THEN
	I=I+1
	WRITE(IOUT,1030) I
      ENDIF
      IF(FDRN) THEN
	I=I+1
	WRITE(IOUT,1040) I
      ENDIF
      IF(FRCH) THEN
	I=I+1
	WRITE(IOUT,1042) I
      ENDIF
      IF(FEVT) THEN
	I=I+1
	WRITE(IOUT,1044) I
      ENDIF
      IF(FRIV) THEN
	I=I+1
	WRITE(IOUT,1050) I
      ENDIF
      IF(FGHB) THEN
	I=I+1
	WRITE(IOUT,1060) I
      ENDIF
 1010 FORMAT(/1X,'WARNING: SPECIFIED FLOW SINK/SOURCE PACKAGES ',
     & 'NOT CONSISTENT'/1X,'WITH THOSE IN FLOW-TRANSPORT LINK FILE.')
 1020 FORMAT(1X,'MAJOR STRESS COMPONENTS PRESENT IN THE FLOW MODEL:')
 1030 FORMAT(1X,I2,2X,'WELL')
 1040 FORMAT(1X,I2,2X,'DRAIN')
 1042 FORMAT(1X,I2,2X,'RECHARGE')
 1044 FORMAT(1X,I2,2X,'EVAPOTRANSPIRATION')
 1050 FORMAT(1X,I2,2X,'RIVER/STREAM')
 1060 FORMAT(1X,I2,2X,'GENERAL-HEAD-DEPENDENT BOUNDARY')
C
C--READ AND PRINT MAXIMUM NUMBER OF
C--POINT SINKS/SOURCES PRESENT IN THE FLOW MODEL
      READ(INSSM,'(I10)') MXSS
      WRITE(IOUT,1080) MXSS
 1080 FORMAT(1X,'MAXIMUM NUMBER OF POINT SINKS/SOURCES =',I8)
C
C--ALLOCATE SPACE FOR ARRAYS
      ISOLD=ISUM
      ISOLD2=ISUM2
      NCR=NCOL*NROW
C
C--INTEGER ARRAYS
      LCIRCH=ISUM2
      IF(FRCH) ISUM2=ISUM2+NCR
      LCIEVT=ISUM2
      IF(FEVT) ISUM2=ISUM2+NCR
C
C--REAL ARRAYS
      LCRECH=ISUM
      IF(FRCH) ISUM=ISUM+NCR
      LCCRCH=ISUM
      IF(FRCH) ISUM=ISUM+NCR * NCOMP
      LCEVTR=ISUM
      IF(FEVT) ISUM=ISUM+NCR
      LCCEVT=ISUM
      IF(FEVT) ISUM=ISUM+NCR * NCOMP
      LCSS=ISUM
      ISUM=ISUM+6*MXSS

      LCSSMC=ISUM
      ISUM=ISUM+NCOMP*MXSS
C
C--CHECK HOW MANY ELEMENTS OF ARRAYS X AND IX ARE USED
      ISUMX=ISUM-ISOLD
      ISUMIX=ISUM2-ISOLD2
      WRITE(IOUT,1090) ISUMX,ISUMIX
 1090 FORMAT(1X,I10,' ELEMENTS OF THE  X ARRAY USED BY THE SSM PACKAGE'
     & /1X,I10,' ELEMENTS OF THE IX ARRAY BY THE SSM PACKAGE'/)
C
C--NORMAL RETURN
      RETURN
      END
C
C
      SUBROUTINE SSM3RP(IN,IOUT,KPER,NCOL,NROW,NLAY,NCOMP,ICBUND,CNEW,
     & CRCH,CEVT,MXSS,NSS,SS,SSMC,SSMC0)
C ********************************************************************
C THIS SUBROUTINE READS CONCENTRATIONS OF SOURCES OR SINKS NEEDED BY
C THE SINK AND SOURCE MIXING (SSM) PACKAGE.
C ********************************************************************
C last modified: 06-23-98
C

      USE SSMDECAY_ARRAY
      IMPLICIT	NONE
      INTEGER   IN,IOUT,KPER,NCOL,NROW,NLAY,NCOMP,ICBUND,
     &          MXSS,NSS,JJ,II,KK,NUM,IQ,INCRCH,INCEVT,NTMP,INDEX,
     &          ierr
      REAL      CRCH,CEVT,SS,SSMC,CSS,CNEW,SSMC0
      LOGICAL	FWEL,FDRN,FRIV,FGHB,FRCH,FEVT
      CHARACTER ANAME*24,TYPESS(-2:5)*15
      DIMENSION SS(6,MXSS),SSMC(NCOMP,MXSS),CRCH(NCOL,NROW,NCOMP),
     &          CEVT(NCOL,NROW,NCOMP),SSMC0(NCOMP,MXSS),
     &          ICBUND(NCOL,NROW,NLAY,NCOMP),CNEW(NCOL,NROW,NLAY,NCOMP)
      COMMON   /FC/FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
	INTEGER*4 RESULT
C
C--INITIALIZE.
      TYPESS(-2)='DECAYING CONC. '
      TYPESS(-1)='CONSTANT CONC. '
      TYPESS(1)='CONSTANT HEAD  '
      TYPESS(2)='WELL           '
      TYPESS(3)='DRAIN          '
      TYPESS(4)='RIVER          '
      TYPESS(5)='HEAD DEP BOUND '
C
C--READ CONCENTRATION OF DIFFUSIVE SOURCES/SINKS (RECHARGE/E.T.)
C--FOR CURRENT STRESS PERIOD IF THEY ARE SIMULATED IN FLOW MODEL
      IF(.NOT.FRCH) GOTO 10
C
C--READ FLAG INCRCH INDICATING HOW TO READ RECHARGE CONCENTRATION
      READ(IN,'(I10)') INCRCH
C
C--IF INCRCH < 0, CONCENTRATIN REUSED FROM LAST STRESS PERIOD
      IF(INCRCH.LT.0) THEN
	WRITE(IOUT,1)
	GOTO 10
      ENDIF
    1 FORMAT(/1X,'CONCENTRATION OF RECHARGE FLUXES',
     & ' REUSED FROM LAST STRESS PERIOD')
C
C--IF INCRCH >= 0, READ AN ARRAY
C--CONTAING CONCENTRATION OF RECHARGE FLUX [CRCH]
      WRITE(IOUT,2) KPER
      ANAME='RECH. CONC. COMP. NO.'
      DO INDEX=1,NCOMP
	WRITE(ANAME(19:21),'(I3.2)') INDEX
	CALL RARRAY(CRCH(1,1,INDEX),ANAME,NROW,NCOL,0,IN,IOUT)
      ENDDO
    2 FORMAT(/1X,'CONCENTRATION OF RECHARGE FLUXES',
     & ' WILL BE READ IN STRESS PERIOD',I3)
C
C--READ CONCENTRAION OF EVAPOTRANSPIRATION FLUX
   10 IF(.NOT.FEVT) GOTO 20
C
      IF(KPER.EQ.1) THEN
        DO INDEX=1,NCOMP
          DO II=1,NROW
            DO JJ=1,NCOL
              CEVT(JJ,II,INDEX)=-1.E-30
            ENDDO
          ENDDO
        ENDDO
      ENDIF
      READ(IN,'(I10)') INCEVT
      IF(INCEVT.LT.0) THEN
	WRITE(IOUT,11)
	GOTO 20
      ENDIF
   11 FORMAT(/1X,'CONCENTRATION OF E. T. FLUXES',
     & ' REUSED FROM LAST STRESS PERIOD')
C
      WRITE(IOUT,12) KPER
      ANAME='E. T. CONC. COMP. NO.'
      DO INDEX=1,NCOMP
	WRITE(ANAME(19:21),'(I3.2)') INDEX
	CALL RARRAY(CEVT(1,1,INDEX),ANAME,NROW,NCOL,0,IN,IOUT)
      ENDDO
   12 FORMAT(/1X,'CONCENTRATION OF E. T. FLUXES',
     & ' WILL BE READ IN STRESS PERIOD',I3)
C
C--READ AND ECHO POINT SINKS/SOURCES OF SPECIFIED CONCENTRATIONS
   20 READ(IN,'(I10)') NTMP
      IF(NTMP.GT.MXSS) THEN
	WRITE(*,30)
C-------EMRL JIG
      call stopfile
C-------EMRL JIG
	STOP
      ELSEIF(NTMP.LT.0) THEN
	WRITE(IOUT,40)
	RETURN
      ELSEIF(NTMP.EQ.0) THEN
	WRITE(IOUT,50) NTMP,KPER
	NSS=0
	RETURN
      ELSE
	NSS=NTMP
      ENDIF
      WRITE(IOUT,60)
      DO NUM=1,NSS

        IF(NCOMP.EQ.1) THEN
          READ(IN,'(3I10,F10.0,I10)') KK,II,JJ,CSS,IQ
          SSMC(1,NUM)=CSS
          if (iq .eq. -2) then                                                    
             if (ALLOCATED(ssmcdecay)) then                                       
                read (in,*,ERR=101,END=101) ssmcdecay(jj,ii,kk,1)                 
             else                                                                 
                ALLOCATE (ssmcdecay(ncol,nrow,nlay,ncomp),STAT=ierr)              
                ssmcdecay = 0.0 !whole array initialization                       
                if (ierr.NE.0) then                                               
                 write(*,*) 'Not enough memory for source decay array'            
C-------EMRL JIG                                                                  
                 call stopfile                                                    
C-------EMRL JIG                                                                  
                 stop                                                             
                end if                                                            
                read (in,*,ERR=101,END=101)ssmcdecay(jj,ii,kk,1)                  
             end if                                                               
          end if                                                                  
        ELSE
          READ(IN,*,ERR=100,END=100) 
     &               KK,II,JJ,CSS,IQ,(SSMC(INDEX,NUM),INDEX=1,NCOMP)
          
          Do INDEX=1,ncomp
              SSMC0(INDEX,NUM)=SSMC(INDEX,NUM)
          End Do
          
          if (iq .eq. -2) then
             if (ALLOCATED(ssmcdecay)) then
                read (in,*,ERR=101,END=101) 
     &                (ssmcdecay(jj,ii,kk,index),index=1,ncomp)
             else
                ALLOCATE (ssmcdecay(ncol,nrow,nlay,ncomp),STAT=ierr)
                ssmcdecay = 0.0 !whole array initialization
                if (ierr.NE.0) then
                 write(*,*) 'Not enough memory for source decay array'
C-------EMRL JIG
                 call stopfile
C-------EMRL JIG
                 stop
                end if
                read (in,*,ERR=101,END=101) 
     &                (ssmcdecay(jj,ii,kk,index),index=1,ncomp)
             end if
          end if
	  END IF
        GOTO 103
100     WRITE (*,*) "Point source sink record# D8 has version-1 data"
	  WRITE (*,*) "CSS() should have ""ncomp"" values (see manual)"
	  GOTO 102
101     WRITE (*,*) "Point source sink record# D8a is missing"
C-------EMRL JIG
102        call stopfile
C-------EMRL JIG
        STOP 
103     CONTINUE

        IF(IQ.EQ.-1) THEN
          DO INDEX=1,NCOMP
            IF(SSMC(INDEX,NUM).GE.0) THEN
              CNEW(JJ,II,KK,INDEX)=SSMC(INDEX,NUM)
              ICBUND(JJ,II,KK,INDEX)=-ABS(ICBUND(JJ,II,KK,INDEX))
            ENDIF
          ENDDO
        elseif (iq == -2) then
           do index = 1, ncomp
              if (ssmc(index,num) .ge.0) then
                 cnew(jj,ii,kk,index) = ssmc(index,num)
                 icbund(jj,ii,kk,index) = -9 ! tag the decaying constant condition
              endif
            enddo
        ELSEIF(IQ.LT.-3.OR.IQ.GT.5) THEN
	  WRITE(*,80)
C-------EMRL JIG
        call stopfile
C-------EMRL JIG
	  STOP
        ENDIF
	  SS(1,NUM)=KK
	  SS(2,NUM)=II
	  SS(3,NUM)=JJ
	  SS(4,NUM)=CSS
	  SS(6,NUM)=IQ

        DO INDEX=1,NCOMP
          CSS=SSMC(INDEX,NUM)
          IF(CSS.GT.0 .OR. ICBUND(JJ,II,KK,INDEX).LT.0)
     &     WRITE(IOUT,70) NUM,KK,II,JJ,CSS,TYPESS(IQ),INDEX
        ENDDO

      ENDDO
   30 FORMAT(/1X,'ERROR: MAXIMUM NUMBER OF POINT SINKS/SOURCES',
     & ' EXCEEDED'/1X,'INCREASE [MXSS] IN SSM INPUT FILE')
   40 FORMAT(/1X,'POINT SINKS/SOURCES OF SPECIFIED CONCENTRATION',
     & ' REUSED FROM LAST STRESS PERIOD')
   50 FORMAT(/1X,'NO. OF POINT SINKS/SOURCES OF SPECIFIED',
     & ' CONCONCENTRATIONS =',I5,' IN STRESS PERIOD',I3)
   60 FORMAT(/5X,'  NO    LAYER   ROW   COLUMN   CONCENTRATION',
     & '       TYPE            COMPONENT')
   70 FORMAT(3X,4(I5,3X),1X,G15.7,5X,A15,I6)
   80 FORMAT(/1X,'ERROR: INVALID CODE FOR POINT SINK/SOURCE TYPE',
     & /1X,'IN THE SSM INPUT FILE')
C
C--RETURN
      RETURN
      END
C
C
      SUBROUTINE SSM3SV(NCOL,NROW,NLAY,NCOMP,ICOMP,ICBUND,PRSITY,
     & DELR,DELC,DH,RETA,IRCH,RECH,CRCH,IEVT,EVTR,CEVT,MXSS,NTSS,
     & NSS,SS,SSMC,QSTO,CNEW,COLD,DTRANS,MIXELM,ISS,
     & TMASIO,RMASIO,TMASS)
C ******************************************************************
C THIS SUBROUTINE CALCULATES THE CHANGE IN CELL CONCENTRATIONS
C DUE TO FLUID SOURCE AND SINK MIXING.
C ******************************************************************
C last modified: 06-23-98
C
      IMPLICIT	NONE
      INTEGER   NCOL,NROW,NLAY,NCOMP,ICOMP,ICBUND,IRCH,IEVT,
     &          MXSS,NTSS,NSS,NUM,IQ,K,I,J,MIXELM,ISS
      REAL      PRSITY,RETA,DTRANS,RECH,CRCH,EVTR,CEVT,SS,SSMC,
     &          CNEW,COLD,CTMP,QSS,DCSSM,TMASIO,RMASIO,DELR,DELC,DH,
     &          QSTO,TMASS
      LOGICAL	FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
      DIMENSION ICBUND(NCOL,NROW,NLAY,NCOMP),SS(6,MXSS),
     &          SSMC(NCOMP,MXSS),RECH(NCOL,NROW),IRCH(NCOL,NROW),
     &          CRCH(NCOL,NROW,NCOMP),EVTR(NCOL,NROW),IEVT(NCOL,NROW),
     &          CEVT(NCOL,NROW,NCOMP),RETA(NCOL,NROW,NLAY,NCOMP),
     &          PRSITY(NCOL,NROW,NLAY),COLD(NCOL,NROW,NLAY,NCOMP),
     &          CNEW(NCOL,NROW,NLAY,NCOMP),DELR(NCOL),DELC(NROW),
     &          DH(NCOL,NROW,NLAY),QSTO(NCOL,NROW,NLAY),
     &          TMASIO(20,2,NCOMP),RMASIO(20,2,NCOMP),TMASS(4,NCOMP)
      COMMON   /FC/FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
C
C--COPY CONCENTRATION OF ICOMP FROM [SSMC] TO [SS]
      IF(NCOMP.GT.1.AND.NSS.GT.0) THEN
        DO NUM=1,NSS
          SS(4,NUM)=SSMC(ICOMP,NUM)
        ENDDO
      ENDIF
C
C--IF A MIXED EULERIAN-LAGRANGIAN SCHEME NOT USED, GO TO
C--FINITE DIFFERENCE ROUTINE [SSSM3F].
      IF(MIXELM.LE.0) GOTO 350
C
C--TRANSIENT GROUNDWATER STORAGE TERM
      IF(ISS.NE.0) GOTO 50
C
      DO K=1,NLAY
	DO I=1,NROW
	  DO J=1,NCOL
            IF(ICBUND(J,I,K,ICOMP).LE.0) CYCLE
            CTMP=COLD(J,I,K,ICOMP)
            IF(QSTO(J,I,K).GT.0) THEN
              RMASIO(19,1,ICOMP)=RMASIO(19,1,ICOMP)
     &         +QSTO(J,I,K)*CTMP*DTRANS*DELR(J)*DELC(I)*DH(J,I,K)
            ELSE
              RMASIO(19,2,ICOMP)=RMASIO(19,2,ICOMP)
     &         +QSTO(J,I,K)*CTMP*DTRANS*DELR(J)*DELC(I)*DH(J,I,K)
            ENDIF
	  ENDDO
	ENDDO
      ENDDO
C
C--DIFFUSIVE SINK/SOURCE TERMS
C--(RECHARGE)
   50 IF(.NOT.FRCH) GOTO 100
C
      DO I=1,NROW
	DO J=1,NCOL
C
	  K=IRCH(J,I)
          IF(K.EQ.0 .OR. ICBUND(J,I,K,ICOMP).LE.0) CYCLE
          CTMP=CRCH(J,I,ICOMP)
	  IF(RECH(J,I).LT.0.) THEN
            CTMP=CNEW(J,I,K,ICOMP)
	  ELSE
            DCSSM=RECH(J,I)*(CTMP-CNEW(J,I,K,ICOMP))/
     &         (RETA(J,I,K,ICOMP)*PRSITY(J,I,K))*DTRANS
            CNEW(J,I,K,ICOMP)=CNEW(J,I,K,ICOMP)+DCSSM
	  ENDIF
C
C--ACCUMULATE MASS IN OR OUT THROUGH THE SOURCE OR SINK
	  IF(RECH(J,I).GT.0) THEN
            RMASIO(7,1,ICOMP)=RMASIO(7,1,ICOMP)+RECH(J,I)*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ELSE
            RMASIO(7,2,ICOMP)=RMASIO(7,2,ICOMP)+RECH(J,I)*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ENDIF
        ENDDO
      ENDDO
C
C--(EVAPOTRANSPIRATION)
  100 IF(.NOT.FEVT) GOTO 200
C
      DO I=1,NROW
	DO J=1,NCOL
	  K=IEVT(J,I)
          IF(K.EQ.0 .OR. ICBUND(J,I,K,ICOMP).LE.0) CYCLE
          CTMP=CEVT(J,I,ICOMP)
          IF(EVTR(J,I).LT.0.AND.CTMP.LT.0) THEN
            CTMP=CNEW(J,I,K,ICOMP)
          ELSEIF(EVTR(J,I).GE.0.AND.CTMP.LT.0) THEN
            CTMP=0.
          ENDIF
          DCSSM=EVTR(J,I)*(CTMP-CNEW(J,I,K,ICOMP))/
     &     (RETA(J,I,K,ICOMP)*PRSITY(J,I,K))*DTRANS
          CNEW(J,I,K,ICOMP)=CNEW(J,I,K,ICOMP)+DCSSM
C
C--ACCUMULATE MASS IN OR OUT THROUGH THE SOURCE OR SINK
	  IF(EVTR(J,I).GT.0) THEN
            RMASIO(8,1,ICOMP)=RMASIO(8,1,ICOMP)+EVTR(J,I)*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ELSE
            RMASIO(8,2,ICOMP)=RMASIO(8,2,ICOMP)+EVTR(J,I)*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ENDIF
        ENDDO
      ENDDO
C
C--POINT SINK/SOURCE TERMS (CONST-HEAD, WELL, DRAIN, RIVER & G-H-B)
  200 DO NUM=1,NTSS
	K=SS(1,NUM)
	I=SS(2,NUM)
	J=SS(3,NUM)
	CTMP=SS(4,NUM)
        QSS=SS(5,NUM)
	IQ=SS(6,NUM)
        IF(ICBUND(J,I,K,ICOMP).GT.0.AND.IQ.GT.0) THEN
	  IF(QSS.LT.0) THEN
            CTMP=CNEW(J,I,K,ICOMP)
	  ELSE
            DCSSM=QSS*(CTMP-CNEW(J,I,K,ICOMP))/
     &       (RETA(J,I,K,ICOMP)*PRSITY(J,I,K))*DTRANS
            CNEW(J,I,K,ICOMP)=CNEW(J,I,K,ICOMP)+DCSSM
	  ENDIF
C
C--ACCUMULATE MASS IN OR OUT THROUGH THE SOURCE OR SINK
	  IF(QSS.GT.0) THEN
            RMASIO(IQ,1,ICOMP)=RMASIO(IQ,1,ICOMP)+QSS*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ELSE
            RMASIO(IQ,2,ICOMP)=RMASIO(IQ,2,ICOMP)+QSS*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ENDIF
	ENDIF
      ENDDO
C
      GOTO 400
C
  350 CALL SSSM3F(NCOL,NROW,NLAY,ICBUND(1,1,1,ICOMP),PRSITY,
     & DELR,DELC,DH,RETA(1,1,1,ICOMP),DTRANS,IRCH,RECH,CRCH(1,1,ICOMP),
     & IEVT,EVTR,CEVT(1,1,ICOMP),MXSS,NTSS,NSS,SS,
     & CNEW(1,1,1,ICOMP),COLD(1,1,1,ICOMP),QSTO,ISS,
     & TMASIO(1,1,ICOMP),RMASIO(1,1,ICOMP),TMASS(1,ICOMP))
C
C--RETURN
  400 RETURN
      END
C
C
      SUBROUTINE SSSM3F(NCOL,NROW,NLAY,ICBUND,PRSITY,DELR,DELC,DH,
     & RETA,DTRANS,IRCH,RECH,CRCH,IEVT,EVTR,CEVT,MXSS,NTSS,NSS,SS,
     & CNEW,COLD,QSTO,ISS,TMASIO,RMASIO,TMASS)
C ******************************************************************
C THIS SUBROUTINE CALCULATES THE CHANGE IN CELL CONCENTRATIONS
C DUE TO FLUID SOURCE/SINK MIXING WITH THE FINITE DIFFERENCE SCHEME.
C ******************************************************************
C last modified: 06-23-98
C
      IMPLICIT	NONE
      INTEGER	NCOL,NROW,NLAY,ICBUND,IRCH,IEVT,MXSS,NTSS,NSS,
     &		NUM,IQ,K,I,J,ISS
      REAL	PRSITY,RETA,DTRANS,RECH,CRCH,EVTR,CEVT,SS,CNEW,COLD,
     &          CTMP,QSS,DCSSM,TMASIO,RMASIO,DELR,DELC,DH,
     &		QSTO,DCSTO,TMASS
      LOGICAL	FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
      DIMENSION ICBUND(NCOL,NROW,NLAY),SS(6,MXSS),
     &		RECH(NCOL,NROW),IRCH(NCOL,NROW),CRCH(NCOL,NROW),
     &		EVTR(NCOL,NROW),IEVT(NCOL,NROW),CEVT(NCOL,NROW),
     &		RETA(NCOL,NROW,NLAY),PRSITY(NCOL,NROW,NLAY),
     &          COLD(NCOL,NROW,NLAY),
     &		CNEW(NCOL,NROW,NLAY),DELR(NCOL),DELC(NROW),
     &          DH(NCOL,NROW,NLAY),QSTO(NCOL,NROW,NLAY),
     &          TMASIO(20,2),RMASIO(20,2),TMASS(4)
      COMMON   /FC/FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
C
C--TRANSIENT FLUID STORAGE TERM
      IF(ISS.NE.0) GOTO 50
C
      DO K=1,NLAY
	DO I=1,NROW
	  DO J=1,NCOL
            IF(ICBUND(J,I,K).LE.0) CYCLE
            CTMP=COLD(J,I,K)
            DCSTO=QSTO(J,I,K)/(RETA(J,I,K)*PRSITY(J,I,K))*CTMP*DTRANS
            CNEW(J,I,K)=CNEW(J,I,K)+DCSTO
            IF(QSTO(J,I,K).GT.0) THEN
              RMASIO(19,1)=RMASIO(19,1)+QSTO(J,I,K)*CTMP*DTRANS*
     &         DELR(J)*DELC(I)*DH(J,I,K)
            ELSE
              RMASIO(19,2)=RMASIO(19,2)+QSTO(J,I,K)*CTMP*DTRANS*
     &         DELR(J)*DELC(I)*DH(J,I,K)
            ENDIF
	  ENDDO
	ENDDO
      ENDDO
C
C--DIFFUSIVE SINK/SOURCE TERMS (RECHARGE & E. T.)
   50 IF(.NOT.FRCH) GOTO 100
C
      DO I=1,NROW
	DO J=1,NCOL
	  K=IRCH(J,I)
          IF(K.EQ.0 .OR. ICBUND(J,I,K).LE.0) CYCLE
	  CTMP=CRCH(J,I)
	  IF(RECH(J,I).LT.0) CTMP=COLD(J,I,K)
	  DCSSM=RECH(J,I)/(RETA(J,I,K)*PRSITY(J,I,K))*CTMP*DTRANS
	  CNEW(J,I,K)=CNEW(J,I,K)+DCSSM
	  IF(RECH(J,I).GT.0) THEN
	    RMASIO(7,1)=RMASIO(7,1)+RECH(J,I)*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ELSE
	    RMASIO(7,2)=RMASIO(7,2)+RECH(J,I)*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ENDIF
   10	ENDDO
      ENDDO
C
  100 IF(.NOT.FEVT) GOTO 200
      DO I=1,NROW
	DO J=1,NCOL
	  K=IEVT(J,I)
          IF(K.EQ.0 .OR. ICBUND(J,I,K).LE.0) CYCLE
	  CTMP=CEVT(J,I)
          IF(EVTR(J,I).LT.0.AND.CTMP.LT.0) THEN
            CTMP=COLD(J,I,K)
          ELSEIF(EVTR(J,I).GE.0.AND.CTMP.LT.0) THEN
            CTMP=0.
          ENDIF
	  DCSSM=EVTR(J,I)/(RETA(J,I,K)*PRSITY(J,I,K))*CTMP*DTRANS
	  CNEW(J,I,K)=CNEW(J,I,K)+DCSSM
	  IF(EVTR(J,I).GT.0) THEN
	    RMASIO(8,1)=RMASIO(8,1)+EVTR(J,I)*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ELSE
	    RMASIO(8,2)=RMASIO(8,2)+EVTR(J,I)*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ENDIF
        ENDDO
      ENDDO
C
C--POINT SINK/SOURCE TERMS (CONST-HEAD, WELL, DRAIN, RIVER & G-H-B)
  200 DO NUM=1,NTSS
	K=SS(1,NUM)
	I=SS(2,NUM)
	J=SS(3,NUM)
	CTMP=SS(4,NUM)
	QSS=SS(5,NUM)
	IQ=SS(6,NUM)
	IF(ICBUND(J,I,K).GT.0.AND.IQ.GT.0) THEN
	  IF(QSS.LT.0) CTMP=COLD(J,I,K)
	  DCSSM=QSS/(RETA(J,I,K)*PRSITY(J,I,K))*CTMP*DTRANS
	  CNEW(J,I,K)=CNEW(J,I,K)+DCSSM
	  IF(QSS.GT.0) THEN
	    RMASIO(IQ,1)=RMASIO(IQ,1)+QSS*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ELSE
	    RMASIO(IQ,2)=RMASIO(IQ,2)+QSS*CTMP*DTRANS*
     &	     DELR(J)*DELC(I)*DH(J,I,K)
	  ENDIF
	ENDIF
      ENDDO
C
C--RETURN
      RETURN
      END
C
C
      SUBROUTINE SSM3FM(NCOL,NROW,NLAY,NCOMP,ICOMP,ICBUND,DELR,DELC,
     & DH,IRCH,RECH,CRCH,IEVT,EVTR,CEVT,MXSS,NTSS,SS,SSMC,
     & QSTO,CNEW,ISS,A,RHS,NODES,UPDLHS,MIXELM)
C ******************************************************************
C THIS SUBROUTINE FORMULATES MATRIX COEFFICIENTS FOR THE SINK/
C SOURCE TERMS IF THE IMPLICIT SCHEME IS USED.
C ******************************************************************
C last modified: 06-23-98
C
      IMPLICIT  NONE
      INTEGER   NCOL,NROW,NLAY,NCOMP,ICOMP,ICBUND,IRCH,IEVT,MXSS,
     &          NTSS,NUM,IQ,K,I,J,ISS,N,NODES,MIXELM
      REAL      CNEW,RECH,CRCH,EVTR,CEVT,SS,SSMC,
     &          CTMP,QSS,DELR,DELC,DH,QSTO,A,RHS
      LOGICAL   FWEL,FDRN,FRCH,FEVT,FRIV,FGHB,UPDLHS
      DIMENSION ICBUND(NCOL,NROW,NLAY,NCOMP),SS(6,MXSS),
     &          SSMC(NCOMP,MXSS),RECH(NCOL,NROW),IRCH(NCOL,NROW),
     &          CRCH(NCOL,NROW,NCOMP),EVTR(NCOL,NROW),
     &          IEVT(NCOL,NROW),CEVT(NCOL,NROW,NCOMP),
     &          DELR(NCOL),DELC(NROW),CNEW(NCOL,NROW,NLAY,NCOMP),
     &          DH(NCOL,NROW,NLAY),QSTO(NCOL,NROW,NLAY),
     &          A(NODES),RHS(NODES)
      COMMON   /FC/FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
C
C--FORMULATE [A] AND [RHS] MATRICES FOR EULERIAN SCHEMES
      IF(MIXELM.GT.0) GOTO 1000
C
C--TRANSIENT FLUID STORAGE TERM
      IF(ISS.EQ.0 .AND. UPDLHS) THEN
        DO K=1,NLAY
          DO I=1,NROW
            DO J=1,NCOL
              IF(ICBUND(J,I,K,ICOMP).GT.0) THEN
                N=(K-1)*NCOL*NROW+(I-1)*NCOL+J
                A(N)=A(N)+QSTO(J,I,K)*DELR(J)*DELC(I)*DH(J,I,K)
              ENDIF
            ENDDO
          ENDDO
        ENDDO
      ENDIF
C
C--AREAL SINK/SOURCE TERMS (RECHARGE & E. T.)
      IF(.NOT.FRCH) GOTO 10
      DO I=1,NROW
        DO J=1,NCOL
          K=IRCH(J,I)
          IF(K.GT.0 .AND. ICBUND(J,I,K,ICOMP).GT.0) THEN
            N=(K-1)*NCOL*NROW+(I-1)*NCOL+J
            IF(RECH(J,I).LT.0) THEN
              IF(UPDLHS) A(N)=A(N)+RECH(J,I)*DELR(J)*DELC(I)*DH(J,I,K)
            ELSE
              RHS(N)=RHS(N)
     &         -RECH(J,I)*CRCH(J,I,ICOMP)*DELR(J)*DELC(I)*DH(J,I,K)
            ENDIF
          ENDIF
        ENDDO
      ENDDO
C
   10 IF(.NOT.FEVT) GOTO 20
      DO I=1,NROW
        DO J=1,NCOL
          K=IEVT(J,I)
          IF(K.GT.0 .AND. ICBUND(J,I,K,ICOMP).GT.0) THEN
            N=(K-1)*NCOL*NROW+(I-1)*NCOL+J
            IF(EVTR(J,I).LT.0.AND.CEVT(J,I,ICOMP).LT.0) THEN
              IF(UPDLHS) A(N)=A(N)+EVTR(J,I)*DELR(J)*DELC(I)*DH(J,I,K)
            ELSEIF(CEVT(J,I,ICOMP).GT.0) THEN
              RHS(N)=RHS(N)
     &         -EVTR(J,I)*CEVT(J,I,ICOMP)*DELR(J)*DELC(I)*DH(J,I,K)
            ENDIF
          ENDIF
        ENDDO
      ENDDO
C
C--POINT SINK/SOURCE TERMS (CONST-HEAD, WELL, DRAIN, RIVER & G-H-B)
   20 DO NUM=1,NTSS
        K=SS(1,NUM)
        I=SS(2,NUM)
        J=SS(3,NUM)
        CTMP=SS(4,NUM)
        IF(NCOMP.GT.1) CTMP=SSMC(ICOMP,NUM)
        QSS=SS(5,NUM)
        IQ=SS(6,NUM)
        IF(ICBUND(J,I,K,ICOMP).GT.0.AND.IQ.GT.0) THEN
          N=(K-1)*NCOL*NROW+(I-1)*NCOL+J
          IF(QSS.LT.0) THEN
            IF(UPDLHS) A(N)=A(N)+QSS*DELR(J)*DELC(I)*DH(J,I,K)
          ELSE
            RHS(N)=RHS(N)-QSS*CTMP*DELR(J)*DELC(I)*DH(J,I,K)
          ENDIF
        ENDIF
      ENDDO
C
C--DONE WITH EULERIAN SCHEMES
      GOTO 2000
C
C--FORMULATE [A] AND [RHS] MATRICES FOR EULERIAN-LAGRANGIAN SCHEMES
 1000 CONTINUE
C
C--AREAL SINK/SOURCE TERMS (RECHARGE & E. T.)
      IF(.NOT.FRCH) GOTO 30
      DO I=1,NROW
        DO J=1,NCOL
          K=IRCH(J,I)
          IF(K.GT.0 .AND. ICBUND(J,I,K,ICOMP).GT.0
     &              .AND. RECH(J,I).GT.0) THEN
            N=(K-1)*NCOL*NROW+(I-1)*NCOL+J
            IF(UPDLHS) A(N)=A(N)-RECH(J,I)*DELR(J)*DELC(I)*DH(J,I,K)
            RHS(N)=RHS(N)
     &       -RECH(J,I)*CRCH(J,I,ICOMP)*DELR(J)*DELC(I)*DH(J,I,K)
          ENDIF
        ENDDO
      ENDDO
C
   30 IF(.NOT.FEVT) GOTO 40
      DO I=1,NROW
        DO J=1,NCOL
          K=IEVT(J,I)
          IF(K.GT.0 .AND. ICBUND(J,I,K,ICOMP).GT.0) THEN
            N=(K-1)*NCOL*NROW+(I-1)*NCOL+J
            IF(EVTR(J,I).LT.0.AND.CEVT(J,I,ICOMP).LT.0) CYCLE
            IF(UPDLHS) A(N)=A(N)-EVTR(J,I)*DELR(J)*DELC(I)*DH(J,I,K)
            IF(CEVT(J,I,ICOMP).GT.0) RHS(N)=RHS(N)
     &       -EVTR(J,I)*CEVT(J,I,ICOMP)*DELR(J)*DELC(I)*DH(J,I,K)
          ENDIF
        ENDDO
      ENDDO
C
C--POINT SINK/SOURCE TERMS (CONST-HEAD, WELL, DRAIN, RIVER & G-H-B)
   40 DO NUM=1,NTSS
        K=SS(1,NUM)
        I=SS(2,NUM)
        J=SS(3,NUM)
        CTMP=SS(4,NUM)
        IF(NCOMP.GT.1) CTMP=SSMC(ICOMP,NUM)
        QSS=SS(5,NUM)
        IQ=SS(6,NUM)
        IF(ICBUND(J,I,K,ICOMP).GT.0.AND.IQ.GT.0.AND.QSS.GT.0) THEN
          N=(K-1)*NCOL*NROW+(I-1)*NCOL+J
          IF(UPDLHS) A(N)=A(N)-QSS*DELR(J)*DELC(I)*DH(J,I,K)
          RHS(N)=RHS(N)-QSS*CTMP*DELR(J)*DELC(I)*DH(J,I,K)
        ENDIF
      ENDDO
C
C--DONE WITH EULERIAN-LAGRANGIAN SCHEMES
 2000 CONTINUE
C
C--RETURN
      RETURN
      END
C
C
      SUBROUTINE SSM3BD(NCOL,NROW,NLAY,NCOMP,ICOMP,ICBUND,DELR,DELC,
     & DH,IRCH,RECH,CRCH,IEVT,EVTR,CEVT,MXSS,NTSS,SS,SSMC,QSTO,CNEW,
     & DTRANS,ISS,TMASIO,RMASIO,TMASS)
C ********************************************************************
C THIS SUBROUTINE CALCULATES MASS BUDGETS ASSOCIATED WITH ALL SINK/
C SOURCE TERMS.
C ********************************************************************
C last modified: 06-23-98
C
      IMPLICIT  NONE
      INTEGER   NCOL,NROW,NLAY,NCOMP,ICOMP,ICBUND,IRCH,IEVT,MXSS,
     &          NTSS,NUM,IQ,K,I,J,ISS
      REAL      DTRANS,RECH,CRCH,EVTR,CEVT,SS,SSMC,CNEW,
     &          CTMP,QSS,TMASIO,RMASIO,DELR,DELC,DH,QSTO,TMASS
      LOGICAL   FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
      DIMENSION ICBUND(NCOL,NROW,NLAY,NCOMP),SS(6,MXSS),
     &          SSMC(NCOMP,MXSS),RECH(NCOL,NROW),IRCH(NCOL,NROW),
     &          CRCH(NCOL,NROW,NCOMP),EVTR(NCOL,NROW),
     &          IEVT(NCOL,NROW),CEVT(NCOL,NROW,NCOMP),
     &          CNEW(NCOL,NROW,NLAY,NCOMP),DELR(NCOL),DELC(NROW),
     &          DH(NCOL,NROW,NLAY),QSTO(NCOL,NROW,NLAY),
     &          TMASIO(20,2,NCOMP),RMASIO(20,2,NCOMP),TMASS(4,NCOMP)
      COMMON   /FC/FWEL,FDRN,FRCH,FEVT,FRIV,FGHB
C
C--TRANSIENT GROUNDWATER STORAGE TERM
      IF(ISS.NE.0) GOTO 50
C
      DO K=1,NLAY
        DO I=1,NROW
          DO J=1,NCOL
            IF(ICBUND(J,I,K,ICOMP).LE.0) CYCLE
            CTMP=CNEW(J,I,K,ICOMP)
            IF(QSTO(J,I,K).GT.0) THEN
              RMASIO(19,1,ICOMP)=RMASIO(19,1,ICOMP)
     &         +QSTO(J,I,K)*CTMP*DTRANS*DELR(J)*DELC(I)*DH(J,I,K)
            ELSE
              RMASIO(19,2,ICOMP)=RMASIO(19,2,ICOMP)
     &         +QSTO(J,I,K)*CTMP*DTRANS*DELR(J)*DELC(I)*DH(J,I,K)
            ENDIF
          ENDDO
        ENDDO
      ENDDO
C
C--DIFFUSIVE SINK/SOURCE TERMS
C--(RECHARGE)
   50 IF(.NOT.FRCH) GOTO 100
C
      DO I=1,NROW
        DO J=1,NCOL
C
          K=IRCH(J,I)
          IF(K.EQ.0 .OR. ICBUND(J,I,K,ICOMP).LE.0) CYCLE
          CTMP=CRCH(J,I,ICOMP)
          IF(RECH(J,I).LT.0) CTMP=CNEW(J,I,K,ICOMP)
C
          IF(RECH(J,I).GT.0) THEN
            RMASIO(7,1,ICOMP)=RMASIO(7,1,ICOMP)+RECH(J,I)*CTMP*DTRANS*
     &       DELR(J)*DELC(I)*DH(J,I,K)
          ELSE
            RMASIO(7,2,ICOMP)=RMASIO(7,2,ICOMP)+RECH(J,I)*CTMP*DTRANS*
     &       DELR(J)*DELC(I)*DH(J,I,K)
          ENDIF
C
        ENDDO
      ENDDO
C
C--(EVAPOTRANSPIRATION)
  100 IF(.NOT.FEVT) GOTO 200
C
      DO I=1,NROW
        DO J=1,NCOL
          K=IEVT(J,I)
          IF(K.EQ.0 .OR. ICBUND(J,I,K,ICOMP).LE.0) CYCLE
          CTMP=CEVT(J,I,ICOMP)
          IF(EVTR(J,I).LT.0.AND.CTMP.LT.0) THEN
            CTMP=CNEW(J,I,K,ICOMP)
          ELSEIF(EVTR(J,I).GE.0.AND.CTMP.LT.0) THEN
            CTMP=0.
          ENDIF
C
          IF(EVTR(J,I).GT.0) THEN
            RMASIO(8,1,ICOMP)=RMASIO(8,1,ICOMP)+EVTR(J,I)*CTMP*DTRANS*
     &       DELR(J)*DELC(I)*DH(J,I,K)
          ELSE
            RMASIO(8,2,ICOMP)=RMASIO(8,2,ICOMP)+EVTR(J,I)*CTMP*DTRANS*
     &       DELR(J)*DELC(I)*DH(J,I,K)
          ENDIF
C
        ENDDO
      ENDDO
C
C--POINT SINK/SOURCE TERMS (CONST-HEAD, WELL, DRAIN, RIVER & G-H-B)
  200 DO NUM=1,NTSS
C
        K=SS(1,NUM)
        I=SS(2,NUM)
        J=SS(3,NUM)
        QSS=SS(5,NUM)
        IQ=SS(6,NUM)
        CTMP=SS(4,NUM)
        IF(NCOMP.GT.1) CTMP=SSMC(ICOMP,NUM)
        IF(QSS.LT.0) CTMP=CNEW(J,I,K,ICOMP)
C
        IF(ICBUND(J,I,K,ICOMP).GT.0.AND.IQ.GT.0) THEN
          IF(QSS.GT.0) THEN
            RMASIO(IQ,1,ICOMP)=RMASIO(IQ,1,ICOMP)+QSS*CTMP*DTRANS*
     &       DELR(J)*DELC(I)*DH(J,I,K)
          ELSE
            RMASIO(IQ,2,ICOMP)=RMASIO(IQ,2,ICOMP)+QSS*CTMP*DTRANS*
     &       DELR(J)*DELC(I)*DH(J,I,K)
          ENDIF
        ENDIF
C
      ENDDO
C
C--RETURN
  400 RETURN
      END
