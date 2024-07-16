#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

BLEServer* pServer = NULL;

// Read Operations
BLECharacteristic* pCharacteristic_Product_Id = NULL;             //
BLECharacteristic* pCharacteristic_BMS_State = NULL;              //
BLECharacteristic* pCharacteristic_Battery_Voltage = NULL;        // // // -- >>
BLECharacteristic* pCharacteristic_Battery_Temperature = NULL;    // // //
BLECharacteristic* pCharacteristic_Battery_Health_Status = NULL;  // // // >>
BLECharacteristic* pCharacteristic_Pack_Total_Cap = NULL;         // // //
BLECharacteristic* pCharacteristic_Battery_CycleCount = NULL;     //
BLECharacteristic* pCharacteristic_BMS_Fault = NULL;              // // //
BLECharacteristic* pCharacteristic_Battery_Current = NULL;        // // -- >>
BLECharacteristic* pCharacteristic_Pack_Remaining_Cap = NULL;     // // >>
BLECharacteristic* pCharacteristic_Battery_FullCharge = NULL;     //
BLECharacteristic* pCharacteristic_Charging_Prof_cc = NULL;       //
BLECharacteristic* pCharacteristic_Charging_Prof_cv = NULL;       //
BLECharacteristic* pCharacteristic_Cell1_Voltage = NULL;          // -- >>
BLECharacteristic* pCharacteristic_Cell2_Voltage = NULL;          // -- >>
BLECharacteristic* pCharacteristic_Cell3_Voltage = NULL;          // -- >>
BLECharacteristic* pCharacteristic_Cell4_Voltage = NULL;          // -- >>
BLECharacteristic* pCharacteristic_Cell5_Voltage = NULL;          // -- >>
BLECharacteristic* pCharacteristic_Cell6_Voltage = NULL;          // -- >>
BLECharacteristic* pCharacteristic_Cell7_Voltage = NULL;          // -- >>
BLECharacteristic* pCharacteristic_Cell8_Voltage = NULL;          // -- >>
BLECharacteristic* pCharacteristic_Cell9_Voltage = NULL;          // -- >>
BLECharacteristic* pCharacteristic_Cell10_Voltage = NULL;         // -- >>
BLECharacteristic* pCharacteristic_Cell11_Voltage = NULL;         // -- >>
BLECharacteristic* pCharacteristic_Cell12_Voltage = NULL;         // -- >>
BLECharacteristic* pCharacteristic_Cell13_Voltage = NULL;         // -- >>
BLECharacteristic* pCharacteristic_Cell14_Voltage = NULL;         // -- >>
BLECharacteristic* pCharacteristic_Cell15_Voltage = NULL;         // -- >>
BLECharacteristic* pCharacteristic_Cell16_Voltage = NULL;         // -- >>
BLECharacteristic* pCharacteristic_Battery_Discharge = NULL;      //

BLECharacteristic* pCharacteristic_Drone_Status = NULL;     // >>
BLECharacteristic* pCharacteristic_Charging_Status = NULL;  // >>

// Write Operations
BLECharacteristic* pCharacteristic_Battery_Cell_Nos = NULL;               // --
BLECharacteristic* pCharacteristic_Battery_Cap = NULL;                    //
BLECharacteristic* pCharacteristic_Battery_Constant_Current = NULL;       //
BLECharacteristic* pCharacteristic_Battery_Peak_Current = NULL;           //
BLECharacteristic* pCharacteristic_Battery_Max_Voltage = NULL;            //
BLECharacteristic* pCharacteristic_Battery_Min_Voltage = NULL;            //
BLECharacteristic* pCharacteristic_Battery_Operating_Temperature = NULL;  //
BLECharacteristic* pCharacteristic_BMS_Id = NULL;                         //
BLECharacteristic* pCharacteristic_Battery_Id = NULL;                     //
BLECharacteristic* pCharacteristic_Battery_DSG_C = NULL;                  //
BLECharacteristic* pCharacteristic_Battery_CHG_C = NULL;                  //
BLECharacteristic* pCharacteristic_DSG_OverCurrent = NULL;                //
BLECharacteristic* pCharacteristic_CHG_OverVoltage = NULL;                //
BLECharacteristic* pCharacteristic_DSG_OverTemperature = NULL;            //
BLECharacteristic* pCharacteristic_CHG_OverTemperature = NULL;            //
BLECharacteristic* pCharacteristic_DSG_UnderVoltage = NULL;               //
BLECharacteristic* pCharacteristic_SOC = NULL;                            //

BLECharacteristic* pCharacteristic_Algox_Cell_Nos = NULL;  //      --
BLECharacteristic* pCharacteristic_Charging_type = NULL;   //     --
BLECharacteristic* pCharacteristic_Cell_Chemistry = NULL;  //     --
BLECharacteristic* pCharacteristic_Algox_Current = NULL;   //     --
BLECharacteristic* pCharacteristic_Start_Charging = NULL;  //     --

// initialization
bool deviceConnected = false;
bool oldDeviceConnected = false;
uint32_t value = 0;

