# psmodbusEEI - EEI Power Supply IOC with Enhanced UNIMAG Control

Enhanced EPICS IOC for controlling EEI power supplies via Modbus/TCP with comprehensive UNIMAG state machine, debug logging, standardized status reporting, and configurable ramp parameters. This IOC provides automatic polarity switching, sequencing control, and standardized STATUS_RB enumeration matching the OCEM E642 implementation.

## Overview

This IOC provides EPICS interface to the EEI Power Supply using the EPICS Modbus driver. It implements the complete Modbus register map including:

- Command and control registers
- Status monitoring
- Current and voltage setpoints and readbacks
- Ramp rate control
- Comprehensive fault monitoring
- Temperature monitoring

## Dependencies

- EPICS Base (7.0 or later recommended)
- ASYN module
- MODBUS module

## Directory Structure

```
psmodbusEEI/
├── configure/          # Build configuration files
├── psmodbusEEIApp/     # Application source
│   ├── src/           # Source code
│   └── Db/            # Database templates
├── iocBoot/           # IOC boot directory
│   └── psmodbusEEIIOC/
│       └── st.cmd     # Startup script
├── opi/               # Operator interface (Phoebus)
└── docs/              # Documentation including Modbus map
```

## Building

1. Edit `configure/RELEASE` to point to your EPICS Base, ASYN, and MODBUS installations
2. Build the IOC:
   ```bash
   make clean uninstall
   make
   ```

## Configuration

### Template Macros

The IOC supports several macros for customizing power supply behavior:

#### Required Macros
- `P`: PV prefix (e.g., `BTF:MAG:EEI:QUATB201`)
- `PORT`: Modbus read port name
- `PORT_WR`: Modbus write port name

#### Optional Ramp Configuration Macros (eei_ps.template)
- `RAMP_MIN`: Minimum ramp rate in A/s (default: 10)
- `RAMP_MAX`: Maximum ramp rate in A/s (default: 3474)
- `RAMP_DEFAULT`: Default ramp rate value in A/s (default: 100)

#### Example Usage
```bash
# Standard configuration with default ramp settings
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB201,PORT=QUATB201_RD,PORT_WR=QUATB201_WR")

# Custom ramp configuration for precision applications
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:QUATB201,PORT=QUATB201_RD,PORT_WR=QUATB201_WR,RAMP_MIN=5,RAMP_MAX=1000,RAMP_DEFAULT=50")

# High-power magnet with fast ramp capability  
dbLoadRecords("../../db/eei_ps.template","P=BTF:MAG:EEI:DHPTB102,PORT=DHPTB102_RD,PORT_WR=DHPTB102_WR,RAMP_MIN=10,RAMP_MAX=3474,RAMP_DEFAULT=200")
```

### Network Configuration

Edit `iocBoot/psmodbusEEIIOC/st.cmd` to configure the IP address and port:

```
drvAsynIPPortConfigure("EEI_IP", "192.168.1.100:502", 0, 0, 0)
```

Replace `192.168.1.100` with your EEI power supply IP address.

### Modbus Configuration

The IOC reads 45 holding registers starting at Modbus address 40001 (offset 0):

```
drvModbusAsynConfigure("EEI_HOLDING", "EEI_IP", 1, 3, 0, 45, 0, 1000, "EEI")
```

Parameters:
- Port name: EEI_HOLDING
- TCP port: EEI_IP
- Slave address: 1
- Function code: 3 (Read Holding Registers)
- Start address: 0 (register 40001)
- Length: 45 registers
- Data type: 0 (UINT16)
- Poll time: 1000 ms

### PV Prefix

Default PV prefix is `EEI:PS01`. To change it, edit the dbLoadRecords line in `st.cmd`:

```
dbLoadRecords("$(TOP)/db/eei_ps.template","P=YOUR:PREFIX,PORT=EEI_HOLDING")
```

## Running the IOC

```bash
cd iocBoot/psmodbusEEIIOC
chmod +x st.cmd
./st.cmd
```

## EPICS Process Variables

### Control PVs (Write)

