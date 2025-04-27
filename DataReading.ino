// Pin Definitions
#define BUTTON_PIN 2

#define SENSOR_A_NEGATIVE 5  //A LO-
#define SENSOR_A_POSITIVE 4  //A LO+
#define SENSOR_B_NEGATIVE 7  //B LO-
#define SENSOR_B_POSITIVE 6  //B+ LO-

#define SENSOR_A_READ A0     // Analog sensor reading for Sensor A
#define SENSOR_B_READ A1     // Analog sensor reading for Sensor B

// Variables for button debounce
int lastRawReading = 1;     // Holds last button Reading
int lastStableReading = 1;  // Holds the last state reading
unsigned long lastDebounceTime = 0; // Holds the amount of time button pressed down
const unsigned long debounceDelay = 50; //is used to ignore false button presses

void setup() {
  Serial.begin(9600);
  pinMode(BUTTON_PIN, INPUT_PULLUP);  // Button

  pinMode(SENSOR_A_NEGATIVE, INPUT);  //A LO-
  pinMode(SENSOR_A_POSITIVE, INPUT);  //A LO+
  pinMode(SENSOR_B_NEGATIVE, INPUT);  //B LO-
  pinMode(SENSOR_B_POSITIVE, INPUT);  //B LO+
}

void loop() {

  // Sensor A
  if ((digitalRead(SENSOR_A_NEGATIVE) == 1) || (digitalRead(SENSOR_A_POSITIVE) == 1)) {
    Serial.print('!'); // If sensor A lead-off detected, send '!'
  } else {
    Serial.print(analogRead(SENSOR_A_READ)); // Otherwise, read and send Sensor A value
  }
  
  // Sensor B
  if ((digitalRead(SENSOR_B_NEGATIVE) == 1) || (digitalRead(SENSOR_B_POSITIVE) == 1)) {
    Serial.print('!'); // If sensor B lead-off detected, send '!'
  } else {
    Serial.print(analogRead(SENSOR_B_READ)); // Otherwise, read and send Sensor B value
  }

  // Read button value
  int currentReading = digitalRead(BUTTON_PIN);

  if (currentReading != lastRawReading) {
    lastDebounceTime = millis(); // Reset debounce timer if reading changes
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (currentReading != lastStableReading) {
      lastStableReading = currentReading;

      if (currentReading == 0) {  // if Button pressed
        Serial.print("c"); // Send 'c' when button is pressed
      }
    }
  }

  lastRawReading = currentReading; // Save current reading for next loop
  delay(10);  // small delay to avoid overwhelming the serial output
}
