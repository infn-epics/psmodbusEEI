#!../../bin/linux-x86_64/psmodbusEEI

## EEI Power Supply IOC - BTF Transfer Line Magnets
## Register all support components
dbLoadDatabase "../../dbd/psmodbusEEI.dbd"
psmodbusEEI_registerRecordDeviceDriver(pdbbase)

## ============================================
## Configure Modbus communication for each PS
## ============================================

# --- QUATB201 (192.168.190.151) ---
drvAsynIPPortConfigure("QUATB201_IP", "192.168.190.151:502", 0, 0, 0)
modbusInterposeConfig("QUATB201_IP", 0, 0, 0)
drvModbusAsynConfigure("QUATB201_RD", "QUATB201_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("QUATB201_WR", "QUATB201_IP", 1, 16, 0, 45, 0, 0, "EEI")

# --- QUATB202 (192.168.190.152) ---
drvAsynIPPortConfigure("QUATB202_IP", "192.168.190.152:502", 0, 0, 0)
modbusInterposeConfig("QUATB202_IP", 0, 0, 0)
drvModbusAsynConfigure("QUATB202_RD", "QUATB202_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("QUATB202_WR", "QUATB202_IP", 1, 16, 0, 45, 0, 0, "EEI")

# --- QUATB203 (192.168.190.153) ---
drvAsynIPPortConfigure("QUATB203_IP", "192.168.190.153:502", 0, 0, 0)
modbusInterposeConfig("QUATB203_IP", 0, 0, 0)
drvModbusAsynConfigure("QUATB203_RD", "QUATB203_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("QUATB203_WR", "QUATB203_IP", 1, 16, 0, 45, 0, 0, "EEI")

# --- QUATB204 (192.168.190.154) ---
drvAsynIPPortConfigure("QUATB204_IP", "192.168.190.154:502", 0, 0, 0)
modbusInterposeConfig("QUATB204_IP", 0, 0, 0)
drvModbusAsynConfigure("QUATB204_RD", "QUATB204_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("QUATB204_WR", "QUATB204_IP", 1, 16, 0, 45, 0, 0, "EEI")

# --- QUATB205 (192.168.190.155) ---
drvAsynIPPortConfigure("QUATB205_IP", "192.168.190.155:502", 0, 0, 0)
modbusInterposeConfig("QUATB205_IP", 0, 0, 0)
drvModbusAsynConfigure("QUATB205_RD", "QUATB205_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("QUATB205_WR", "QUATB205_IP", 1, 16, 0, 45, 0, 0, "EEI")

# --- QUATB206 (192.168.190.156) ---
drvAsynIPPortConfigure("QUATB206_IP", "192.168.190.156:502", 0, 0, 0)
modbusInterposeConfig("QUATB206_IP", 0, 0, 0)
drvModbusAsynConfigure("QUATB206_RD", "QUATB206_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("QUATB206_WR", "QUATB206_IP", 1, 16, 0, 45, 0, 0, "EEI")

# --- DHPTB102 (192.168.190.157) ---
drvAsynIPPortConfigure("DHPTB102_IP", "192.168.190.157:502", 0, 0, 0)
modbusInterposeConfig("DHPTB102_IP", 0, 0, 0)
drvModbusAsynConfigure("DHPTB102_RD", "DHPTB102_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("DHPTB102_WR", "DHPTB102_IP", 1, 16, 0, 45, 0, 0, "EEI")

# --- DHSTB201 (192.168.190.158) ---
drvAsynIPPortConfigure("DHSTB201_IP", "192.168.190.158:502", 0, 0, 0)
modbusInterposeConfig("DHSTB201_IP", 0, 0, 0)
drvModbusAsynConfigure("DHSTB201_RD", "DHSTB201_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("DHSTB201_WR", "DHSTB201_IP", 1, 16, 0, 45, 0, 0, "EEI")

# --- DHSTB202 (192.168.190.159) ---
drvAsynIPPortConfigure("DHSTB202_IP", "192.168.190.159:502", 0, 0, 0)
modbusInterposeConfig("DHSTB202_IP", 0, 0, 0)
drvModbusAsynConfigure("DHSTB202_RD", "DHSTB202_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("DHSTB202_WR", "DHSTB202_IP", 1, 16, 0, 45, 0, 0, "EEI")

# --- DHSTB203 (192.168.190.160) ---
drvAsynIPPortConfigure("DHSTB203_IP", "192.168.190.160:502", 0, 0, 0)
modbusInterposeConfig("DHSTB203_IP", 0, 0, 0)
drvModbusAsynConfigure("DHSTB203_RD", "DHSTB203_IP", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("DHSTB203_WR", "DHSTB203_IP", 1, 16, 0, 45, 0, 0, "EEI")

## ============================================
## Load record instances for each PS
## Merged template includes both Modbus and UNIMAG interface
## ============================================

# QUATB201 (with custom ramp settings: slow ramp for precision)
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB201,PORT=QUATB201_RD,PORT_WR=QUATB201_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=50")

# QUATB202
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB202,PORT=QUATB202_RD,PORT_WR=QUATB202_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=100")

# QUATB203  
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB203,PORT=QUATB203_RD,PORT_WR=QUATB203_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=100")

# QUATB204
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB204,PORT=QUATB204_RD,PORT_WR=QUATB204_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=100")

# QUATB205
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB205,PORT=QUATB205_RD,PORT_WR=QUATB205_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=100")

# QUATB206
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB206,PORT=QUATB206_RD,PORT_WR=QUATB206_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=100")

# DHPTB102 (with faster ramp for high power magnet)
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:DHPTB102,PORT=DHPTB102_RD,PORT_WR=DHPTB102_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=200")

# DHSTB201
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:DHSTB201,PORT=DHSTB201_RD,PORT_WR=DHSTB201_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=150")

# DHSTB202
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:DHSTB202,PORT=DHSTB202_RD,PORT_WR=DHSTB202_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=150")

# DHSTB203
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:DHSTB203,PORT=DHSTB203_RD,PORT_WR=DHSTB203_WR,MAX_CURR=330,MIN_CURR=-330,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=150")

## ============================================
## Start IOC
## ============================================
iocInit()

## ============================================
## Start SNL programs for each PS
## ============================================
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB201"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB202"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB203"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB204"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB205"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB206"
seq unimagEEIControl, "P=BTF:MAG:EEI:DHPTB102"
seq unimagEEIControl, "P=BTF:MAG:EEI:DHSTB201"
seq unimagEEIControl, "P=BTF:MAG:EEI:DHSTB202"
seq unimagEEIControl, "P=BTF:MAG:EEI:DHSTB203"

## Print IOC information
dbl > pv_list.txt

dbgf BTF:MAG:EEI:DHPTB102:CURRENT_SP
dbgf BTF:MAG:EEI:DHPTB102:CURRENT_RB

dbgf BTF:MAG:EEI:DHPTB102:STATE_SP
dbgf BTF:MAG:EEI:DHPTB102:STATE_RB
