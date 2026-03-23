#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024-2026 Bullium Consulting
###############################################################################
# Script Name: rpi_version_check.sh
# Description: Displays the Raspberry Pi model information.
# Purpose: Quickly identify the hardware model of a Raspberry Pi device.
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.1
# Date: 2025-07-08
# Support: support@bullium.com
###############################################################################

set -euo pipefail

echo '.;: Raspberry Pi Model :;. ' 
echo
cat /proc/device-tree/model | tr -d '\0'
