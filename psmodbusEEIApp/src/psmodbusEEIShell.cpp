/* psmodbusEEI Shell Functions */
/* IOC shell functions for EEI power supply configuration */

#include <stddef.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>

#include "epicsExport.h"
#include "iocsh.h"
#include "dbAccess.h"
#include "registryFunction.h"

/* EEI Power Supply Ramp Configuration Functions */
static int setEEIRampLimits(const char* pvPrefix, double minRate, double maxRate)
{
    char pvName[256];
    DBADDR addr;
    long status;
    
    printf("Setting ramp limits for %s: min=%.0f, max=%.0f A/s\n", pvPrefix, minRate, maxRate);
    
    /* Set minimum rate limit */
    snprintf(pvName, sizeof(pvName), "%s:RAMP_RATE_SET.DRVL", pvPrefix);
    status = dbNameToAddr(pvName, &addr);
    if (status == 0) {
        double val = minRate;
        dbPutField(&addr, DBR_DOUBLE, &val, 1);
        printf("  Set %s = %.0f A/s\n", pvName, minRate);
    } else {
        printf("  Warning: PV %s not found (may not be loaded yet)\n", pvName);
    }
    
    /* Set maximum rate limit */
    snprintf(pvName, sizeof(pvName), "%s:RAMP_RATE_SET.DRVH", pvPrefix);
    status = dbNameToAddr(pvName, &addr);
    if (status == 0) {
        double val = maxRate;
        dbPutField(&addr, DBR_DOUBLE, &val, 1);
        printf("  Set %s = %.0f A/s\n", pvName, maxRate);
    } else {
        printf("  Warning: PV %s not found (may not be loaded yet)\n", pvName);
    }
    
    /* Set high operating range */
    snprintf(pvName, sizeof(pvName), "%s:RAMP_RATE_SET.HOPR", pvPrefix);
    status = dbNameToAddr(pvName, &addr);
    if (status == 0) {
        double val = maxRate;
        dbPutField(&addr, DBR_DOUBLE, &val, 1);
    }
    
    /* Set low operating range */
    snprintf(pvName, sizeof(pvName), "%s:RAMP_RATE_SET.LOPR", pvPrefix);
    status = dbNameToAddr(pvName, &addr);
    if (status == 0) {
        double val = minRate;
        dbPutField(&addr, DBR_DOUBLE, &val, 1);
    }
    
    return 0;
}

static int setEEIRampDefault(const char* pvPrefix, double defaultRate)
{
    char pvName[256];
    DBADDR addr;
    long status;
    
    /* Set default ramp rate value */
    snprintf(pvName, sizeof(pvName), "%s:RAMP_RATE_SET", pvPrefix);
    status = dbNameToAddr(pvName, &addr);
    if (status == 0) {
        double val = defaultRate;
        dbPutField(&addr, DBR_DOUBLE, &val, 1);
        printf("  Set %s = %.0f A/s (default)\n", pvName, defaultRate);
        return 0;
    } else {
        printf("  Warning: PV %s not found (may not be loaded yet)\n", pvName);
        return -1;
    }
}

/* IOC shell function registration */
static const iocshArg setEEIRampLimitsArg0 = {"pvPrefix", iocshArgString};
static const iocshArg setEEIRampLimitsArg1 = {"minRate", iocshArgDouble};
static const iocshArg setEEIRampLimitsArg2 = {"maxRate", iocshArgDouble};
static const iocshArg* const setEEIRampLimitsArgs[] = {
    &setEEIRampLimitsArg0, &setEEIRampLimitsArg1, &setEEIRampLimitsArg2
};
static const iocshFuncDef setEEIRampLimitsDef = {"setEEIRampLimits", 3, setEEIRampLimitsArgs,
    "Set EEI ramp rate limits\n"
    "Usage: setEEIRampLimits(\"<PV_PREFIX>\", <min_rate>, <max_rate>)\n"
    "Example: setEEIRampLimits(\"BTF:MAG:EEI:QUATB201\", 10, 3474)\n"};

static void setEEIRampLimitsCall(const iocshArgBuf* args) {
    setEEIRampLimits(args[0].sval, args[1].dval, args[2].dval);
}

static const iocshArg setEEIRampDefaultArg0 = {"pvPrefix", iocshArgString};
static const iocshArg setEEIRampDefaultArg1 = {"defaultRate", iocshArgDouble};
static const iocshArg* const setEEIRampDefaultArgs[] = {
    &setEEIRampDefaultArg0, &setEEIRampDefaultArg1
};
static const iocshFuncDef setEEIRampDefaultDef = {"setEEIRampDefault", 2, setEEIRampDefaultArgs,
    "Set EEI ramp rate default value\n"
    "Usage: setEEIRampDefault(\"<PV_PREFIX>\", <default_rate>)\n"
    "Example: setEEIRampDefault(\"BTF:MAG:EEI:QUATB201\", 100)\n"};

static void setEEIRampDefaultCall(const iocshArgBuf* args) {
    setEEIRampDefault(args[0].sval, args[1].dval);
}

static void psmodbusEEIRegister(void) {
    iocshRegister(&setEEIRampLimitsDef, setEEIRampLimitsCall);
    iocshRegister(&setEEIRampDefaultDef, setEEIRampDefaultCall);
}

epicsExportRegistrar(psmodbusEEIRegister);