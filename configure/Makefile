# Makefile

TOP = ..
include $(TOP)/configure/CONFIG

TARGETS = $(CONFIG_TARGETS)
CONFIGS += $(subst ../,,$(wildcard $(CONFIG)/*.cfg))

include $(TOP)/configure/RULES
