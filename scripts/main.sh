#!/bin/bash
bail() { echo "FATAL: $1"; exit 1; }
bash ./check.sh    || bail "unmet deps detected."
sh part.sh