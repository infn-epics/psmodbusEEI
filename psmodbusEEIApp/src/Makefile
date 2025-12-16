TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS BELOW HERE

# Build an IOC support library
#LIBRARY_IOC += psmodbusEEISupport

# xxxRecord.h will be created from xxxRecord.dbd
#DBDINC += xxxRecord
# Install devXxxSoft.dbd into <top>/dbd
#DBD += xxxSupport.dbd

# Compile and add the code to the support library
#psmodbusEEISupport_SRCS += xxxRecord.c
#psmodbusEEISupport_SRCS += devXxxSoft.c

# Link locally-provided code into the support library,
# rather than directly into the IOC application.
#psmodbusEEISupport_SRCS += dbSubExample.c
#psmodbusEEISupport_SRCS += devpsmodbusEEIVersion.c
#psmodbusEEISupport_SRCS += psmodbusEEIHello.c
#psmodbusEEISupport_SRCS += initTrace.c

#psmodbusEEISupport_LIBS += $(EPICS_BASE_IOC_LIBS)

# Build the IOC application
PROD_IOC = psmodbusEEI

# psmodbusEEI.dbd will be created and installed
DBD += psmodbusEEI.dbd

# psmodbusEEI.dbd will be made up from these files:
psmodbusEEI_DBD += base.dbd
psmodbusEEI_DBD += asyn.dbd
psmodbusEEI_DBD += drvAsynIPPort.dbd
psmodbusEEI_DBD += modbusSupport.dbd

# psmodbusEEI_registerRecordDeviceDriver.cpp derives from psmodbusEEI.dbd
psmodbusEEI_SRCS += psmodbusEEI_registerRecordDeviceDriver.cpp

# Build the main IOC entry point where needed
psmodbusEEI_SRCS_DEFAULT += psmodbusEEIMain.cpp
psmodbusEEI_SRCS_vxWorks += -nil-

# Link in the code from our support library
#psmodbusEEI_LIBS += psmodbusEEISupport

# To build SNL programs, SNCSEQ must be defined
# in the <top>/configure/RELEASE file
#ifneq ($(SNCSEQ),)
    # Build sncExample into psmodbusEEISupport
    #sncExample_SNCFLAGS += +r
    #psmodbusEEI_DBD += sncExample.dbd
    # A .stt sequence program is *not* pre-processed:
    #psmodbusEEISupport_SRCS += sncExample.stt
    #psmodbusEEISupport_LIBS += seq pv
    #psmodbusEEI_LIBS += seq pv

    # Build sncProgram as a standalone program
    #PROD_HOST += sncProgram
    #sncProgram_SNCFLAGS += +m
    # A .st sequence program *is* pre-processed:
    #sncProgram_SRCS += sncProgram.st
    #sncProgram_LIBS += seq pv
    #sncProgram_LIBS += $(EPICS_BASE_HOST_LIBS)
#endif

# Link QSRV (pvAccess Server) if available
# ifdef BASE_7_0
#     psmodbusEEI_DBD += PVAServerRegister.dbd
#     psmodbusEEI_DBD += qsrv.dbd
# endif

# Finally link IOC to the EPICS Base libraries
psmodbusEEI_LIBS += modbus
psmodbusEEI_LIBS += asyn
psmodbusEEI_LIBS += $(EPICS_BASE_IOC_LIBS)

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD EXTRA GNUMAKE RULES BELOW HERE