//Read
uint16_t Product_Id = 0;
uint16_t BMS_State = 0;
uint16_t Battery_Voltage = 0;
uint16_t Battery_Temperature = 0;
uint16_t Battery_Health_Status = 0;
uint16_t Pack_Total_Cap = 0;
uint16_t Battery_CycleCount = 0;
uint16_t BMS_Fault = 0;
uint16_t Battery_Current = 0;
uint16_t Pack_Remaining_Cap = 0;
uint16_t Battery_FullCharge = 0;
uint16_t Charging_Prof_cc = 0;
uint16_t Charging_Prof_cv = 0;
uint16_t Battery_Discharge = 0;

uint8_t Drone_Status = 0;
uint8_t Charging_Status = 0;

// Cell Voltages
uint16_t Cell1_Voltage = 0;   //
uint16_t Cell2_Voltage = 0;   //
uint16_t Cell3_Voltage = 0;   //
uint16_t Cell4_Voltage = 0;   //
uint16_t Cell5_Voltage = 0;   //
uint16_t Cell6_Voltage = 0;   //
uint16_t Cell7_Voltage = 0;   //
uint16_t Cell8_Voltage = 0;   //
uint16_t Cell9_Voltage = 0;   //
uint16_t Cell10_Voltage = 0;  //
uint16_t Cell11_Voltage = 0;  //
uint16_t Cell12_Voltage = 0;  //
uint16_t Cell13_Voltage = 0;  //
uint16_t Cell14_Voltage = 0;  //
uint16_t Cell15_Voltage = 0;  //
uint16_t Cell16_Voltage = 0;  //

// Write
uint16_t Battery_Cell_Nos = 0;
uint16_t Battery_Cap = 0;
uint16_t Battery_Constant_Current = 0;
uint16_t Battery_Peak_Current = 0;
uint16_t Battery_Max_Voltage = 0;
uint16_t Battery_Min_Voltage = 0;
uint16_t Battery_Operating_Temperature = 0;
uint16_t Battery_ID = 0;
uint16_t BMS_ID = 0;

uint16_t DSG_OverCurrent = 0;
uint16_t CHG_OverVoltage = 0;
uint16_t DSG_OverTemperature = 0;
uint16_t CHG_OverTemperature = 0;
uint16_t DSG_UnderVoltage = 0;
uint16_t Battery_DSG_C = 0;
uint16_t Battery_CHG_C = 0;
uint16_t SOC = 0;

uint16_t Algox_Cell_Nos = 0;
uint16_t Charging_type = 0;
uint16_t Cell_Chemistry = 0;
uint16_t Algox_Current = 0;
uint16_t Start_Charging = 0;

#define SERVICE_UUID "66eae0f3-bea4-496e-ac81-d591677dd9aa"

#define Product_Id_UUID "a4beceb7-689d-4e1f-bee6-b59358dde0ea"             //
#define BMS_State_UUID "606d63cb-6f2c-42d0-9a1d-c3c20749c487"              //
#define Battery_Voltage_UUID "6c1e0a36-f854-49f2-a78f-3db43f6424b1"        // // //
#define Battery_Temperature_UUID "ee24bdeb-7408-4cec-8186-27e01bf301d7"    // // //
#define Battery_Health_Status_UUID "96ff5f4c-4830-4ec1-95d8-8f92a4bba717"  // // //
#define Pack_Total_Cap_UUID "0494e147-8541-4917-be37-09540a7f3161"         // // //
#define Battery_CycleCount_UUID "0492a1ac-d680-4e46-a28d-0422753dd0b3"     //
#define BMS_Fault_UUID "28fcf388-dbe0-4453-a1aa-7f41116e0e58"              // // //
#define Battery_Current_UUID "ffe56b2d-0607-428f-ba10-7a76268c4420"        // //
#define Pack_Remaining_Cap_UUID "2e2cb9b4-02d9-4ac3-a97e-52f3c6b0c51e"     // //
#define Battery_FullCharge_UUID "79bda1ab-8b37-421a-83b7-01c1980bdec1"     //
#define Charging_Prof_CV_UUID "c628e8ca-6c4e-4cda-88b1-6ca0f9320855"       //
#define Charging_Prof_CC_UUID "16423408-9605-4312-a369-45bcacd6a880"       //
#define Cell1_Voltage_UUID "59878c02-5bfc-42c1-9c91-861b3f262ee0"          //
#define Cell2_Voltage_UUID "9bc4eb20-faef-48a3-a2d3-04a4977225d6"          //
#define Cell3_Voltage_UUID "dd5d4670-160e-4304-8a09-bbadfc7c1dec"          //
#define Cell4_Voltage_UUID "a3c48189-4ee2-40e1-86ee-7291fb61939d"          //
#define Cell5_Voltage_UUID "a1d5d1fa-691b-4f82-8c6e-98945243d711"          //
#define Cell6_Voltage_UUID "7d7f5064-9f05-4723-8c9a-49ca699a7535"          //
#define Cell7_Voltage_UUID "df8de357-450d-4373-bf3b-d3fcbb61d4a7"          //
#define Cell8_Voltage_UUID "6d3efe3d-e699-49ee-a01a-df60700305be"          //
#define Cell9_Voltage_UUID "3b9c753a-53cb-4a55-aed6-2f6609250341"          //
#define Cell10_Voltage_UUID "35496015-80bd-43b3-91ee-50aadb953ed8"         //
#define Cell11_Voltage_UUID "a69b3c58-36ef-4b22-ad0b-dbb0af5dbacd"         //
#define Cell12_Voltage_UUID "9452d6c5-3467-41f1-96fe-91df261efbcf"         //
#define Cell13_Voltage_UUID "0bc76b72-e9a7-4be7-bf53-0d0c897d8a5c"         //
#define Cell14_Voltage_UUID "a13f06e2-a6a8-4ecf-a130-441ab94f337d"         //
#define Cell15_Voltage_UUID "1d6a23ef-523d-446c-93c0-53eebad0eca9"         //
#define Cell16_Voltage_UUID "4c776ff8-7448-4ba0-b238-1010b4a62297"         //
#define Battery_Discharge_UUID "24688ee9-9c1d-45bf-ba47-2b36cb92ace5"      //