| PV Name | Type | Description | Range |
|---------|------|-------------|-------|
| `$(P):CMD_STANDBY` | mbbo | Set Standby mode | 0-1 |
| `$(P):CMD_POWER_ON` | mbbo | Power On command | 0-1 |
| `$(P):CMD_GLOBAL_OFF` | mbbo | Global Off command | 0-1 |
| `$(P):CMD_RESET` | mbbo | Reset faults | 0-1 |
| `$(P):CMD_START_RAMP` | mbbo | Start current ramp | 0-1 |
| `$(P):CMD_POLARITY_POS` | mbbo | Set positive polarity | 0-1 |
| `$(P):CMD_POLARITY_NEG` | mbbo | Set negative polarity | 0-1 |
| `$(P):CMD_CONTACTORS_OPEN` | mbbo | Open contactors | 0-1 |
| `$(P):CURR_SET` | ao | Current setpoint (A) | 0-330 |
| `$(P):CURR_SET_SIGN` | mbbo | Current sign | 0=Pos, 1=Neg |
| `$(P):RAMP_RATE_SET` | ao | Ramp rate (A/s) | 10-3474 |
| `$(P):CYCLE_PATTERN_1` | ao | Cycles at set | 0-65535 |
| `$(P):CYCLE_PATTERN_0` | ao | Cycles at zero | 0-65535 |

### Status PVs (Read)

| PV Name | Type | Description |
|---------|------|-------------|
| `$(P):STAT_STANDBY` | bi | Standby state |
| `$(P):STAT_POWER_ON` | bi | Power On state |
| `$(P):STAT_FAULTY` | bi | Fault state |
| `$(P):STAT_REMOTE` | bi | Remote mode active |
| `$(P):STAT_LOCAL` | bi | Local mode active |
| `$(P):STAT_POLARITY_POS` | bi | Positive polarity active |
| `$(P):STAT_POLARITY_NEG` | bi | Negative polarity active |
| `$(P):STAT_CONTACTORS_OPEN` | bi | Contactors open |
| `$(P):CURR_RB` | ai | Current readback (A) |
| `$(P):CURR_RB_SIGN` | mbbi | Current sign readback |
| `$(P):VOLT_RB` | ai | Voltage readback (V) |
| `$(P):RAMP_RATE_RB` | ai | Ramp rate readback (A/s) |

### Fault Monitoring PVs (Read)

| PV Name | Description |
|---------|-------------|
| `$(P):FAULT_PLC_DCDC` | PLC DC/DC converter fault |
| `$(P):FAULT_PLC_DCCT_PS` | PLC DCCT power supply fault |
| `$(P):FAULT_PLC_MAG_ILK1` | PLC magnet interlock #1 |
| `$(P):FAULT_PLC_MAG_ILK2` | PLC magnet interlock #2 |
| `$(P):FAULT_PLC_ACDC1` | PLC AC/DC converter 1 fault |
| `$(P):FAULT_PLC_ACDC2` | PLC AC/DC converter 2 fault |
| `$(P):FAULT_PLC_WATER_FLOW` | PLC water flow fault |
| `$(P):FAULT_PLC_24V_PS` | PLC 24V power supply fault |
| `$(P):FAULT_PLC_FUSES` | PLC fuses fault |
| `$(P):FAULT_DCDC_OVERCURR` | DC/DC overcurrent fault |
| `$(P):FAULT_DCDC_THERM_PROT` | DC/DC thermal protection |
| `$(P):FAULT_DCDC_OVERTEMP` | DC/DC heat sink overtemperature |
| `$(P):FAULT_DCDC_DCLINK_LOW` | DC/DC DC link voltage low |
| `$(P):FAULT_DCDC_DCLINK_HIGH` | DC/DC DC link voltage high |
| `$(P):FAULT_DCDC_GROUND_CURR` | DC/DC ground current fault |
| `$(P):FAULT_ACDC1_OVERCURR` | AC/DC1 overcurrent fault |
| `$(P):FAULT_ACDC1_THERM_PROT` | AC/DC1 thermal protection |
| `$(P):FAULT_ACDC1_WATER_TEMP` | AC/DC1 water overtemperature |
| `$(P):FAULT_ACDC1_AIR_TEMP` | AC/DC1 air overtemperature |
| `$(P):FAULT_ACDC2_OVERCURR` | AC/DC2 overcurrent fault |
| `$(P):FAULT_ACDC2_THERM_PROT` | AC/DC2 thermal protection |
| `$(P):FAULT_ACDC2_WATER_TEMP` | AC/DC2 water overtemperature |
| `$(P):FAULT_ACDC2_AIR_TEMP` | AC/DC2 air overtemperature |

### Temperature and Diagnostic PVs (Read)

| PV Name | Description | Units |
|---------|-------------|-------|
| `$(P):DCDC_HEATSINK_TEMP_RB` | DC/DC heat sink temperature | °C |
| `$(P):ACDC1_VOLT_OUT_RB` | AC/DC1 output voltage | V |
| `$(P):ACDC1_CURR_OUT_RB` | AC/DC1 output current | A |
| `$(P):ACDC2_VOLT_OUT_RB` | AC/DC2 output voltage | V |
| `$(P):ACDC2_CURR_OUT_RB` | AC/DC2 output current | A |

