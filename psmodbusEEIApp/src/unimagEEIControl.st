program unimagEEIControl

/*
 * EPICS State Notation Language program for UNIMAG interface
 * Handles automatic polarity switching and sequencing for EEI power supply
 *
 * Per the Modbus map, COMMAND WORD #1 bit 4 (CMD_START_RAMP) is documented
 * as "START_RAMP/TRIGGER" - a single, dual-purpose commit signal. Bits 5/6
 * (CMD_CURRENT_MODE_TRIG / CMD_CURRENT_MODE_SW) are a mutually-exclusive
 * mode selector (like polarity POS/NEG): "Software" mode applies register
 * writes immediately, "Triggered" mode requires CMD_START_RAMP to commit a
 * pending write - including a polarity switch, which otherwise has no
 * commit step of its own.
 *
 * The active mode is controlled live via "{P}:MODE_SW_ENABLE" (see
 * eei_ps_unimag.template - it also applies the mode to the hardware bits),
 * monitored here so it can be changed at runtime without restarting the IOC.
 *
 * Separately, per the EEI regulator firmware docs, quadrupole/normal-dipole
 * units switch polarity with physical contactors (CMD_POLARITY_POS/NEG_EXEC
 * + CMD_CONTACTORS_OPEN, confirmed via STAT_POLARITY_POS/NEG). This requires
 * ramping to zero and dropping to standby before the contactors can safely
 * move, then powering back on - see CHECK_STATE/RAMP_TO_ZERO/GO_STANDBY/
 * CHANGE_POLARITY/GO_POWERON below.
 *
 * The pulsed-dipole H-bridge regulator (e.g. DHPTB102) has no contactors and
 * is fully bipolar: it reverses current electronically via a sign bit
 * (CURRENT_SP_SIGN) on the current reference, committed by the same
 * START_RAMP/TRIGGER bit used for a magnitude change. There is no need to
 * go to standby or sequence a contactor - every setpoint update just writes
 * sign + magnitude and pulses START_RAMP/TRIGGER (see SET_SIGNED_CURRENT
 * below). This is selected per-IOC by "{P}:CFG_POLARITY_VIA_SIGN" (set via
 * the POLARITY_VIA_SIGN db macro).
 */

option +r;  /* Make reentrant */

/* C declarations */
%% #include <math.h>

/* PV declarations */
double current_sp;
assign current_sp to "{P}:CURRENT_SP";
monitor current_sp;

double current_rb;
assign current_rb to "{P}:CURR_RB_RAW";
monitor current_rb;

double curr_set;
assign curr_set to "{P}:CURR_SET_RAW";

int curr_sign;
assign curr_sign to "{P}:CURRENT_SP_SIGN";

int stat_polarity_pos;
assign stat_polarity_pos to "{P}:STAT_POLARITY_POS";
monitor stat_polarity_pos;

int stat_polarity_neg;
assign stat_polarity_neg to "{P}:STAT_POLARITY_NEG";
monitor stat_polarity_neg;

int stat_standby;
assign stat_standby to "{P}:STAT_STANDBY";
monitor stat_standby;

int stat_power_on;
assign stat_power_on to "{P}:STAT_POWER_ON";
monitor stat_power_on;

int cmd_standby;
assign cmd_standby to "{P}:CMD_STANDBY";

int cmd_power_on;
assign cmd_power_on to "{P}:CMD_POWER_ON";

int cmd_start_ramp;
assign cmd_start_ramp to "{P}:CMD_START_RAMP";

int mode_sw_enable;
assign mode_sw_enable to "{P}:MODE_SW_ENABLE";
monitor mode_sw_enable;

int polarity_via_sign;
assign polarity_via_sign to "{P}:CFG_POLARITY_VIA_SIGN";
monitor polarity_via_sign;

int cmd_contactors_open;
assign cmd_contactors_open to "{P}:CMD_CONTACTORS_OPEN";

int cmd_polarity_pos_exec;
assign cmd_polarity_pos_exec to "{P}:CMD_POLARITY_POS_EXEC";

int cmd_polarity_neg_exec;
assign cmd_polarity_neg_exec to "{P}:CMD_POLARITY_NEG_EXEC";

int cmd_reset;
assign cmd_reset to "{P}:CMD_RESET";
monitor cmd_reset;

/* Event flags */
evflag current_sp_ef;
sync current_sp current_sp_ef;

evflag cmd_reset_ef;
sync cmd_reset cmd_reset_ef;

/* State variables */
int requested_polarity;  /* 1=positive, 2=negative */
double requested_current;
double abs_current;
int polarity_change_needed;
int timeout_counter;