#define Drone_Status_UUID "1efa6f0c-2ab4-44ca-8153-71b32678c4c3"     //
#define Charging_Status_UUID "cc32c0bb-218b-4b7f-808c-63dc94dd5c08"  //

// Write
#define Bat_Cell_Nos_UUID "6bd6c397-e8dc-4d41-991d-8f2e887b7061"
#define Battery_Cap_UUID "0731d816-a269-4397-a7e5-0d1bf16310be"
#define Battery_Constant_Current_UUID "fd049ff1-670c-40fe-98b8-00504699f8c1"
#define Battery_Peak_Current_UUID "08b3b2fe-8fce-4393-b554-a31429b35d45"
#define Bat_Max_Vol_UUID "d9dbad81-4b0d-4e3b-b438-3a1170981179"
#define Bat_Min_Vol_UUID "751eafc6-1a1d-4a5e-8df1-4e6ee1f479d1"
#define Bat_Operating_Temp_UUID "73e469a2-b1c2-4119-8be7-f325f75b8374"
#define Bat_ID_UUID "2277ad1c-a8fd-48c3-9c1c-bddafa72922f"
#define BMS_ID_UUID "d7e138fa-a4c2-482d-a8ee-f62429d4bdf4"
#define Bat_CHG_C_UUID "435ddd69-c9c1-498c-9889-a63d97dea0ed"

#define DSG_OverCurrent_UUID "ed360ed8-8b14-4c3a-b39e-076ea97e782a"
#define CHG_OverVoltage_UUID "86435c8e-33b2-49f1-af7a-e54ef290a66e"
#define DSG_OverTemperature_UUID "38b4df1e-08c8-4b33-8d71-654660afede1"
#define CHG_OverTemperature_UUID "c00e4792-2ee8-4cd1-9bd6-803ac9fd113e"
#define DSG_UnderVoltage_UUID "f9e62d2c-82f6-4cb4-ae6c-4b5b19b4c918"

#define Bat_DSG_C_UUID "6fc9cfaf-cbf9-4c28-866d-6ef4e4e5440a"
#define SOC_UUID "14df897e-b1cc-4b16-8df0-d032bc92a875"

#define Charging_type_UUID "26b83d0d-4d66-45f2-8afb-32f1fed254aa"
#define Cell_Chemistry_UUID "4b9eba9d-3523-4311-ba81-9e4e18d5f491"
#define Algox_Cell_Nos_UUID "d57ec39e-8789-4aa6-89de-5d2ea01fa5aa"
#define Algox_Current_UUID "ad187c83-f94f-49fe-a686-6ab132447069"
#define Start_Charging_UUID "9027cc8b-da21-4c8a-95c2-44fc448834f4"

#define FW_Update_UUID "26b83d0d-4d66-45f2-8afb-32f1fed254aa"

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
  };

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
  }
};

class myCharCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    BLEUUID charID = pCharacteristic->getUUID();
    std::string value = pCharacteristic->getValue();
    // Modify the write functionality based on the characteristic UUID
    if (charID.equals(BLEUUID(Bat_Cell_Nos_UUID))) {
      // Modify Battery_Cell_Nos
      Battery_Cell_Nos = std::stoul(value);
      Serial.println(Battery_Cell_Nos);

    } else if (charID.equals(BLEUUID(Battery_Cap_UUID))) {
      // Modify Battery_Cap
      Battery_Cap = std::stoul(value);
      Serial.println(Battery_Cap);

    } else if (charID.equals(BLEUUID(Battery_Constant_Current_UUID))) {
      // Modify Battery_Constant_Current
      Battery_Constant_Current = std::stoul(value);
      Serial.println(Battery_Constant_Current);

    } else if (charID.equals(BLEUUID(Battery_Peak_Current_UUID))) {
      // Modify Battery_Peak_Current
      Battery_Peak_Current = std::stoul(value);
      Serial.println(Battery_Peak_Current);

    } else if (charID.equals(BLEUUID(Bat_Max_Vol_UUID))) {
      // Modify Battery_Max_Voltage
      Battery_Max_Voltage = std::stoul(value);
      Serial.println(Battery_Max_Voltage);

    } else if (charID.equals(BLEUUID(Bat_Min_Vol_UUID))) {
      // Modify Battery_Min_Voltage
      Battery_Min_Voltage = std::stoul(value);
      Serial.println(Battery_Min_Voltage);

    } else if (charID.equals(BLEUUID(Bat_Operating_Temp_UUID))) {
      // Modify Battery_Operating_Temperature
      Battery_Operating_Temperature = std::stoul(value);
      Serial.println(Battery_Operating_Temperature);

    } else if (charID.equals(BLEUUID(Bat_ID_UUID))) {
      // Modify Battery_ID
      Battery_ID = std::stoul(value);
      Serial.println(Battery_ID);

    } else if (charID.equals(BLEUUID(BMS_ID_UUID))) {
      // Modify BMS_ID
      BMS_ID = std::stoul(value);
      Serial.println(BMS_ID);

    } else if (charID.equals(BLEUUID(Bat_CHG_C_UUID))) {
      // Modify Battery_CHG_C
      Battery_CHG_C = std::stoul(value);
      Serial.println(Battery_CHG_C);

    } else if (charID.equals(BLEUUID(Bat_DSG_C_UUID))) {
      // Modify Battery_DSG_C
      Battery_DSG_C = std::stoul(value);
      Serial.println(Battery_DSG_C);

    } else if (charID.equals(BLEUUID(DSG_OverCurrent_UUID))) {
      // Modify DSG_OverCurrent
      DSG_OverCurrent = std::stoul(value);
      Serial.println(DSG_OverCurrent);

    } else if (charID.equals(BLEUUID(CHG_OverVoltage_UUID))) {
      // Modify CHG_OverVoltage
      CHG_OverVoltage = std::stoul(value);
      Serial.println(CHG_OverVoltage);

    } else if (charID.equals(BLEUUID(DSG_OverTemperature_UUID))) {
      // Modify DSG_OverTemperature
      DSG_OverTemperature = std::stoul(value);
      Serial.println(DSG_OverTemperature);

    } else if (charID.equals(BLEUUID(CHG_OverTemperature_UUID))) {
      // Modify CHG_OverTemperature
      CHG_OverTemperature = std::stoul(value);
      Serial.println(CHG_OverTemperature);

    } else if (charID.equals(BLEUUID(DSG_UnderVoltage_UUID))) {
      // Modify DSG_UnderVoltage
      DSG_UnderVoltage = std::stoul(value);
      Serial.println(DSG_UnderVoltage);

    } else if (charID.equals(BLEUUID(SOC_UUID))) {
      // Modify SOC
      SOC = std::stoul(value);
      Serial.println(SOC);

    } else if (charID.equals(BLEUUID(Charging_type_UUID))) {
      // Modify Charging_type
      Charging_type = std::stoul(value);
      Serial.println(Charging_type);

    } else if (charID.equals(BLEUUID(Cell_Chemistry_UUID))) {
      // Modify Cell_Chemistry
      Cell_Chemistry = std::stoul(value);
      Serial.println(Cell_Chemistry);

    } else if (charID.equals(BLEUUID(Algox_Cell_Nos_UUID))) {
      // Modify Algox_Cell_Nos
      Algox_Cell_Nos = std::stoul(value);
      Serial.println(Algox_Cell_Nos);

    } else if (charID.equals(BLEUUID(Algox_Current_UUID))) {
      // Modify Algox_Current
      Algox_Current = std::stoul(value);
      Serial.println(Algox_Current);

    } else if (charID.equals(BLEUUID(Start_Charging_UUID))) {
      // Modify Start_Charging
      Start_Charging = std::stoul(value);
      Serial.println(Start_Charging);
    }
    // Add more else-if conditions for other characteristics
  }
};

