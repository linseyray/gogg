import cc.arduino.*;
import org.firmata.*;
import processing.serial.*;

Arduino arduino;

/*************************************************
             GENERAL CONSTANTS / VARS
 ************************************************/
int deltaTime = 0;    // Time elapsed of this drawing cycle
int timeElapsed = 0;

int LED_ON = Arduino.HIGH;
int LED_OFF = Arduino.LOW;

// LED/pin numbers (on Arduino)
final int LEFT_PILLAR_LED = 13;   // Red
final int FLOOR_RED_LED = 12;     // Red
final int FLOOR_BLUE_LED = 11;    // Blue
final int FRONT_WALL_LED1 = 10;   // Blue
final int FRONT_WALL_LED2 = 9;    // Blue
final int RIGHT_WALL_LED1 = 8;    // Blue
final int RIGHT_WALL_LED2 = 7;    // Blue
final int RIGHT_PILLAR_LED = 6;    // Red

// Letter keycodes (on keyboard)
// Can be used to control the LEDs directly
final int KEY_C = 67;     
final int KEY_D = 68;    
final int KEY_R = 82;   
final int KEY_T = 84;  
final int KEY_Y = 89; 
final int KEY_U = 85;
final int KEY_J = 74;
final int KEY_N = 78;

// Button keycodes (on keyboard)
final int BUTTON_1 = 17;
final int BUTTON_2 = 18;
final int BUTTON_3 = 32;
final int BUTTON_4 = 16;
final int BUTTON_5 = 81;
final int BUTTON_6 = 83;
final int BUTTON_7 = 65;
final int BUTTON_8 = 90;

final int START_FLASH_SPEED = 1000;

public class Button {
    public boolean on = false;
    public int buttonNumber = 0;
    public int ledNumber = 0;
    public int keyCode = 0;
    private boolean flashing = false;
    private int flashSpeed = START_FLASH_SPEED;
    private int timeSinceLastFlash = 0;

    public Button(int buttonNumber, int ledNumber, int keyCode) {
        this.buttonNumber = buttonNumber;
        this.ledNumber = ledNumber;
        this.keyCode = keyCode;
    }

    public void setLed(boolean on) {
        this.on = on;
        int state = on ? LED_ON : LED_OFF;
        arduino.digitalWrite(ledNumber, state);
    }

    public void toggleLed() {
        setLed(!on);
    }

    public void startFlashing() {
        flashing = true;
        timeSinceLastFlash = 0;
    }

    public void stopFlashing() {
        flashing = false;
        timeSinceLastFlash = 0;
    }

    public void flash(int deltaTime) {
        timeSinceLastFlash += deltaTime;
        if (timeSinceLastFlash >= flashSpeed) {
            toggleLed();
            timeSinceLastFlash = 0;
        }
    }
};

// Short-cut button indices
// int to Enum    ButtonName.values()[index];
// Enum to int    buttonName.ordinal();
enum ButtonName {
    LEFT_PILLAR,    // Red
    FLOOR_RED,      // Red
    FLOOR_BLUE,     // Blue
    FRONT_WALL_1,   // Blue
    FRONT_WALL_2,   // Blue
    RIGHT_WALL_1,   // Blue
    RIGHT_WALL_2,   // Blue
    RIGHT_PILLAR    // Red
};

int[] RED_LED_NUMBERS = { 13, 12, 6};
int[] BLUE_LED_NUMBERS = { 11, 10, 9, 8, 7};
ButtonName[] RED_BUTTONS = { 
    ButtonName.LEFT_PILLAR, 
    ButtonName.FLOOR_RED, 
    ButtonName.RIGHT_PILLAR 
};
ButtonName[] BLUE_BUTTONS = { 
    ButtonName.FLOOR_BLUE, 
    ButtonName.FRONT_WALL_1, 
    ButtonName.FRONT_WALL_2,
    ButtonName.RIGHT_WALL_1, 
    ButtonName.RIGHT_WALL_2 
};

// Set the button information
Button[] buttons = {
    new Button(BUTTON_1, LEFT_PILLAR_LED, KEY_C),
    new Button(BUTTON_2, FLOOR_RED_LED, KEY_D),
    new Button(BUTTON_3, FLOOR_BLUE_LED, KEY_R),
    new Button(BUTTON_4, FRONT_WALL_LED1, KEY_T),
    new Button(BUTTON_5, FRONT_WALL_LED2, KEY_Y),
    new Button(BUTTON_6, RIGHT_WALL_LED1, KEY_U),
    new Button(BUTTON_7, RIGHT_WALL_LED2, KEY_J),
    new Button(BUTTON_8, RIGHT_PILLAR_LED, KEY_N)
};

