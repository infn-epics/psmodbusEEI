#!../../bin/linux-x86_64/psmodbusEEI

# QUATB203 00:90:E8:63:EB:6A 192.168.190.153
## Register all support components
dbLoadDatabase "../../dbd/psmodbusEEI.dbd"
psmodbusEEI_registerRecordDeviceDriver(pdbbase)

## Configure Modbus communication
# Configure IP port (adjust IP address and port as needed)
# drvAsynIPPortConfigure("EEI_IP", "192.168.190.153:502", 0, 0, 0)

drvAsynIPPortConfigure("EEI_IP", "192.168.190.156:502", 0, 0, 0)

# Enable Modbus interpose interface
modbusInterposeConfig("EEI_IP", 0, 0, 0)

# Configure Modbus port for reading holding registers (Function Code 3)
# Parameters: portName, asynPortName, slaveAddress, modbusFunction, modbusStartAddress, modbusLength, dataType, pollMsec, plcType
# Function code 3 = Read Holding Registers
# Start at register 40001 (Modbus address 0), read 45 registers (up to 0x2C)
drvModbusAsynConfigure("EEI_HOLDING_RD", "EEI_IP", 1, 3, 0, 45, 0, 1000, "EEI")

# Configure Modbus port for writing holding registers (Function Code 6)
# Function code 6 = Write Single Register
# Start at register 40001 (Modbus address 0), write to 45 registers
drvModbusAsynConfigure("EEI_HOLDING_WR", "EEI_IP",1, 16, 0, 45, 0, 0, "EEI")

## Load record instances
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB201,PORT=EEI_HOLDING_RD,PORT_WR=EEI_HOLDING_WR")
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:QUATB201,PORT=EEI_HOLDING_RD,PORT_WR=EEI_HOLDING_WR")

## Start IOC
iocInit()

## Print IOC information
dbl > pv_list.txt