void setup() {
  //Read
  Product_Id = 010101;
  BMS_State = 2;
  Battery_Voltage = 22400;
  Battery_Temperature = 2934;
  Battery_Health_Status = 2094;
  Pack_Total_Cap = 22000;
  Battery_CycleCount = 50;
  BMS_Fault = 5;
  Battery_Current = 1150;
  Pack_Remaining_Cap = 1982;
  Battery_FullCharge = 2789;
  Charging_Prof_cc = 2534;
  Charging_Prof_cv = 2531;
  Battery_Discharge = 2500;

  Drone_Status = 1;
  Charging_Status = 0;

  // Cell Voltages
  Cell1_Voltage = 3100;   //
  Cell2_Voltage = 3095;   //
  Cell3_Voltage = 2459;   //
  Cell4_Voltage = 2987;   //
  Cell5_Voltage = 3500;   //
  Cell6_Voltage = 3095;   //
  Cell7_Voltage = 3095;   //
  Cell8_Voltage = 3095;   //
  Cell9_Voltage = 3095;   //
  Cell10_Voltage = 3095;  //
  Cell11_Voltage = 3095;  //
  Cell12_Voltage = 3095;  //
  Cell13_Voltage = 3095;  //
  Cell14_Voltage = 3095;  //
  Cell15_Voltage = 3095;  //
  Cell16_Voltage = 3095;  //

  // Write
  Battery_Cell_Nos = 0;
  Battery_Cap = 0;
  Battery_Constant_Current = 0;
  Battery_Peak_Current = 0;
  Battery_Max_Voltage = 0;
  Battery_Min_Voltage = 0;
  Battery_Operating_Temperature = 0;
  Battery_ID = 0;
  BMS_ID = 0;

  DSG_OverCurrent = 0;
  CHG_OverVoltage = 0;
  DSG_OverTemperature = 0;
  CHG_OverTemperature = 0;
  DSG_UnderVoltage = 0;
  Battery_DSG_C = 0;
  Battery_CHG_C = 0;
  SOC = 0;

  Algox_Cell_Nos = 0;
  Charging_type = 0;
  Cell_Chemistry = 0;
  Algox_Current = 0;
  Start_Charging = 0;

  Serial.begin(115200);

  // Create the BLE Device
  BLEDevice::init("AlgoCOM");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  //create service
  BLEService* pService = pServer->createService(BLEUUID(SERVICE_UUID), 300);
  // Create and add characteristics to the service

  pCharacteristic_Product_Id = pService->createCharacteristic(
      Product_Id_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Product_Id->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Product_Id);

  pCharacteristic_BMS_State = pService->createCharacteristic(
      BMS_State_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_BMS_State->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_BMS_State);

  pCharacteristic_Battery_Voltage = pService->createCharacteristic(
      Battery_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Battery_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Voltage);

  pCharacteristic_Battery_Temperature = pService->createCharacteristic(
      Battery_Temperature_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Battery_Temperature->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Temperature);

  pCharacteristic_Battery_Health_Status = pService->createCharacteristic(
      Battery_Health_Status_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Battery_Health_Status->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Health_Status);

  pCharacteristic_Pack_Total_Cap = pService->createCharacteristic(
      Pack_Total_Cap_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Pack_Total_Cap->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Pack_Total_Cap);

  pCharacteristic_Battery_CycleCount = pService->createCharacteristic(
      Battery_CycleCount_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Battery_CycleCount->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_CycleCount);

  pCharacteristic_BMS_Fault = pService->createCharacteristic(
      BMS_Fault_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_BMS_Fault->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_BMS_Fault);

  pCharacteristic_Battery_Current = pService->createCharacteristic(
      Battery_Current_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Battery_Current->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Current);

  pCharacteristic_Pack_Remaining_Cap = pService->createCharacteristic(
      Pack_Remaining_Cap_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Pack_Remaining_Cap->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Pack_Remaining_Cap);

  pCharacteristic_Battery_FullCharge = pService->createCharacteristic(
      Battery_FullCharge_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Battery_FullCharge->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_FullCharge);

  pCharacteristic_Charging_Prof_cc = pService->createCharacteristic(
      Charging_Prof_CC_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Charging_Prof_cc->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Charging_Prof_cc);

  pCharacteristic_Charging_Prof_cv = pService->createCharacteristic(
      Charging_Prof_CV_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Charging_Prof_cv->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Charging_Prof_cv);

  pCharacteristic_Cell1_Voltage = pService->createCharacteristic(
      Cell1_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell1_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell1_Voltage); 

  pCharacteristic_Cell2_Voltage = pService->createCharacteristic(
      Cell2_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell2_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell2_Voltage);

  pCharacteristic_Cell3_Voltage = pService->createCharacteristic(
      Cell3_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell3_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell3_Voltage);

  pCharacteristic_Cell4_Voltage = pService->createCharacteristic(
      Cell4_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell4_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell4_Voltage);

    pCharacteristic_Cell5_Voltage = pService->createCharacteristic(
      Cell5_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell5_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell5_Voltage);

    pCharacteristic_Cell6_Voltage = pService->createCharacteristic(
      Cell6_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell6_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell6_Voltage);

    pCharacteristic_Cell7_Voltage = pService->createCharacteristic(
      Cell7_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell7_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell7_Voltage);

    pCharacteristic_Cell8_Voltage = pService->createCharacteristic(
      Cell8_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell8_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell8_Voltage);

    pCharacteristic_Cell9_Voltage = pService->createCharacteristic(
      Cell9_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell9_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell9_Voltage);

    pCharacteristic_Cell10_Voltage = pService->createCharacteristic(
      Cell10_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell10_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell10_Voltage);

    pCharacteristic_Cell11_Voltage = pService->createCharacteristic(
      Cell11_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell11_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell11_Voltage);

    pCharacteristic_Cell12_Voltage = pService->createCharacteristic(
      Cell12_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell12_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell12_Voltage);

    pCharacteristic_Cell13_Voltage = pService->createCharacteristic(
      Cell13_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell13_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell13_Voltage);

    pCharacteristic_Cell14_Voltage = pService->createCharacteristic(
      Cell14_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell14_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell14_Voltage);

    pCharacteristic_Cell15_Voltage = pService->createCharacteristic(
      Cell15_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell15_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell15_Voltage);

    pCharacteristic_Cell16_Voltage = pService->createCharacteristic(
      Cell16_Voltage_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Cell16_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell16_Voltage);

  pCharacteristic_Battery_Discharge = pService->createCharacteristic(
      Battery_Discharge_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Battery_Discharge->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Discharge);

  pCharacteristic_Drone_Status = pService->createCharacteristic(
      Drone_Status_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Drone_Status->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Drone_Status);

  pCharacteristic_Charging_Status = pService->createCharacteristic(
      Charging_Status_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_Charging_Status->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Charging_Status);

  pCharacteristic_Battery_Cell_Nos = pService->createCharacteristic(
    Bat_Cell_Nos_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_Cell_Nos->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_Cell_Nos->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Cell_Nos);

  pCharacteristic_Battery_Cap = pService->createCharacteristic(
    Battery_Cap_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_Cap->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_Cap->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Cap);

  pCharacteristic_Battery_Constant_Current = pService->createCharacteristic(
    Battery_Constant_Current_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_Constant_Current->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_Constant_Current->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Constant_Current);

  pCharacteristic_Battery_Peak_Current = pService->createCharacteristic(
    Battery_Peak_Current_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_Peak_Current->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_Peak_Current->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Peak_Current);

  pCharacteristic_Battery_Max_Voltage = pService->createCharacteristic(
    Bat_Max_Vol_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_Max_Voltage->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_Max_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Max_Voltage);

  pCharacteristic_Battery_Min_Voltage = pService->createCharacteristic(
    Bat_Min_Vol_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_Min_Voltage->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_Min_Voltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Min_Voltage);

  pCharacteristic_Battery_Operating_Temperature = pService->createCharacteristic(
    Bat_Operating_Temp_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_Operating_Temperature->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_Operating_Temperature->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Operating_Temperature);

  pCharacteristic_BMS_Id = pService->createCharacteristic(
    BMS_ID_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_BMS_Id->setCallbacks(new myCharCallbacks());
  pCharacteristic_BMS_Id->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_BMS_Id);

  pCharacteristic_Battery_Id = pService->createCharacteristic(
    Bat_ID_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_Id->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_Id->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_Id);

  pCharacteristic_Battery_DSG_C = pService->createCharacteristic(
    Bat_DSG_C_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_DSG_C->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_DSG_C->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_DSG_C);

  pCharacteristic_Battery_CHG_C = pService->createCharacteristic(
    Bat_CHG_C_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Battery_CHG_C->setCallbacks(new myCharCallbacks());
  pCharacteristic_Battery_CHG_C->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Battery_CHG_C);

  pCharacteristic_DSG_OverCurrent = pService->createCharacteristic(
    DSG_OverCurrent_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_DSG_OverCurrent->setCallbacks(new myCharCallbacks());
  pCharacteristic_DSG_OverCurrent->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_DSG_OverCurrent);

  pCharacteristic_CHG_OverVoltage = pService->createCharacteristic(
    CHG_OverVoltage_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_CHG_OverVoltage->setCallbacks(new myCharCallbacks());
  pCharacteristic_CHG_OverVoltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_CHG_OverVoltage);

  pCharacteristic_DSG_OverTemperature = pService->createCharacteristic(
    DSG_OverTemperature_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_DSG_OverTemperature->setCallbacks(new myCharCallbacks());
  pCharacteristic_DSG_OverTemperature->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_DSG_OverTemperature);

  pCharacteristic_CHG_OverTemperature = pService->createCharacteristic(
    CHG_OverTemperature_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_CHG_OverTemperature->setCallbacks(new myCharCallbacks());
  pCharacteristic_CHG_OverTemperature->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_CHG_OverTemperature);

  pCharacteristic_DSG_UnderVoltage = pService->createCharacteristic(
    DSG_UnderVoltage_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_DSG_UnderVoltage->setCallbacks(new myCharCallbacks());
  pCharacteristic_DSG_UnderVoltage->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_DSG_UnderVoltage);

  pCharacteristic_SOC = pService->createCharacteristic(
    SOC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_SOC->setCallbacks(new myCharCallbacks());
  pCharacteristic_SOC->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_SOC);

  pCharacteristic_Algox_Cell_Nos = pService->createCharacteristic(
    Algox_Cell_Nos_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Algox_Cell_Nos->setCallbacks(new myCharCallbacks());
  pCharacteristic_Algox_Cell_Nos->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Algox_Cell_Nos);

  pCharacteristic_Charging_type = pService->createCharacteristic(
    Charging_type_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Charging_type->setCallbacks(new myCharCallbacks());
  pCharacteristic_Charging_type->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Charging_type);

  pCharacteristic_Cell_Chemistry = pService->createCharacteristic(
    Cell_Chemistry_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Cell_Chemistry->setCallbacks(new myCharCallbacks());
  pCharacteristic_Cell_Chemistry->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Cell_Chemistry);

  pCharacteristic_Algox_Current = pService->createCharacteristic(
    Algox_Current_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Algox_Current->setCallbacks(new myCharCallbacks());
  pCharacteristic_Algox_Current->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Algox_Current);

  pCharacteristic_Start_Charging = pService->createCharacteristic(
    Start_Charging_UUID,
    BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_READ
  );
  pCharacteristic_Start_Charging->setCallbacks(new myCharCallbacks());
  pCharacteristic_Start_Charging->addDescriptor(new BLE2902());
  pService->addCharacteristic(pCharacteristic_Start_Charging);

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");
}