/*************************************************
            GAME CONSTANTS
 ************************************************/
                
/*************************************************
                SETUP
 ************************************************/
void setup(){
    arduino = new Arduino(this, Arduino.list()[0], 57600);  

    // Set all the pins we'll use as output pins
    arduino.pinMode(13, Arduino.OUTPUT);
    arduino.pinMode(12, Arduino.OUTPUT); 
    arduino.pinMode(11, Arduino.OUTPUT);
    arduino.pinMode(10, Arduino.OUTPUT); 
    arduino.pinMode(9, Arduino.OUTPUT);
    arduino.pinMode(8, Arduino.OUTPUT); 
    arduino.pinMode(7, Arduino.OUTPUT);
    arduino.pinMode(6, Arduino.OUTPUT); 
}

/*************************************************
                GAME LOOP
 ************************************************/

void draw() {
    if (timeElapsed <= 0) {
        for (Button button : buttons) {
            button.startFlashing();
        }
    }

    deltaTime = millis() - timeElapsed;
    timeElapsed = millis();

    //alternateLedsPerColour();
    //checkLedStates();
    flashLeds(deltaTime);
}

/*************************************************
               STATE CHECKS 
 ************************************************/
void checkLedStates() {
    if (allRedsOn() && allBluesOff())
        println("BOOOOOOOOOM");   // EXPLODE???

    if (allBluesOn() && allRedsOff())
        println("uwin?");   // win?

    if (bluesOnFrontWallOn()) 
        println("BLUES ON FRONT WALL ON");

    if (bluesOnRightWallOn()) 
        println("BLUES ON RIGHT WALL ON");

}

boolean allRedsOn() {
    for (ButtonName buttonName: RED_BUTTONS) 
        if (!buttons[buttonName.ordinal()].on)
            return false;
    return true;
}

boolean allBluesOn() {
    for (ButtonName buttonName: BLUE_BUTTONS) {
        if (!buttons[buttonName.ordinal()].on)
            return false;
    }
    return true;
}

boolean allRedsOff() {
    for (ButtonName buttonName: RED_BUTTONS) 
        if (buttons[buttonName.ordinal()].on)
            return false;
    return true;
}

boolean allBluesOff() {
    for (ButtonName buttonName: BLUE_BUTTONS) 
        if (buttons[buttonName.ordinal()].on)
            return false;
    return true;
}

boolean bluesOnFrontWallOn() {
    return buttons[ButtonName.FRONT_WALL_1.ordinal()].on &&
           buttons[ButtonName.FRONT_WALL_2.ordinal()].on;
}

boolean bluesOnRightWallOn() {
    return buttons[ButtonName.RIGHT_WALL_1.ordinal()].on &&
           buttons[ButtonName.RIGHT_WALL_2.ordinal()].on;
}


/*************************************************
                  INPUT
 ************************************************/
void keyPressed() {
    println(keyCode);

    for (Button button : buttons) {
        if (keyCode == button.keyCode ||    // Moderator turned on/off a led
            keyCode == button.buttonNumber) // Player pressed one of the buttons
            button.toggleLed();
    }
}

void keyReleased() {
}


/*************************************************
                LED FUNCTIONS
 ************************************************/
void turnLedsOn(ButtonName[] buttonNames) {
    for (ButtonName buttonName: buttonNames) 
        buttons[buttonName.ordinal()].setLed(true);
}

void turnLedsOff(ButtonName[] buttonNames) {
    for (ButtonName buttonName: buttonNames) 
        buttons[buttonName.ordinal()].setLed(false);
}

void alternateLedsPerColour() {
    turnLedsOn(RED_BUTTONS);
    delay(250);
    turnLedsOff(RED_BUTTONS);

    turnLedsOn(BLUE_BUTTONS);
    delay(250);
    turnLedsOff(BLUE_BUTTONS);
}

void randomizeLeds() {
}

// TODO
void flashLeds(int deltaTime) {
    for (Button button : buttons) {
        if (button.flashing)
            button.flash(deltaTime);
    }
}

