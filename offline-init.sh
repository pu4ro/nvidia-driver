#!/bin/bash
echo ">>> OFFLINE INIT: skipping apt & downloads"
# GPU Operator가 기다리는 ready-flag 생성
mkdir -p /run/nvidia/validations
touch /run/nvidia/validations/.driver-ctr-ready
# 실제 커널 모듈 로딩
exec /usr/bin/nvidia-modprobe -u -c0