void loop() {

  // notify changed value
  if (deviceConnected) {
    pCharacteristic_Product_Id->setValue(Product_Id);
    pCharacteristic_BMS_State->setValue(BMS_State);
    pCharacteristic_Battery_Voltage->setValue(Battery_Voltage);
    pCharacteristic_Battery_Temperature->setValue(Battery_Temperature);
    pCharacteristic_Battery_Health_Status->setValue(Battery_Health_Status);
    pCharacteristic_Pack_Total_Cap->setValue(Pack_Total_Cap);
    pCharacteristic_Battery_CycleCount->setValue(Battery_CycleCount);
    pCharacteristic_BMS_Fault->setValue(BMS_Fault);
    pCharacteristic_Battery_Current->setValue(Battery_Current);
    pCharacteristic_Pack_Remaining_Cap->setValue(Pack_Remaining_Cap);
    pCharacteristic_Battery_FullCharge->setValue(Battery_FullCharge);
    pCharacteristic_Charging_Prof_cc->setValue(Charging_Prof_cc);
    pCharacteristic_Charging_Prof_cv->setValue(Charging_Prof_cv);

    pCharacteristic_Cell1_Voltage->setValue(Cell1_Voltage);
    pCharacteristic_Cell2_Voltage->setValue(Cell2_Voltage);
    pCharacteristic_Cell3_Voltage->setValue(Cell3_Voltage);
    pCharacteristic_Cell4_Voltage->setValue(Cell4_Voltage);
    pCharacteristic_Cell5_Voltage->setValue(Cell5_Voltage);
    pCharacteristic_Cell6_Voltage->setValue(Cell6_Voltage);
    pCharacteristic_Cell7_Voltage->setValue(Cell7_Voltage);
    pCharacteristic_Cell8_Voltage->setValue(Cell8_Voltage);
    pCharacteristic_Cell9_Voltage->setValue(Cell9_Voltage);
    pCharacteristic_Cell10_Voltage->setValue(Cell10_Voltage);
    pCharacteristic_Cell11_Voltage->setValue(Cell11_Voltage);
    pCharacteristic_Cell12_Voltage->setValue(Cell12_Voltage);
    pCharacteristic_Cell13_Voltage->setValue(Cell13_Voltage);
    pCharacteristic_Cell14_Voltage->setValue(Cell14_Voltage);
    pCharacteristic_Cell15_Voltage->setValue(Cell15_Voltage);
    pCharacteristic_Cell16_Voltage->setValue(Cell16_Voltage);

    pCharacteristic_Battery_Discharge->setValue(Battery_Discharge);
    int Drone_Status = 1;
    pCharacteristic_Drone_Status->setValue(Drone_Status);
    int Charging_Status = 1;
    pCharacteristic_Charging_Status->setValue(Charging_Status);

    pCharacteristic_Battery_Cell_Nos->setValue(Battery_Cell_Nos);
    pCharacteristic_Battery_Cap->setValue(Battery_Cap);
    pCharacteristic_Battery_Constant_Current->setValue(Battery_Constant_Current);
    pCharacteristic_Battery_Peak_Current->setValue(Battery_Peak_Current);
    pCharacteristic_Battery_Max_Voltage->setValue(Battery_Max_Voltage);
    pCharacteristic_Battery_Min_Voltage->setValue(Battery_Min_Voltage);
    pCharacteristic_Battery_Operating_Temperature->setValue(Battery_Operating_Temperature);
    pCharacteristic_BMS_Id->setValue(BMS_ID);
    pCharacteristic_Battery_Id->setValue(Battery_ID);
    pCharacteristic_Battery_DSG_C->setValue(Battery_DSG_C);
    pCharacteristic_Battery_CHG_C->setValue(Battery_CHG_C);
    pCharacteristic_DSG_OverCurrent->setValue(DSG_OverCurrent);
    pCharacteristic_CHG_OverVoltage->setValue(CHG_OverVoltage);
    pCharacteristic_DSG_OverTemperature->setValue(DSG_OverTemperature);
    pCharacteristic_CHG_OverTemperature->setValue(CHG_OverTemperature);
    pCharacteristic_DSG_UnderVoltage->setValue(DSG_UnderVoltage);
    pCharacteristic_SOC->setValue(SOC);
    pCharacteristic_Algox_Cell_Nos->setValue(Algox_Cell_Nos);
    pCharacteristic_Charging_type->setValue(Charging_type);
    pCharacteristic_Cell_Chemistry->setValue(Cell_Chemistry);
    pCharacteristic_Algox_Current->setValue(Algox_Current);
    pCharacteristic_Start_Charging->setValue(Start_Charging);

    //updating parameters
    // value++;
    // if (value == 10) {
    //   pCharacteristic_BMS_State->notify();
    //   bms_state++;
    //   if (bms_state > 3) {
    //     bms_state = 1;
    //   }
    //   value = 0;
    // }
    pCharacteristic_Product_Id->notify();
    delay(10);
    pCharacteristic_BMS_State->notify();
    delay(10);
    pCharacteristic_Battery_Voltage->notify();
    delay(10);
    pCharacteristic_Battery_Temperature->notify();
    delay(10);
    pCharacteristic_Battery_Health_Status->notify();
    delay(10);
    pCharacteristic_Pack_Total_Cap->notify();
    delay(10);
    pCharacteristic_Battery_CycleCount->notify();
    delay(10);
    pCharacteristic_BMS_Fault->notify();
    delay(10);
    pCharacteristic_Battery_Current->notify();
    delay(10);
    pCharacteristic_Pack_Remaining_Cap->notify();
    delay(10);
    pCharacteristic_Battery_FullCharge->notify();
    delay(10);
    pCharacteristic_Charging_Prof_cc->notify();
    delay(10);
    pCharacteristic_Charging_Prof_cv->notify();
    delay(10);
    pCharacteristic_Cell1_Voltage->notify();
    delay(10);
    pCharacteristic_Cell2_Voltage->notify();
    delay(10);
    pCharacteristic_Cell3_Voltage->notify();
    delay(10);
    pCharacteristic_Cell4_Voltage->notify();
    delay(10);
    pCharacteristic_Cell5_Voltage->notify();
    delay(10);
    pCharacteristic_Cell6_Voltage->notify();
    delay(10);
    pCharacteristic_Cell7_Voltage->notify();
    delay(10);
    pCharacteristic_Cell8_Voltage->notify();
    delay(10);
    pCharacteristic_Cell9_Voltage->notify();
    delay(10);
    pCharacteristic_Cell10_Voltage->notify();
    delay(10);
    pCharacteristic_Cell11_Voltage->notify();
    delay(10);
    pCharacteristic_Cell12_Voltage->notify();
    delay(10);
    pCharacteristic_Cell13_Voltage->notify();
    delay(10);
    pCharacteristic_Cell14_Voltage->notify();
    delay(10);
    pCharacteristic_Cell15_Voltage->notify();
    delay(10);
    pCharacteristic_Cell16_Voltage->notify();
    delay(10);
    pCharacteristic_Battery_Discharge->notify();
    delay(10);
    pCharacteristic_Drone_Status->notify();
    delay(10);
    pCharacteristic_Charging_Status->notify();
    delay(10);
    pCharacteristic_Battery_Cell_Nos->notify();
    delay(10);
    pCharacteristic_Battery_Cap->notify();
    delay(10);
    pCharacteristic_Battery_Constant_Current->notify();
    delay(10);
    pCharacteristic_Battery_Peak_Current->notify();
    delay(10);
    pCharacteristic_Battery_Max_Voltage->notify();
    delay(10);
    pCharacteristic_Battery_Min_Voltage->notify();
    delay(10);
    pCharacteristic_Battery_Operating_Temperature->notify();
    delay(10);
    pCharacteristic_BMS_Id->notify();
    delay(10);
    pCharacteristic_Battery_Id->notify();
    delay(10);
    pCharacteristic_Battery_DSG_C->notify();
    delay(10);
    pCharacteristic_Battery_CHG_C->notify();
    delay(10);
    pCharacteristic_DSG_OverCurrent->notify();
    delay(10);
    pCharacteristic_CHG_OverVoltage->notify();
    delay(10);


    pCharacteristic_DSG_OverTemperature->notify();
    delay(10);
    pCharacteristic_CHG_OverTemperature->notify();
    delay(10);
    pCharacteristic_DSG_UnderVoltage->notify();
    delay(10);
    pCharacteristic_SOC->notify();
    delay(10);
    pCharacteristic_Algox_Cell_Nos->notify();
    delay(10);
    pCharacteristic_Charging_type->notify();
    delay(10);
    pCharacteristic_Cell_Chemistry->notify();
    delay(10);
    pCharacteristic_Algox_Current->notify();
    delay(10);
    pCharacteristic_Start_Charging->notify();
    delay(500);  // bluetooth stack will go into congestion, if too many packets are sent, in 6 hours test i was able to go as low as 3ms
  }
  // disconnecting
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);                   // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising();  // restart advertising
    Serial.println("start advertising");
    oldDeviceConnected = deviceConnected;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected) {
    // do stuff here on connecting
    oldDeviceConnected = deviceConnected;
  }
}