### Detailed Fault Words (Read)

Raw fault word registers for detailed diagnostics:

| PV Name | Description |
|---------|-------------|
| `$(P):PLC_FAULT_WORD1_RB` | PLC faults word 1 |
| `$(P):PLC_FAULT_WORD2_RB` | PLC faults word 2 |
| `$(P):DCDC_FAULT_WORD1_RB` | DC/DC faults word 1 |
| `$(P):DCDC_FAULT_WORD2_RB` | DC/DC faults word 2 |
| `$(P):ACDC1_FAULT_WORD1_RB` | AC/DC1 faults word 1 |
| `$(P):ACDC1_FAULT_WORD2_RB` | AC/DC1 faults word 2 |
| `$(P):ACDC2_FAULT_WORD1_RB` | AC/DC2 faults word 1 |
| `$(P):ACDC2_FAULT_WORD2_RB` | AC/DC2 faults word 2 |

## Operator Interface

A Phoebus OPI screen is provided in `opi/eei_ps.bob`. The screen includes:

- Status indicators for operational states
- Control buttons for power, standby, reset, etc.
- Current and voltage monitoring
- Ramp rate control
- Comprehensive fault monitoring with LED indicators
- Temperature monitoring

To open the screen in Phoebus:
```bash
phoebus -resource opi/eei_ps.bob -P "P=EEI:PS01"
```

## Modbus Register Map

The complete Modbus register map is documented in `docs/EEI Modbus map updated.csv`.

Key register ranges:
- **40001-40021 (0x00-0x14)**: Command/control registers (Write)
- **40022-40023 (0x15-0x16)**: Status registers (Read)
- **40024-40027 (0x17-0x1A)**: Current/voltage readbacks (Read)
- **40028-40029 (0x1B-0x1C)**: Main fault summary (Read)
- **40033-40040 (0x20-0x27)**: Detailed fault registers (Read)
- **40041-40045 (0x28-0x2C)**: Temperature and diagnostic data (Read)

## Operating Procedures

### Startup Sequence

1. Ensure power supply is powered and connected to network
2. Verify water cooling is operational
3. Start the IOC
4. Check status: `$(P):STAT_STANDBY` should be 1
5. Set current setpoint: `caput $(P):CURR_SET <value>`
6. Set ramp rate: `caput $(P):RAMP_RATE_SET <value>`
7. Power on: `caput $(P):CMD_POWER_ON 1`
8. Start ramp: `caput $(P):CMD_START_RAMP 1`

### Shutdown Sequence

1. Ramp current to zero or stop ramp
2. Execute global off: `caput $(P):CMD_GLOBAL_OFF 1`
3. Wait for power supply to turn off
4. Stop IOC if needed

### Fault Recovery

1. Check fault status PVs to identify the fault
2. Address the underlying issue (cooling, interlocks, etc.)
3. Execute reset: `caput $(P):CMD_RESET 1`
4. Verify fault is cleared
5. Resume normal operation

## Safety Notes

⚠️ **Important Safety Information:**

- Always verify interlock status before operation
- Monitor water flow and temperature continuously
- Current limits: 0-330 A (absolute value)
- Voltage limits: -135 to +135 V
- Do not exceed maximum ramp rates
- Global off immediately stops all operations

## Troubleshooting

### Communication Issues

- Verify IP address and port in st.cmd
- Check network connectivity: `ping <IP address>`
- Verify Modbus slave address (default: 1)
- Check firewall settings

### IOC Won't Start

- Verify EPICS Base, ASYN, and MODBUS paths in configure/RELEASE
- Rebuild: `make clean uninstall && make`
- Check for port conflicts

### PVs Not Updating

- Check IOC console for errors
- Verify Modbus polling is active (default: 1000 ms)
- Check asyn trace: `asynSetTraceMask("EEI_IP", 0, 9)`

## Testing

Basic PV tests:
```bash
# Test connectivity
caget $(P):STAT_WORD1_RB

# Test write capability
caput $(P):CURR_SET 10

# Monitor current
camonitor $(P):CURR_RB

# Check all faults
caget $(P):FAULT_*
```

## Support

For issues or questions:
- Check the EEI Power Supply manual
- Review Modbus register map in docs/
- Consult EPICS Modbus documentation

## License

This IOC follows standard EPICS licensing.

## Version History

- **1.0.0** (2024-12-11): Initial release
  - Complete Modbus register map implementation
  - All command and status PVs
  - Comprehensive fault monitoring
  - Phoebus OPI screen

## Author

Created based on the EEI Modbus specification and plc-elinp IOC example.
