#include <Sensirion.h>

#define shtClockPin 4
#define shtDataPin  5
#define shtPowerPin 10
#define relayPin    11
#define statusLEDPinA 12
#define statusLEDPinB 13

#define tempCheckFrequency 20000
#define tempRangeLow 10.0
#define tempRangeHigh 11.0

Sensirion sht = Sensirion(shtDataPin, shtClockPin);
byte error = 0;

byte relayState = 0;


void setup() {
    // Initialize I/O
    pinMode(shtPowerPin, OUTPUT);
    pinMode(relayPin, OUTPUT);
    pinMode(statusLEDPinA, OUTPUT);
    pinMode(statusLEDPinB, OUTPUT);
    delay(5000);
    Serial.begin(9600);
    
    // Turn on sht1x
    delay(20);
    digitalWrite(shtPowerPin, HIGH);
    
    // Initialize sht1x
    delay(20);
    logStatusRegister();
    if (error = sht.writeSR(LOW_RES))      // Set sensor to low resolution
        logError(error);
    logStatusRegister();
}

void loop() {
    unsigned int rawData;
    float temperature;
    float humidity;
    
    statusGreen();
    
    if (error = sht.measTemp(&rawData)) {
        logError(error);
        return;
    }
    temperature = sht.calcTemp(rawData);
    if (error = sht.measHumi(&rawData)) {
        logError(error);
        return;
    }
    humidity = sht.calcHumi(rawData, temperature);
    
    Serial.print("Temperature = ");   Serial.print(temperature);
    Serial.print(" C, Humidity = ");  Serial.print(humidity);
    Serial.println(" %");
    
    if (temperature > tempRangeHigh)
        relayOn();
    else if (temperature <= tempRangeLow)
        relayOff();
        
    statusOff();
    delay(tempCheckFrequency);
}

void logStatusRegister() {
    byte stat;
    if (error = sht.readSR(&stat))
        logError(error);
    Serial.print("Status reg = 0x");
    Serial.println(stat, HEX);
}

void logError(byte error) {
    statusRed();
    
    switch (error) {
    case S_Err_NoACK:
        Serial.println("Error: No response (ACK) received from sensor!");
        break;
    case S_Err_CRC:
        Serial.println("Error: CRC mismatch!");
        break;
    case S_Err_TO:
        Serial.println("Error: Measurement timeout!");
        break;
    default:
        Serial.println("Unknown error received!");
        break;
    }
    
    Serial.println("Resetting sht1x sensor");
    digitalWrite(shtPowerPin, LOW);
    digitalWrite(shtClockPin, LOW);
    digitalWrite(shtDataPin, LOW);
    delay(10000);
    digitalWrite(shtPowerPin, HIGH);
    sht = Sensirion(shtDataPin, shtClockPin);
}

void statusGreen() {
    digitalWrite(statusLEDPinA, LOW);
    digitalWrite(statusLEDPinB, HIGH);
}
void statusRed() {
    digitalWrite(statusLEDPinB, LOW);
    digitalWrite(statusLEDPinA, HIGH);
}
void statusOff() {
    digitalWrite(statusLEDPinA, LOW);
    digitalWrite(statusLEDPinB, LOW);
}
void relayOn() {
    if (relayState != 1) {
        relayState = 1;
        digitalWrite(relayPin, HIGH);
        Serial.println("Relay On");
    }
}
void relayOff() {
    if (relayState != 0) {
        relayState = 0;
        digitalWrite(relayPin, LOW);
        Serial.println("Relay Off");
    }
}