/* Constants */
#define CURRENT_THRESHOLD 2.0
#define TIMEOUT_TICKS 60  /* 30 seconds with 0.5s delay */
#define POL_POSITIVE 1
#define POL_NEGATIVE 2

ss unimag_control {
    state IDLE {
        when (efTestAndClear(current_sp_ef)) {
            /* New current setpoint received */
            requested_current = current_sp;
            abs_current = fabs(requested_current);
            
            /* Determine requested polarity */
            if (requested_current >= 0) {
                requested_polarity = POL_POSITIVE;
            } else {
                requested_polarity = POL_NEGATIVE;
            }
            
            /* Check if polarity change is needed. Bipolar (polarity_via_sign)
             * units never need the contactor dance - every setpoint just
             * writes sign + magnitude and triggers (see CHECK_STATE). */
            if (polarity_via_sign) {
                polarity_change_needed = 0;
            } else {
                pvGet(stat_polarity_pos);
                pvGet(stat_polarity_neg);

                if ((requested_polarity == POL_POSITIVE && !stat_polarity_pos) ||
                    (requested_polarity == POL_NEGATIVE && !stat_polarity_neg)) {
                    polarity_change_needed = 1;
                    timeout_counter = 0;
                } else {
                    polarity_change_needed = 0;
                }
            }
        } state CHECK_STATE
        
        when (efTestAndClear(cmd_reset_ef)) {
            /* Reset command cancels all operations */
            polarity_change_needed = 0;
            timeout_counter = 0;
        } state IDLE
    }
    
    state CHECK_STATE {
        entry {
            /* Get current status */
            pvGet(stat_power_on);
            pvGet(current_rb);
        }
        
        when (polarity_via_sign) {
            /* Bipolar H-bridge unit: no contactors/standby to sequence -
             * just write sign + magnitude and trigger. */
        } state SET_SIGNED_CURRENT

        when (!polarity_change_needed) {
            /* No polarity change needed, just set current directly */
        } state SET_CURRENT_DIRECT

        when (polarity_change_needed && stat_power_on && fabs(current_rb) > CURRENT_THRESHOLD) {
            /* Need to ramp to zero first */
        } state RAMP_TO_ZERO
        
        when (polarity_change_needed && stat_power_on && fabs(current_rb) <= CURRENT_THRESHOLD) {
            /* Can go directly to standby */
        } state GO_STANDBY
        
        when (polarity_change_needed && !stat_power_on) {
            /* Already in standby or off, can change polarity */
        } state CHANGE_POLARITY
    }
    
    state RAMP_TO_ZERO {
        entry {
            /* Set current to zero and start ramp */
            curr_set = 0.0;
            pvPut(curr_set);
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
            timeout_counter = 0;
        }
        
        when (fabs(current_rb) < CURRENT_THRESHOLD) {
            /* Current reached zero */
        } state GO_STANDBY
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            printf("unimagControl: Timeout waiting for zero current\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state RAMP_TO_ZERO
    }
    
    state GO_STANDBY {
        entry {
            cmd_standby = 1;
            pvPut(cmd_standby);
            timeout_counter = 0;
        }
        
        when (delay(0.5)) {
        } state WAIT_STANDBY
    }
    
    state WAIT_STANDBY {
        when (stat_standby) {
            /* Standby confirmed */
        } state CHANGE_POLARITY
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            printf("unimagControl: Timeout waiting for standby\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_STANDBY
    }
    
    state CHANGE_POLARITY {
        entry {
            /* Contactor-based units only (bipolar/polarity_via_sign units
             * are dispatched straight to SET_SIGNED_CURRENT and never reach
             * this state) - open contactors first. */
            cmd_contactors_open = 1;
            pvPut(cmd_contactors_open);
            timeout_counter = 0;
        }

        when (delay(1.0)) {
            /* Change polarity after delay. This register is a mutually-
             * exclusive selector (OPEN/POS/NEG), so a plain write of 1 or 2
             * replaces the whole register, clearing OPEN and the other
             * polarity bit in one atomic Modbus write. */
            if (requested_polarity == POL_POSITIVE) {
                cmd_polarity_pos_exec = 1;
                pvPut(cmd_polarity_pos_exec);
            } else {
                cmd_polarity_neg_exec = 2;
                pvPut(cmd_polarity_neg_exec);
            }
            /* In Triggered mode, the polarity write above has no commit of
             * its own - pulse the START_RAMP/TRIGGER bit to apply it. */
            if (!mode_sw_enable) {
                cmd_start_ramp = 1;
                pvPut(cmd_start_ramp);
            }
        } state WAIT_POLARITY_DELAY
    }

    state WAIT_POLARITY_DELAY {
        when (delay(2.0)) {
        } state WAIT_POLARITY
    }

    state WAIT_POLARITY {
        entry {
            pvGet(stat_polarity_pos);
            pvGet(stat_polarity_neg);
        }

        when ((requested_polarity == POL_POSITIVE && stat_polarity_pos) ||
              (requested_polarity == POL_NEGATIVE && stat_polarity_neg)) {
            /* Polarity confirmed */
            polarity_change_needed = 0;
        } state GO_POWERON

        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            printf("unimagControl: Timeout waiting for polarity change\n");
        } state IDLE

        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
        } state IDLE

        when (delay(0.5)) {
            /* Keep checking */
            pvGet(stat_polarity_pos);
            pvGet(stat_polarity_neg);
        } state WAIT_POLARITY
    }
    
    state GO_POWERON {
        entry {
            cmd_power_on = 1;
            pvPut(cmd_power_on);
            timeout_counter = 0;
        }
        
        when (delay(0.5)) {
        } state WAIT_POWERON
    }
    
    state WAIT_POWERON {
        when (stat_power_on) {
            /* Power on confirmed */
        } state SET_CURRENT
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            printf("unimagControl: Timeout waiting for power on\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_POWERON
    }
    
    state SET_CURRENT {
        entry {
            /* Set the absolute current value */
            curr_set = abs_current;
            pvPut(curr_set);
        }
        
        when (delay(0.5)) {
        } state START_RAMP
    }
    
    state START_RAMP {
        entry {
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
        }

        when (delay(0.2)) {
        } state IDLE
    }
    
    state SET_CURRENT_DIRECT {
        entry {
            /* No polarity change needed, check if we need to power on */
            pvGet(stat_power_on);
            timeout_counter = 0;
        }

        when (!stat_power_on) {
            /* Need to power on first */
            cmd_power_on = 1;
            pvPut(cmd_power_on);
        } state WAIT_POWERON_DIRECT

        when (stat_power_on) {
            /* Already powered on */
            curr_set = abs_current;
            pvPut(curr_set);
        } state RAMP_DIRECT
    }

    state WAIT_POWERON_DIRECT {
        when (stat_power_on) {
            curr_set = abs_current;
            pvPut(curr_set);
        } state RAMP_DIRECT

        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - don't get stuck here forever, or every future
             * setpoint would silently be ignored (IDLE never revisited). */
            printf("unimagControl: Timeout waiting for power on (direct)\n");
        } state IDLE

        when (efTestAndClear(cmd_reset_ef)) {
        } state IDLE

        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_POWERON_DIRECT
    }
    
    state RAMP_DIRECT {
        when (delay(0.5)) {
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
        } state IDLE_DIRECT
    }
    
    state IDLE_DIRECT {
        when (delay(0.2)) {
        } state IDLE
    }

    state SET_SIGNED_CURRENT {
        entry {
            /* Bipolar H-bridge unit: reverse current electronically via the
             * sign bit on the current reference - no contactors, no standby,
             * no ramp-to-zero. Every setpoint writes sign + magnitude and
             * commits with the same START_RAMP/TRIGGER bit. */
            curr_sign = (requested_polarity == POL_POSITIVE) ? 0 : 1;
            pvPut(curr_sign);
            pvGet(stat_power_on);
            timeout_counter = 0;
        }

        when (!stat_power_on) {
            /* Need to power on first */
            cmd_power_on = 1;
            pvPut(cmd_power_on);
        } state WAIT_POWERON_SIGNED

        when (stat_power_on) {
            /* Already powered on */
            curr_set = abs_current;
            pvPut(curr_set);
        } state RAMP_SIGNED
    }

    state WAIT_POWERON_SIGNED {
        when (stat_power_on) {
            curr_set = abs_current;
            pvPut(curr_set);
        } state RAMP_SIGNED

        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - don't get stuck here forever, or every future
             * setpoint would silently be ignored (IDLE never revisited). */
            printf("unimagControl: Timeout waiting for power on (signed)\n");
        } state IDLE

        when (efTestAndClear(cmd_reset_ef)) {
        } state IDLE

        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_POWERON_SIGNED
    }

    state RAMP_SIGNED {
        when (delay(0.5)) {
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
        } state IDLE_SIGNED
    }

    state IDLE_SIGNED {
        when (delay(0.2)) {
        } state IDLE
    }
}
