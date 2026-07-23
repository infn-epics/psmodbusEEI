# EEI Power Supply EPICS Modbus IOC

EPICS IOC for controlling EEI Power Supply via Modbus TCP protocol.

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

To change the PV prefix, edit the `dbLoadRecords` lines in `st.cmd` (both the base template and the
UNIMAG template must use the same prefix), and the `seq` line that starts the SNL program:

```
dbLoadRecords("../../db/eei_ps.template","P=YOUR:PREFIX,PORT=EEI_HOLDING_RD,PORT_WR=EEI_HOLDING_WR")
dbLoadRecords("../../db/eei_ps_unimag.template","P=YOUR:PREFIX,PORT=EEI_HOLDING_RD,PORT_WR=EEI_HOLDING_WR")
...
seq unimagEEIControl, "P=YOUR:PREFIX"
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
| `$(P):CMD_POLARITY_POS_REQ` | bo | Request positive polarity (opens contactors, then switches) | 0-1 |
| `$(P):CMD_POLARITY_NEG_REQ` | bo | Request negative polarity (opens contactors, then switches) | 0-1 |
| `$(P):CMD_CONTACTORS_OPEN` | bo | Open contactors | 0-1 |
| `$(P):CURRENT_SP` | ao | **Signed** current setpoint (A) — normal entry point, see [Setting the Current](#setting-the-current) | -330 to 330 |
| `$(P):CURR_SET_RAW` | ao | Raw hardware magnitude register (unsigned, driven by the SNL program) | 0-330 |
| `$(P):CURRENT_SP_SIGN` | mbbo | Raw hardware sign register | 0=Pos, 1=Neg |
| `$(P):STATE_SP` | mbbo | Set power supply state | 0=OFF,1=ON,2=STANDBY,3=RESET |
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
| `$(P):CURRENT_RB` | calc | Current readback (A), **signed** — matches `$(P):CURRENT_SP`'s convention. Sign source depends on `CFG_POLARITY_VIA_SIGN`: `CURRENT_RB_SIGN` for sign-bit units, `STAT_POLARITY_NEG` for contactor-based units (see below) |
| `$(P):CURR_RB_RAW` | ai | Raw hardware magnitude register (unsigned) |
| `$(P):CURRENT_RB_SIGN` | mbbi | Raw hardware sign register |
| `$(P):VOLT_RB` | ai | Voltage readback (V) |
| `$(P):RAMP_RATE_RB` | ai | Ramp rate readback (A/s) |
| `$(P):STATE_RB` | mbbi | Decoded power supply state (STANDBY/ON/FAULT) |

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
3. Start the IOC (this also starts the `unimagEEIControl` SNL program, see below)
4. Check status: `$(P):STAT_STANDBY` should be 1
5. Set ramp rate: `caput $(P):RAMP_RATE_SET <value>`
6. Set the current setpoint: `caput $(P):CURRENT_SP <value>` (see [Setting the Current](#setting-the-current) — this alone drives power-on, polarity, and ramp start)

### Setting the Current

Current is set through a single **signed** PV, `$(P):CURRENT_SP` (A, positive or negative), defined in
`psmodbusEEIApp/Db/eei_ps_unimag.template`. This is a soft record with no hardware link — it is monitored
by the `unimagEEIControl` SNL program (`psmodbusEEIApp/src/unimagEEIControl.st`), which translates the sign
into a polarity command and writes the magnitude to the raw hardware registers (`$(P):CURR_SET_RAW`,
`$(P):CURRENT_SP_SIGN`). The IOC's `st.cmd` starts this program with `seq unimagEEIControl, "P=<prefix>"`
after `iocInit()`.

On every new value of `$(P):CURRENT_SP` the state machine:

1. Determines the requested polarity from the sign of the setpoint.
2. If the power supply is already in the requested polarity, sets the magnitude directly
   (powering on first if needed) and starts the ramp — no polarity change needed.
3. If a polarity change is required:
   - Ramps the current down to zero first if the supply is powered on and current is above a small
     threshold (2 A).
   - Puts the supply into standby (`$(P):CMD_STANDBY`).
   - Opens the contactors (`$(P):CMD_CONTACTORS_OPEN`), then writes the polarity selector
     (`$(P):CMD_POLARITY_POS_EXEC` / `$(P):CMD_POLARITY_NEG_EXEC`) — this register is a mutually-exclusive
     OPEN/POS/NEG selector, so a single write both changes polarity and clears the "open" state atomically.
     On units in "Triggered" mode (see below), this write alone doesn't take effect until committed, so
     `$(P):CMD_START_RAMP` is pulsed right after it.
   - Waits for `$(P):STAT_POLARITY_POS` / `$(P):STAT_POLARITY_NEG` to confirm the switch.
   - Powers back on (`$(P):CMD_POWER_ON`) and starts the ramp to the requested magnitude
     (`$(P):CMD_START_RAMP`).
4. Each waiting step has a timeout (30 s); on timeout the operation is cancelled and the state machine
   returns to idle. Asserting `$(P):CMD_RESET` at any point also cancels the in-progress operation.

#### Trigger source: Software vs. Hardware

The general installation/operation manual (`docs/manuals/170458-INFN-manuale-110319.pdf`, §6.2.4 and
§8.5.9) clarifies what COMMAND WORD #1 bits 5/6 (`$(P):CMD_CURRENT_MODE_TRIG` / `$(P):CMD_CURRENT_MODE_SW`)
actually select. The trigger itself (`$(P):CMD_START_RAMP`, documented as `START_RAMP/TRIGGER`) is
**always required** to commit a new current reference (magnitude and/or sign) — there is no mode where
writes just take effect on their own. What bits 5/6 select is the trigger's **source**:

- **Software** (`CMD_CURRENT_MODE_SW`): the trigger comes from the Modbus/EPICS `start_ramp` bit (Remote
  mode) or the operator-panel button (Local mode) — this is what our `$(P):CMD_START_RAMP` writes drive.
- **Hardware** (`CMD_CURRENT_MODE_TRIG`): the trigger comes from an external BNC "Trigger input" signal
  instead — in this mode, **our `$(P):CMD_START_RAMP` writes are silently ignored entirely**, since the
  manual states the remote/local Start Ramp commands "are not active" while Hardware is selected.

Since this IOC only ever writes the trigger via Modbus, Software must always be selected for it to have any
effect. This is controlled via `$(P):MODE_SW_ENABLE` (in `eei_ps_unimag.template`) — writing it applies the
corresponding hardware bit immediately via `$(P):MODE_APPLY`. The boot-time default is Software (`1`),
which is correct for every unit under this IOC's control and should not normally need overriding; the
`SW_MODE` db macro and live `caput <prefix>:MODE_SW_ENABLE` exist mainly for diagnosing a unit that seems
to ignore triggered commands entirely (as opposed to just polarity — see below).

#### Polarity mechanism: contactors vs. sign bit (e.g. DHPTB102)

The EEI regulator firmware documentation (`docs/manuals/`) shows two different converter topologies exist
in this power supply family, each with a completely different polarity mechanism:

- **Quadrupole / normal-dipole regulators** (e.g. QUATB201) switch polarity with physical contactors: this
  is the `$(P):CMD_POLARITY_POS_EXEC` / `NEG_EXEC` + `$(P):CMD_CONTACTORS_OPEN` sequence described above,
  confirmed via the `$(P):STAT_POLARITY_POS` / `NEG` contactor-state readbacks.
- **Pulsed-dipole regulators** (e.g. DHPTB102) use a solid-state H-bridge converter with **no polarity
  contactors at all** — current is reversed electronically via a sign bit on the current reference
  (`$(P):CURRENT_SP_SIGN`), committed by the same `$(P):CMD_START_RAMP` trigger used for a magnitude
  change. `$(P):STAT_POLARITY_POS`/`NEG` reflect a contactor that doesn't exist on this topology and can't
  be used to confirm a polarity change on it.

This is confirmed by `docs/manuals/170458-INFN-manuale-110319.pdf` §6.2.6.1 ("Alimentatore MPS-F per
Magneti Fast Dipoli" — the Fast/pulsed-dipole line DHPTB102 belongs to): current inversion is realized by
the DCDC-F module "without the use of electromechanical devices" and "handled automatically the instant
the Trigger command is issued" — unlike §6.2.6.2 (MPS-D/MPS-Q, contactor-based), which explicitly
restricts polarity switching to the Standby state, §6.2.6.1 states no such restriction for the sign-bit
mechanism; it's just a normal signed current-reference update like any other.

This is selected per-IOC via `$(P):CFG_POLARITY_VIA_SIGN` (in `eei_ps_unimag.template`, set with the
`POLARITY_VIA_SIGN` db macro; default `0` = contactor-based). When set, `unimagEEIControl.st` skips the
ramp-to-zero/standby/power-cycle dance entirely (`SET_SIGNED_CURRENT` state) — every setpoint just writes
`$(P):CURRENT_SP_SIGN` and the magnitude together and pulses `$(P):CMD_START_RAMP`, whether or not polarity
is actually changing, matching the manual's description that this topology has no Standby restriction and
handles inversion automatically. Polarity state is tracked internally in the SNL (`STAT_POLARITY_POS`/`NEG`
aren't consulted) since there's no hardware confirmation available for this topology.

The same split applies to the signed readback, `$(P):CURRENT_RB` (a `calc` record over `$(P):CURR_RB_RAW`,
register 40025), and it's a genuinely different relationship per topology, not just a different sign
source:
- **Sign-bit units**: `CURR_RB_RAW` is a true absolute value here (matches the Modbus map's DP01-column
  label "ABSOLUTE VALUE"), so the sign is applied from `$(P):CURRENT_RB_SIGN` (a real register for this
  topology).
- **Contactor-based units**: `CURR_RB_RAW` is *already a signed sensor reading* — the Modbus map only
  qualifies this register as "ABSOLUTE VALUE" in the DP01 column; the DH,DC/QUADS columns just say
  `curr_readout`, unqualified, and empirically it does read negative when `STAT_POLARITY_NEG` is active. So
  for this topology `CURRENT_RB` must pass `CURR_RB_RAW` through **unchanged** — applying `STAT_POLARITY_NEG`
  on top of it double-negates and silently flips the sign back to wrong. (`CURRENT_RB_SIGN` is also
  DP01-spec-only and isn't driven by contactor-based firmware at all — it just sits at its power-on default,
  which is why it must never be used for this topology either.)

Example of setting `POLARITY_VIA_SIGN` on the `eei_ps_unimag.template` load:

```
dbLoadRecords("../../db/eei_ps_unimag.template","P=BTF:MAG:EEI:DHPTB102,PORT=EEI_HOLDING_RD,PORT_WR=EEI_HOLDING_WR,POLARITY_VIA_SIGN=1")
```

See `iocBoot/psmodbusEEIIOC/st-dhptb102.cmd`.

For manual/low-level control (bypassing the sequencing above), the underlying PVs can still be driven
directly: `$(P):CURR_SET_RAW` (unsigned magnitude), `$(P):CURRENT_SP_SIGN`, and
`$(P):CMD_POLARITY_POS_REQ` / `$(P):CMD_POLARITY_NEG_REQ` (which run the contactor-open + polarity-write
sequence via a `seq` record instead of the SNL program — only meaningful on contactor-based units). This
is intended for debugging only — normal operation should go through `$(P):CURRENT_SP`.

Overall power supply state can also be read/set via the decoded `$(P):STATE_RB` (STANDBY/ON/FAULT) and
`$(P):STATE_SP` (OFF/ON/STANDBY/RESET) convenience PVs.

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
caput $(P):CURRENT_SP 10

# Monitor current (signed - matches CURRENT_SP's convention)
camonitor $(P):CURRENT_RB

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
