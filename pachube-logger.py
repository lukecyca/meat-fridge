from serial import Serial
import re
from time import sleep
import sys
import eeml
import socket

API_KEY = 'REDACTED'
API_URL = 'REDACTED'

# Define data format from arduino
READING_FORMAT = re.compile("Temperature = ([\d\.]+) C, Humidity = ([\d\.]+) \%")

class Binary(eeml.Unit):
    def __init__(self):
        eeml.Unit.__init__(self, 'Binary (On/Off)', 'derivedUnits', '')

def pachube_put(pac):
    try:
        pac.put()
    except Exception, e:
        print "Logging failed: {0}".format(e)

def log_reading(temp, hum):
    pac = eeml.Pachube(API_URL, API_KEY)
    pac.update([eeml.Data('temperature', temp, unit=eeml.Celsius()), eeml.Data('humidity', hum, unit=eeml.RH())])
    pachube_put(pac)

def log_relay(state):
    pac = eeml.Pachube(API_URL, API_KEY)
    pac.update([eeml.Data('relay', state, unit=Binary())])
    pachube_put(pac)

# Set the timeout to 10 seconds
socket.setdefaulttimeout(10)

# Use first serial device if non was specified on command line
device = 0
if len(sys.argv) > 1:
    device = sys.argv[1]

# Connect to serial port
s = Serial(device, 9600)
sleep(1)

while True:
    line = s.readline()
    parsed = READING_FORMAT.match(line)
    if parsed:
        print "Logging Reading: Temp={0} Hum={1}".format(parsed.groups()[0], parsed.groups()[1])
        log_reading(parsed.groups()[0], parsed.groups()[1])
    elif line.strip() == 'Relay On':
        log_relay(1)
        print "Logging Relay On"
    elif line.strip() == 'Relay Off':
        log_relay(0)
        print "Loggin Relay Off"
    else:
        print line.strip()
