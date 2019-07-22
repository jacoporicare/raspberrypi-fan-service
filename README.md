# Raspberry fan service

Configurable systemd fan service written in Python.

## Installation

Just clone it and run `sudo ./install-service.sh`. Root permissions are needed because the script uses `systemctl` and copies the script to `/usr/local/bin`. You should always check the source code before you run any script from the internet.

The installation script comes with a sensible default configuration but it's easy to change it with arguments:

- `--pin N` the PIN number (BCM) of the fan (default 17)
- `--on-threshold N` the temperature at which to turn the fan on, in °C (default 65)
- `--off-threshold N` the temperature at which to turn the fan off, in °C (default 55)
- `--delay N` the delay between subsequent temperature readings, in seconds (default 2)
- `--preempt` preemptively kick in the fan when the CPU frequency is raised (default off)

Here's an example with all of them with their default values (except `--preempt` which is off by default):

```sh
sudo ./install-service.sh --pin 17 --on-threshold 65 --off-threshold 55 --delay 2 --preempt
```

If you need to change the configuration of the daemon just run this script again, it will overwrite and reload the daemon.
