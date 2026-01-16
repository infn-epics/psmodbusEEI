program unimagEEIControl

/*
 * EPICS State Notation Language program for UNIMAG interface
 * Handles automatic polarity switching and sequencing for EEI power supply
 * Enhanced with debug logging and state tracking similar to OCEM UNIMAG
 */

option +r;  /* Make reentrant */

/* C declarations */
%% #include <math.h>
%% #include <stdio.h>
%% #include <stdarg.h>
%% #include <epicsTime.h>

/* Debug level variable */
int debugLevel;
assign debugLevel to "{P}:DEBUG_LEVEL";
monitor debugLevel;

/* State machine status */
int smState;
assign smState to "{P}:SM_STATE_RB"; 

int smBusy;
assign smBusy to "{P}:SM_BUSY_RB";

string smStatusMsg;
assign smStatusMsg to "{P}:SM_STATUS_MSG";

/* PV declarations */
double current_sp;
assign current_sp to "{P}:CURRENT_SP";
monitor current_sp;

double current_rb;
assign current_rb to "{P}:CURRENT_RB";
monitor current_rb;

double curr_set;
assign curr_set to "{P}:CURR_SP_RAW";

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

/* UNIMAG State Machine States - match OCEM implementation */
#define UNIMAG_INIT          0
#define UNIMAG_OK            1  
#define UNIMAG_NOT_REACHED   2
#define UNIMAG_ZERO_STBY     3
#define UNIMAG_CHANGE_POL    4
#define UNIMAG_WAIT_POL      5
#define UNIMAG_GOING_TO_SET  6

/* Debug levels */
#define DEBUG_ERROR   0
#define DEBUG_INFO    1
#define DEBUG_DETAIL  2
#define DEBUG_TRACE   3

/* Debug logging functions */
%% static void unimagDebugLog(int level, const char* format, ...) {
%%     static int dbgLevel = 0;
%%     va_list args;
%%     char timeStr[32];
%%     epicsTimeStamp now;
%%     
%%     if (level > dbgLevel) return;
%%     
%%     epicsTimeGetCurrent(&now);
%%     epicsTimeToStrftime(timeStr, sizeof(timeStr), "%H:%M:%S.%03f", &now);
%%     
%%     printf("[%s] UNIMAG EEI: ", timeStr);
%%     va_start(args, format);
%%     vprintf(format, args);
%%     va_end(args);
%% }

