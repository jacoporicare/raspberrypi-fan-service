#!/bin/bash
if [[ "$EUID" -ne 0 ]]; then
	>&2
	printf "Please run as root, systemd requires root access.\n"
	exit 1
fi

if ! [ -f "/usr/bin/python3" ]; then
	>&2
	printf "Fan requires Python 3\n"
	printf "You should run: 'sudo apt install python3'\n"
	exit 1
fi

ON_THRESHOLD=65
OFF_THRESHOLD=55
DELAY=2
PREEMPT="no"
POSITIONAL_ARGS=()

SERVICE_PATH=/etc/systemd/system/fan.service

while [[ $# -gt 0 ]]; do
	K="$1"
	case $K in
	-p | --preempt)
		if [ "$2" == "yes" ] || [ "$2" == "no" ]; then
			PREEMPT="$2"
			shift
		else
			PREEMPT="yes"
		fi
		shift
		;;
	--on-threshold)
		ON_THRESHOLD="$2"
		shift
		shift
		;;
	--off-threshold)
		OFF_THRESHOLD="$2"
		shift
		shift
		;;
	-d | --delay)
		DELAY="$2"
		shift
		shift
		;;
	*)
		POSITIONAL_ARGS+=("$1")
		shift
		;;
	esac
done

set -- "${POSITIONAL_ARGS[@]}"

EXTRA_ARGS=""

if [ "$PREEMPT" == "yes" ]; then
	EXTRA_ARGS+=' --preempt'
fi

cp fan.py /usr/local/bin

cat <<EOF
Setting up with:
Off Threshold: $OFF_THRESHOLD C
On Threshold: $ON_THRESHOLD C
Delay: $DELAY seconds
Preempt: $PREEMPT

To change these options, run:
sudo ./install-service.sh [--off-threshold <temp>] [--on-threshold <temp>] [--delay <seconds>] [--preempt]

Or edit: $SERVICE_PATH


EOF

read -r -d '' UNIT_FILE <<EOF
[Unit]
Description=Fan Service
After=multi-user.target

[Service]
Type=simple
WorkingDirectory=/usr/local/bin
ExecStart=/usr/local/bin/fan.py --on-threshold $ON_THRESHOLD --off-threshold $OFF_THRESHOLD --delay $DELAY $EXTRA_ARGS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

pkgs=("RPi.GPIO" "psutil")

for pkg in "${pkgs[@]}"; do
	printf "Checking for $pkg\n"
	python3 - <<EOF
import $pkg
EOF

	if [ $? -ne 0 ]; then
		printf "Installing $pkg\n"
		pip3 install "$pkg"
	else
		printf "$pkg already installed\n"
	fi
done

printf "\nInstalling service to: $SERVICE_PATH\n"
echo "$UNIT_FILE" >$SERVICE_PATH
systemctl daemon-reload
systemctl enable --no-pager fan.service
systemctl restart --no-pager fan.service
systemctl status --no-pager fan.service
