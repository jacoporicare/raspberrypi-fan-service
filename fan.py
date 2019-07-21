#!/usr/bin/env python3
import RPi.GPIO as GPIO
import psutil
import argparse
import time
import signal
import sys


T_MIN = 35
T_MAX = 95

PIN_FAN = 17


parser = argparse.ArgumentParser()
parser.add_argument('--off-threshold', type=float, default=55.0,
                    help='Temperature threshold in degrees C to enable fan')
parser.add_argument('--on-threshold', type=float, default=65.0,
                    help='Temperature threshold in degrees C to disable fan')
parser.add_argument('--delay', type=float, default=2.0,
                    help='Delay, in seconds, between temperature readings')
parser.add_argument('--preempt', action='store_true', default=False,
                    help='Monitor CPU frequency and activate cooling premptively')
parser.add_argument('--verbose', action='store_true',
                    default=False, help='Output temp and fan status messages')

args = parser.parse_args()


GPIO.setmode(GPIO.BCM)
GPIO.setup(PIN_FAN, GPIO.OUT)


def clean_exit():
    set_fan(False)
    GPIO.cleanup()
    sys.exit(0)


def handle_signal(signum, frame):
    clean_exit()


def get_cpu_temp():
    t = psutil.sensors_temperatures()
    for x in ['cpu-thermal', 'cpu_thermal']:
        if x in t:
            return t[x][0].current
    print("Warning: Unable to get CPU temperature!")
    return 0


def get_cpu_freq():
    freq = psutil.cpu_freq()
    return freq


def set_fan(status):
    global enabled
    if status != enabled:
        GPIO.output(PIN_FAN, status)
    enabled = status


enabled = False
enable = False
is_fast = False
signal.signal(signal.SIGTERM, handle_signal)

try:
    while True:
        t = get_cpu_temp()
        f = get_cpu_freq()
        was_fast = is_fast
        is_fast = (int(f.current) == int(f.max))
        if args.verbose:
            print("Current: {:05.02f} Target: {:05.02f} Freq {: 5.02f} On: {}".format(
                t, args.off_threshold, f.current / 1000.0, enabled))

        if args.preempt and is_fast and was_fast:
            enable = True
        else:
            if t >= args.on_threshold:
                enable = True
            elif t <= args.off_threshold:
                enable = False

        set_fan(enable)

        time.sleep(args.delay)
except KeyboardInterrupt:
    clean_exit()