ss unimag_control {
    state IDLE {
        entry {
            smState = UNIMAG_OK;
            pvPut(smState);
            smBusy = 0;
            pvPut(smBusy);
            strcpy(smStatusMsg, "Ready - monitoring");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: IDLE - Ready to process commands\n");
        }
        
        when (efTestAndClear(current_sp_ef)) {
            /* New current setpoint received */
            requested_current = current_sp;
            abs_current = fabs(requested_current);
            
            unimagDebugLog(DEBUG_INFO, "UNIMAG: New setpoint %.1f A received\n", current_sp);
            
            /* Determine requested polarity */
            if (requested_current >= 0) {
                requested_polarity = POL_POSITIVE;
                unimagDebugLog(DEBUG_DETAIL, "UNIMAG: Requested polarity: POSITIVE\n");
            } else {
                requested_polarity = POL_NEGATIVE;
                unimagDebugLog(DEBUG_DETAIL, "UNIMAG: Requested polarity: NEGATIVE\n");
            }
            
            /* Check if polarity change is needed */
            pvGet(stat_polarity_pos);
            pvGet(stat_polarity_neg);
            
            if ((requested_polarity == POL_POSITIVE && !stat_polarity_pos) ||
                (requested_polarity == POL_NEGATIVE && !stat_polarity_neg)) {
                polarity_change_needed = 1;
                timeout_counter = 0;
                unimagDebugLog(DEBUG_INFO, "UNIMAG: Polarity change required\n");
            } else {
                polarity_change_needed = 0;
                unimagDebugLog(DEBUG_INFO, "UNIMAG: Correct polarity already set\n");
            }
        } state CHECK_STATE
        
        when (efTestAndClear(cmd_reset_ef)) {
            /* Reset command cancels all operations */
            polarity_change_needed = 0;
            timeout_counter = 0;
            unimagDebugLog(DEBUG_INFO, "UNIMAG: Reset command received\n");
        } state IDLE
    }
    
    state CHECK_STATE {
        entry {
            smState = UNIMAG_NOT_REACHED;
            pvPut(smState);
            smBusy = 1;
            pvPut(smBusy);
            strcpy(smStatusMsg, "Analyzing setpoint");
            pvPut(smStatusMsg);
            
            /* Get current status */
            pvGet(stat_power_on);
            pvGet(current_rb);
            
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG State: CHECK_STATE - Power: %d, Current: %.1f A\n", 
                          stat_power_on, current_rb);
        }
        
        when (!polarity_change_needed) {
            /* No polarity change needed, just set current directly */
            unimagDebugLog(DEBUG_INFO, "UNIMAG CHECK_STATE -> SET_CURRENT_DIRECT: No polarity change\n");
        } state SET_CURRENT_DIRECT
        
        when (polarity_change_needed && stat_power_on && fabs(current_rb) > CURRENT_THRESHOLD) {
            /* Need to ramp to zero first */
            unimagDebugLog(DEBUG_INFO, "UNIMAG CHECK_STATE -> RAMP_TO_ZERO: Must zero before polarity change\n");
        } state RAMP_TO_ZERO
        
        when (polarity_change_needed && stat_power_on && fabs(current_rb) <= CURRENT_THRESHOLD) {
            /* Can go directly to standby */
            unimagDebugLog(DEBUG_INFO, "UNIMAG CHECK_STATE -> GO_STANDBY: Already at zero\n");
        } state GO_STANDBY
        
        when (polarity_change_needed && !stat_power_on) {
            /* Already in standby or off, can change polarity */
            unimagDebugLog(DEBUG_INFO, "UNIMAG CHECK_STATE -> CHANGE_POLARITY: Already powered down\n");
        } state CHANGE_POLARITY
    }
    
    state RAMP_TO_ZERO {
        entry {
            smState = UNIMAG_ZERO_STBY;
            pvPut(smState);
            strcpy(smStatusMsg, "Ramping to zero for polarity");
            pvPut(smStatusMsg);
            
            /* Set current to zero and start ramp */
            curr_set = 0.0;
            pvPut(curr_set);
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
            timeout_counter = 0;
            
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: RAMP_TO_ZERO - Zeroing current\n");
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Setting current to 0.0 A\n");
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Starting ramp to zero\n");
        }
        
        when (fabs(current_rb) < CURRENT_THRESHOLD) {
            /* Current reached zero */
            unimagDebugLog(DEBUG_INFO, "UNIMAG RAMP_TO_ZERO -> GO_STANDBY: Zero reached\n");
        } state GO_STANDBY
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            strcpy(smStatusMsg, "Timeout: ramping");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_ERROR, "UNIMAG RAMP_TO_ZERO -> IDLE: Timeout waiting for zero\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
            unimagDebugLog(DEBUG_INFO, "UNIMAG RAMP_TO_ZERO -> IDLE: Reset command\n");
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state RAMP_TO_ZERO
    }
    
    state GO_STANDBY {
        entry {
            smState = UNIMAG_ZERO_STBY;
            pvPut(smState);
            strcpy(smStatusMsg, "Going to standby");
            pvPut(smStatusMsg);
            
            cmd_standby = 1;
            pvPut(cmd_standby);
            timeout_counter = 0;
            
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: GO_STANDBY - Executing standby\n");
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Standby command issued\n");
        }
        
        when (delay(0.5)) {
            pvGet(stat_standby);
        } state WAIT_STANDBY
    }
    
    state WAIT_STANDBY {
        entry {
            strcpy(smStatusMsg, "Waiting for standby");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG State: WAIT_STANDBY - Confirming standby\n");
        }
        
        when (stat_standby) {
            /* Standby confirmed */
            unimagDebugLog(DEBUG_INFO, "UNIMAG WAIT_STANDBY -> CHANGE_POLARITY: Standby confirmed\n");
        } state CHANGE_POLARITY
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            strcpy(smStatusMsg, "Timeout: standby");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_ERROR, "UNIMAG WAIT_STANDBY -> IDLE: Timeout waiting for standby\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
            unimagDebugLog(DEBUG_INFO, "UNIMAG WAIT_STANDBY -> IDLE: Reset command\n");
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(stat_standby);
        } state WAIT_STANDBY
    }
    
    state CHANGE_POLARITY {
        entry {
            smState = UNIMAG_CHANGE_POL;
            pvPut(smState);
            strcpy(smStatusMsg, "Changing polarity");
            pvPut(smStatusMsg);
            
            /* Open contactors first */
            cmd_contactors_open = 1;
            pvPut(cmd_contactors_open);
            timeout_counter = 0;
            
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: CHANGE_POLARITY - Opening contactors\n");
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Contactors open\n");
        }
        
        when (delay(1.0)) {
            /* Change polarity after delay */
            if (requested_polarity == POL_POSITIVE) {
                cmd_polarity_pos_exec = 1;
                pvPut(cmd_polarity_pos_exec);
                unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Setting positive polarity\n");
            } else {
                cmd_polarity_neg_exec = 1;
                pvPut(cmd_polarity_neg_exec);
                unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Setting negative polarity\n");
            }
        } state WAIT_POLARITY_DELAY
    }
    
    state WAIT_POLARITY_DELAY {
        entry {
            strcpy(smStatusMsg, "Polarity command delay");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG State: WAIT_POLARITY_DELAY - Command delay\n");
        }
        
        when (delay(2.0)) {
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG WAIT_POLARITY_DELAY -> WAIT_POLARITY: Delay complete\n");
        } state WAIT_POLARITY
    }
    
    state WAIT_POLARITY {
        entry {
            smState = UNIMAG_WAIT_POL;
            pvPut(smState);
            strcpy(smStatusMsg, "Waiting for polarity confirm");
            pvPut(smStatusMsg);
            
            pvGet(stat_polarity_pos);
            pvGet(stat_polarity_neg);
            
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: WAIT_POLARITY - Confirming polarity change\n");
        }
        
        when ((requested_polarity == POL_POSITIVE && stat_polarity_pos) ||
              (requested_polarity == POL_NEGATIVE && stat_polarity_neg)) {
            /* Polarity confirmed */
            polarity_change_needed = 0;
            unimagDebugLog(DEBUG_INFO, "UNIMAG WAIT_POLARITY -> GO_POWERON: Polarity confirmed\n");
        } state GO_POWERON
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            strcpy(smStatusMsg, "Timeout: polarity");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_ERROR, "UNIMAG WAIT_POLARITY -> IDLE: Timeout waiting for polarity\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
            unimagDebugLog(DEBUG_INFO, "UNIMAG WAIT_POLARITY -> IDLE: Reset command\n");
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(stat_polarity_pos);
            pvGet(stat_polarity_neg);
        } state WAIT_POLARITY
    }
    
    state GO_POWERON {
        entry {
            strcpy(smStatusMsg, "Powering on after polarity");
            pvPut(smStatusMsg);
            
            cmd_power_on = 1;
            pvPut(cmd_power_on);
            timeout_counter = 0;
            
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: GO_POWERON - Power on command\n");
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Power on\n");
        }
        
        when (delay(0.5)) {
        } state WAIT_POWERON
    }
    
    state WAIT_POWERON {
        entry {
            strcpy(smStatusMsg, "Waiting for power on");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG State: WAIT_POWERON - Confirming power on\n");
        }
        
        when (stat_power_on) {
            /* Power on confirmed */
            unimagDebugLog(DEBUG_INFO, "UNIMAG WAIT_POWERON -> SET_CURRENT: Power confirmed\n");
        } state SET_CURRENT
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            strcpy(smStatusMsg, "Timeout: power on");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_ERROR, "UNIMAG WAIT_POWERON -> IDLE: Timeout waiting for power\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            unimagDebugLog(DEBUG_INFO, "UNIMAG WAIT_POWERON -> IDLE: Reset command\n");
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(stat_power_on);
        } state WAIT_POWERON
    }
    
    state SET_CURRENT {
        entry {
            smState = UNIMAG_GOING_TO_SET;
            pvPut(smState);
            strcpy(smStatusMsg, "Setting target");
            pvPut(smStatusMsg);
            
            /* Set the absolute current value */
            curr_set = abs_current;
            pvPut(curr_set);
            
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: SET_CURRENT - Setting %.1f A\n", abs_current);
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Current set to %.1f A\n", abs_current);
        }
        
        when (delay(0.5)) {
        } state START_RAMP
    }
    
    state START_RAMP {
        entry {
            strcpy(smStatusMsg, "Starting ramp");
            pvPut(smStatusMsg);
            
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
            
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: START_RAMP - Ramp initiated\n");
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Ramp start\n");
        }
        
        when (delay(0.2)) {
            strcpy(smStatusMsg, "Ramp complete");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_INFO, "UNIMAG START_RAMP -> IDLE: Ramp command complete\n");
        } state IDLE
    }
    
    state SET_CURRENT_DIRECT {
        entry {
            smState = UNIMAG_GOING_TO_SET;
            pvPut(smState);
            strcpy(smStatusMsg, "Direct current mode");
            pvPut(smStatusMsg);
            
            /* No polarity change needed, check if we need to power on */
            pvGet(stat_power_on);
            
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: SET_CURRENT_DIRECT - Direct path\n");
        }
        
        when (!stat_power_on) {
            /* Need to power on first */
            cmd_power_on = 1;
            pvPut(cmd_power_on);
            unimagDebugLog(DEBUG_INFO, "UNIMAG SET_CURRENT_DIRECT -> WAIT_POWERON_DIRECT: Power on needed\n");
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Power on for direct path\n");
        } state WAIT_POWERON_DIRECT
        
        when (stat_power_on) {
            /* Already powered on */
            curr_set = abs_current;
            pvPut(curr_set);
            unimagDebugLog(DEBUG_INFO, "UNIMAG SET_CURRENT_DIRECT -> RAMP_DIRECT: Already powered\n");
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Direct current set to %.1f A\n", abs_current);
        } state RAMP_DIRECT
    }
    
    state WAIT_POWERON_DIRECT {
        entry {
            strcpy(smStatusMsg, "Waiting for power on");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG State: WAIT_POWERON_DIRECT\n");
        }
        
        when (stat_power_on) {
            curr_set = abs_current;
            pvPut(curr_set);
            unimagDebugLog(DEBUG_INFO, "UNIMAG WAIT_POWERON_DIRECT -> RAMP_DIRECT: Power confirmed\n");
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Current set to %.1f A (direct)\n", abs_current);
        } state RAMP_DIRECT
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(stat_power_on);
        } state WAIT_POWERON_DIRECT
    }
    
    state RAMP_DIRECT {
        entry {
            strcpy(smStatusMsg, "Direct ramp");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_INFO, "UNIMAG State: RAMP_DIRECT - Direct ramp\n");
        }
        
        when (delay(0.5)) {
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
            unimagDebugLog(DEBUG_DETAIL, "UNIMAG Command: Direct ramp start\n");
        } state IDLE_DIRECT
    }
    
    state IDLE_DIRECT {
        entry {
            strcpy(smStatusMsg, "Ramp initiated");
            pvPut(smStatusMsg);
            unimagDebugLog(DEBUG_INFO, "UNIMAG RAMP_DIRECT -> IDLE: Direct ramp complete\n");
        }
        
        when (delay(0.2)) {
        } state IDLE
    }
}
