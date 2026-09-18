#!../../bin/linux-x86_64/psmodbusEEI

# QUATB203 00:90:E8:63:EB:6A 192.168.190.153
## Register all support components
dbLoadDatabase "../../dbd/psmodbusEEI.dbd"
psmodbusEEI_registerRecordDeviceDriver(pdbbase)

## Configure Modbus communication - QUATB201
# Configure IP port (adjust IP address and port as needed)
# drvAsynIPPortConfigure("EEI_IP_QUATB201", "192.168.190.153:502", 0, 0, 0)

drvAsynIPPortConfigure("EEI_IP_QUATB201", "192.168.190.151:502", 0, 0, 0)

# Enable Modbus interpose interface
modbusInterposeConfig("EEI_IP_QUATB201", 0, 0, 0)

# Configure Modbus port for reading holding registers (Function Code 3)
# Parameters: portName, asynPortName, slaveAddress, modbusFunction, modbusStartAddress, modbusLength, dataType, pollMsec, plcType
# Function code 3 = Read Holding Registers
# Start at register 40001 (Modbus address 0), read 45 registers (up to 0x2C)
drvModbusAsynConfigure("EEI_HOLDING_RD_QUATB201", "EEI_IP_QUATB201", 1, 3, 0, 45, 0, 1000, "EEI")

# Configure Modbus port for writing holding registers (Function Code 6)
# Function code 6 = Write Single Register
# Start at register 40001 (Modbus address 0), write to 45 registers
drvModbusAsynConfigure("EEI_HOLDING_WR_QUATB201", "EEI_IP_QUATB201",1, 16, 0, 45, 0, 0, "EEI")

## Load record instances
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB201,PORT=EEI_HOLDING_RD_QUATB201,PORT_WR=EEI_HOLDING_WR_QUATB201")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:QUATB201,PORT=EEI_HOLDING_RD_QUATB201,PORT_WR=EEI_HOLDING_WR_QUATB201")


## dipole bipolar
## Configure Modbus communication - DHPTB102
# NOTE: must use port names distinct from QUATB201's above - reusing the
# same asyn/Modbus port names here would silently reconfigure them to this
# IP, causing QUATB201's records to poll DHPTB102's physical hardware
# instead of their own.

drvAsynIPPortConfigure("EEI_IP_DHPTB102", "192.168.190.157:502", 0, 0, 0)

# Enable Modbus interpose interface
modbusInterposeConfig("EEI_IP_DHPTB102", 0, 0, 0)

# Configure Modbus port for reading holding registers (Function Code 3)
# Parameters: portName, asynPortName, slaveAddress, modbusFunction, modbusStartAddress, modbusLength, dataType, pollMsec, plcType
# Function code 3 = Read Holding Registers
# Start at register 40001 (Modbus address 0), read 45 registers (up to 0x2C)
drvModbusAsynConfigure("EEI_HOLDING_RD_DHPTB102", "EEI_IP_DHPTB102", 1, 3, 0, 45, 0, 1000, "EEI")

# Configure Modbus port for writing holding registers (Function Code 6)
# Function code 6 = Write Single Register
# Start at register 40001 (Modbus address 0), write to 45 registers
drvModbusAsynConfigure("EEI_HOLDING_WR_DHPTB102", "EEI_IP_DHPTB102",1, 16, 0, 45, 0, 0, "EEI")

## Load record instances
# DHPTB102 is a pulsed-dipole (H-bridge) unit: it has no polarity contactors,
# so polarity is set via the CURRENT_SP_SIGN bit + CMD_START_RAMP trigger
# instead (POLARITY_VIA_SIGN=1) - see eei_ps_unimag.template and
# unimagEEIControl.st for details.
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:DHPTB102,PORT=EEI_HOLDING_RD_DHPTB102,PORT_WR=EEI_HOLDING_WR_DHPTB102,MAX_CURR=330,MIN_CURR=-330")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:DHPTB102,PORT=EEI_HOLDING_RD_DHPTB102,PORT_WR=EEI_HOLDING_WR_DHPTB102,POLARITY_VIA_SIGN=1,MAX_CURR=330,MIN_CURR=-330")

## Configure Modbus communication - QUATB202
drvAsynIPPortConfigure("EEI_IP_QUATB202", "192.168.190.152:502", 0, 0, 0)
modbusInterposeConfig("EEI_IP_QUATB202", 0, 0, 0)
drvModbusAsynConfigure("EEI_HOLDING_RD_QUATB202", "EEI_IP_QUATB202", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("EEI_HOLDING_WR_QUATB202", "EEI_IP_QUATB202", 1, 16, 0, 45, 0, 0, "EEI")
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB202,PORT=EEI_HOLDING_RD_QUATB202,PORT_WR=EEI_HOLDING_WR_QUATB202")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:QUATB202,PORT=EEI_HOLDING_RD_QUATB202,PORT_WR=EEI_HOLDING_WR_QUATB202")

## Configure Modbus communication - DHSTB201
drvAsynIPPortConfigure("EEI_IP_DHSTB201", "192.168.190.158:502", 0, 0, 0)
modbusInterposeConfig("EEI_IP_DHSTB201", 0, 0, 0)
drvModbusAsynConfigure("EEI_HOLDING_RD_DHSTB201", "EEI_IP_DHSTB201", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("EEI_HOLDING_WR_DHSTB201", "EEI_IP_DHSTB201", 1, 16, 0, 45, 0, 0, "EEI")
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:DHSTB201,PORT=EEI_HOLDING_RD_DHSTB201,PORT_WR=EEI_HOLDING_WR_DHSTB201")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:DHSTB201,PORT=EEI_HOLDING_RD_DHSTB201,PORT_WR=EEI_HOLDING_WR_DHSTB201")

