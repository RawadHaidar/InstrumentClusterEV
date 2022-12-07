/****************************************************************************
CAN Read Demo for the SparkFun CAN Bus Shield. 

Written by Stephen McCoy. 
Original tutorial available here: http://www.instructables.com/id/CAN-Bus-Sniffing-and-Broadcasting-with-Arduino
Used with permission 2016. License CC By SA. 

Distributed as-is; no warranty is given.
*************************************************************************/

#include <Canbus.h>
#include <defaults.h>
#include <global.h>
#include <mcp2515.h>
#include <mcp2515_defs.h>
int x;
int RPMforward;
int RPMReverse;
int Gear_ratio;
float wheel_raduis_meter=0.78; 
float SpeedForward;
float SpeedReverse;

//********************************Setup Loop*********************************//

void setup() {
  pinMode(6,INPUT);
  pinMode(7,INPUT);

  Serial.begin(115200); // For debug use
    
  delay(1000);
  
  if(Canbus.init(CANSPEED_500))  //Initialise MCP2515 CAN controller at the specified speed
    
    
  delay(1000);
}

//********************************Main Loop*********************************//

void loop(){

  tCAN message;
if (mcp2515_check_message()) 
  {
    if (mcp2515_get_message(&message)) 
  {
        if(message.id == 0x6B5)  // filtering message from the inverter 
             {
                  x=(255-message.data[5])*255;
                  if(message.data[5]<200){
                    RPMforward=(message.data[4])+((message.data[5]*250));// RPM value as inverter
                    Gear_ratio=9;
                    wheel_raduis_meter=0.78;
                    SpeedForward=(((((RPMforward/Gear_ratio)*3.14)/60)*wheel_raduis_meter)*3.6);
                    //Serial.println((message.data[4])+((message.data[5]*250)),DEC);//RPM forward
                    Serial.println(SpeedForward);//Speed forward
                  }
                  if(message.data[5]>200){
                    RPMReverse=((259-message.data[4])+x);
                    Gear_ratio=9;
                    wheel_raduis_meter=0.78;
                    SpeedReverse=(((((RPMReverse/Gear_ratio)*3.14)/60)*wheel_raduis_meter)*3.6);
                    Serial.println(SpeedReverse);
                    //Serial.println(((255-message.data[4])+x),DEC);// RPM Reverse
                  } 
                  Serial.println(message.data[1],DEC);//Throttle Req in %
                  Serial.println(message.data[2],DEC);// SOC from inverter
                  Serial.println(message.data[3],DEC);// fault code
                  Serial.println((message.data[6]*0.1));// DC-BUS current
                  
                  if(digitalRead(6)== LOW){
                    Serial.println('D');
                    }else if (digitalRead(7)== LOW){
                      Serial.println('R');
                    }else if(digitalRead(6)== HIGH && digitalRead(7)== HIGH){
                      Serial.println('N');
                    }
                  //Serial.println(RPMforward);
                  //Serial.println(RPMReverse);
                 // Serial.println("");
             }
           }}

}