## Configure Modbus communication - QUATB203
drvAsynIPPortConfigure("EEI_IP_QUATB203", "192.168.190.153:502", 0, 0, 0)
modbusInterposeConfig("EEI_IP_QUATB203", 0, 0, 0)
drvModbusAsynConfigure("EEI_HOLDING_RD_QUATB203", "EEI_IP_QUATB203", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("EEI_HOLDING_WR_QUATB203", "EEI_IP_QUATB203", 1, 16, 0, 45, 0, 0, "EEI")
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB203,PORT=EEI_HOLDING_RD_QUATB203,PORT_WR=EEI_HOLDING_WR_QUATB203")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:QUATB203,PORT=EEI_HOLDING_RD_QUATB203,PORT_WR=EEI_HOLDING_WR_QUATB203")

## Configure Modbus communication - QUATB204
drvAsynIPPortConfigure("EEI_IP_QUATB204", "192.168.190.154:502", 0, 0, 0)
modbusInterposeConfig("EEI_IP_QUATB204", 0, 0, 0)
drvModbusAsynConfigure("EEI_HOLDING_RD_QUATB204", "EEI_IP_QUATB204", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("EEI_HOLDING_WR_QUATB204", "EEI_IP_QUATB204", 1, 16, 0, 45, 0, 0, "EEI")
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB204,PORT=EEI_HOLDING_RD_QUATB204,PORT_WR=EEI_HOLDING_WR_QUATB204")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:QUATB204,PORT=EEI_HOLDING_RD_QUATB204,PORT_WR=EEI_HOLDING_WR_QUATB204")

## Configure Modbus communication - DHSTB202
drvAsynIPPortConfigure("EEI_IP_DHSTB202", "192.168.190.159:502", 0, 0, 0)
modbusInterposeConfig("EEI_IP_DHSTB202", 0, 0, 0)
drvModbusAsynConfigure("EEI_HOLDING_RD_DHSTB202", "EEI_IP_DHSTB202", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("EEI_HOLDING_WR_DHSTB202", "EEI_IP_DHSTB202", 1, 16, 0, 45, 0, 0, "EEI")
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:DHSTB202,PORT=EEI_HOLDING_RD_DHSTB202,PORT_WR=EEI_HOLDING_WR_DHSTB202")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:DHSTB202,PORT=EEI_HOLDING_RD_DHSTB202,PORT_WR=EEI_HOLDING_WR_DHSTB202")

## Configure Modbus communication - QUATB205
drvAsynIPPortConfigure("EEI_IP_QUATB205", "192.168.190.155:502", 0, 0, 0)
modbusInterposeConfig("EEI_IP_QUATB205", 0, 0, 0)
drvModbusAsynConfigure("EEI_HOLDING_RD_QUATB205", "EEI_IP_QUATB205", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("EEI_HOLDING_WR_QUATB205", "EEI_IP_QUATB205", 1, 16, 0, 45, 0, 0, "EEI")
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB205,PORT=EEI_HOLDING_RD_QUATB205,PORT_WR=EEI_HOLDING_WR_QUATB205")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:QUATB205,PORT=EEI_HOLDING_RD_QUATB205,PORT_WR=EEI_HOLDING_WR_QUATB205")

## Configure Modbus communication - QUATB206
drvAsynIPPortConfigure("EEI_IP_QUATB206", "192.168.190.156:502", 0, 0, 0)
modbusInterposeConfig("EEI_IP_QUATB206", 0, 0, 0)
drvModbusAsynConfigure("EEI_HOLDING_RD_QUATB206", "EEI_IP_QUATB206", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("EEI_HOLDING_WR_QUATB206", "EEI_IP_QUATB206", 1, 16, 0, 45, 0, 0, "EEI")
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB206,PORT=EEI_HOLDING_RD_QUATB206,PORT_WR=EEI_HOLDING_WR_QUATB206")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:QUATB206,PORT=EEI_HOLDING_RD_QUATB206,PORT_WR=EEI_HOLDING_WR_QUATB206")

## Configure Modbus communication - DHSTB203
drvAsynIPPortConfigure("EEI_IP_DHSTB203", "192.168.190.160:502", 0, 0, 0)
modbusInterposeConfig("EEI_IP_DHSTB203", 0, 0, 0)
drvModbusAsynConfigure("EEI_HOLDING_RD_DHSTB203", "EEI_IP_DHSTB203", 1, 3, 0, 45, 0, 1000, "EEI")
drvModbusAsynConfigure("EEI_HOLDING_WR_DHSTB203", "EEI_IP_DHSTB203", 1, 16, 0, 45, 0, 0, "EEI")
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:DHSTB203,PORT=EEI_HOLDING_RD_DHSTB203,PORT_WR=EEI_HOLDING_WR_DHSTB203")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:DHSTB203,PORT=EEI_HOLDING_RD_DHSTB203,PORT_WR=EEI_HOLDING_WR_DHSTB203")

## Start IOC
iocInit()

## Start SNL programs
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB201"
seq unimagEEIControl, "P=BTF:MAG:EEI:DHPTB102"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB202"
seq unimagEEIControl, "P=BTF:MAG:EEI:DHSTB201"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB203"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB204"
seq unimagEEIControl, "P=BTF:MAG:EEI:DHSTB202"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB205"
seq unimagEEIControl, "P=BTF:MAG:EEI:QUATB206"
seq unimagEEIControl, "P=BTF:MAG:EEI:DHSTB203"

## Print IOC information
dbl > pv_list.txt
