// Service Id definition for different products 
// ignore: non_constant_identifier_names
Map<String, String> uuid_service = {
  "SERVICE_BMS": "66eae0f3-bea4-496e-ac81-d591677dd9aa" // Battery Management System
};

// Collection of UUIDs all required 
Map<String, String> uuids = {
  "Service_ID": "66eae0f3-bea4-496e-ac81-d591677dd9aa",

  "Product_Id": "a4beceb7-689d-4e1f-bee6-b59358dde0ea", // AlgoBMS AlgoPAD AlgoX
  "BMS_state": "606d63cb-6f2c-42d0-9a1d-c3c20749c487", // AlgoBMS
  "AlgoPAD_state": "e7735642-e777-4f90-84ef-6c8c5bf42e1f", // AlgoPAD

  "Battery_voltage": "6c1e0a36-f854-49f2-a78f-3db43f6424b1", // idle charge drive algoX chargingPAD
  "Battery_temperature": "ee24bdeb-7408-4cec-8186-27e01bf301d7", // idle charge drive
  "Battery_health_status": "96ff5f4c-4830-4ec1-95d8-8f92a4bba717", // idle charge drive chargingPAD
  "Package_total_capacity": "0494e147-8541-4917-be37-09540a7f3161", // idle charge drive
  "Battery_cycle_count": "0492a1ac-d680-4e46-a28d-0422753dd0b3", // idle 
  "BMS_fault": "28fcf388-dbe0-4453-a1aa-7f41116e0e58", // idle charge drive
  "Battery_current": "ffe56b2d-0607-428f-ba10-7a76268c4420", // charge drive algoX chargingPAD
  "Package_remaining_capacity": "2e2cb9b4-02d9-4ac3-a97e-52f3c6b0c51e", // charge drive chargingPAD
  "Battery_full_charge": "79bda1ab-8b37-421a-83b7-01c1980bdec1", // charge
  "Charging_Porfile_cv": "c628e8ca-6c4e-4cda-88b1-6ca0f9320855", // charge
  "Charging_Porfile_cc": "16423408-9605-4312-a369-45bcacd6a880", // charge
  "cell1_voltage": "59878c02-5bfc-42c1-9c91-861b3f262ee0", // charge algoX chargingPAD
  "cell2_voltage": "9bc4eb20-faef-48a3-a2d3-04a4977225d6", // charge algoX chargingPAD
  "cell3_voltage": "dd5d4670-160e-4304-8a09-bbadfc7c1dec", // charge algoX chargingPAD
  "cell4_voltage": "a3c48189-4ee2-40e1-86ee-7291fb61939d", // charge algoX chargingPAD
  "cell5_voltage": "a1d5d1fa-691b-4f82-8c6e-98945243d711", // charge algoX chargingPAD
  "cell6_voltage": "7d7f5064-9f05-4723-8c9a-49ca699a7535", // charge algoX chargingPAD
  "cell7_voltage": "df8de357-450d-4373-bf3b-d3fcbb61d4a7", // charge algoX chargingPAD
  "cell8_voltage": "6d3efe3d-e699-49ee-a01a-df60700305be", // charge algoX chargingPAD
  "cell9_voltage": "3b9c753a-53cb-4a55-aed6-2f6609250341", // charge algoX chargingPAD
  "cell10_voltage": "35496015-80bd-43b3-91ee-50aadb953ed8", // charge algoX chargingPAD
  "cell11_voltage": "a69b3c58-36ef-4b22-ad0b-dbb0af5dbacd", // charge algoX chargingPAD
  "cell12_voltage": "9452d6c5-3467-41f1-96fe-91df261efbcf", // charge algoX chargingPAD
  "cell13_voltage": "0bc76b72-e9a7-4be7-bf53-0d0c897d8a5c", // charge algoX chargingPAD
  "cell14_voltage": "a13f06e2-a6a8-4ecf-a130-441ab94f337d", // charge algoX chargingPAD
  "cell15_voltage": "1d6a23ef-523d-446c-93c0-53eebad0eca9", // charge algoX chargingPAD
  "cell16_voltage": "4c776ff8-7448-4ba0-b238-1010b4a62297", // charge algoX chargingPAD
  "Battery_discharge": "24688ee9-9c1d-45bf-ba47-2b36cb92ace5", // drive

  "Cell_mismatch": "1ce397a4-2706-423e-a02f-7898bb435bc7", // algoX
  "Battery_not_connected": "6e647982-b9a2-4d72-92b1-14e409ea7e84", // algoX
  "Cell_connector_not_connected": "4a4d4eb9-a683-4956-b980-58495d45a960s", // algoX

  "Drone_status": "1efa6f0c-2ab4-44ca-8153-71b32678c4c3", // idlePAD
  "Charging_status": "cc32c0bb-218b-4b7f-808c-63dc94dd5c08", // idlePAD

  "Battery_cell_nos": "6bd6c397-e8dc-4d41-991d-8f2e887b7061", // BMSWrite
  "Battery_capacity": "0731d816-a269-4397-a7e5-0d1bf16310be", // BMSWrite
  "Battery_constant_current": "fd049ff1-670c-40fe-98b8-00504699f8c1", // BMSWrite
  "Battery_peak_current": "08b3b2fe-8fce-4393-b554-a31429b35d45", // BMSWrite
  "Battery_max_voltage": "d9dbad81-4b0d-4e3b-b438-3a1170981179", // BMSWrite
  "Battery_min_voltage": "751eafc6-1a1d-4a5e-8df1-4e6ee1f479d1", // BMSWrite
  "Battery_operating_temperature": "73e469a2-b1c2-4119-8be7-f325f75b8374", // BMSWrite
  "Battery_id": "2277ad1c-a8fd-48c3-9c1c-bddafa72922f", // BMSWrite
  "BMS_id": "d7e138fa-a4c2-482d-a8ee-f62429d4bdf4", // BMSWrite
  // "Battery_CHG_C": "435ddd69-c9c1-498c-9889-a63d97dea0ed", // BMSWrite
  "DSG_OverCurrent": "ed360ed8-8b14-4c3a-b39e-076ea97e782a", // BMSWrite
  "CHG_OverCurrent": "4fa96911-6065-45a0-b0be-9d15827e06d5",
  "CHG_OverVoltage": "86435c8e-33b2-49f1-af7a-e54ef290a66e", // BMSWrite
  "DSG_OverTemperature": "38b4df1e-08c8-4b33-8d71-654660afede1", // BMSWrite
  "CHG_OverTemperature": "c00e4792-2ee8-4cd1-9bd6-803ac9fd113e", // BMSWrite
  "DSG_UnderVoltage": "f9e62d2c-82f6-4cb4-ae6c-4b5b19b4c918", // BMSWrite
  // "Battery_DSG_C": "6fc9cfaf-cbf9-4c28-866d-6ef4e4e5440a", // BMSWrite
  "SOC": "14df897e-b1cc-4b16-8df0-d032bc92a875", // BMSWrite

  "Charging_type": "26b83d0d-4d66-45f2-8afb-32f1fed254aa", // AlgoXWrite
  "Cell_Chemistry": "4b9eba9d-3523-4311-ba81-9e4e18d5f491", // AlgoXWrite
  "Algox_Cell_Nos": "d57ec39e-8789-4aa6-89de-5d2ea01fa5aa", // AlgoXWrite
  "Algox_Current": "ad187c83-f94f-49fe-a686-6ab132447069", // AlgoXWrite
  "Start_Charging": "9027cc8b-da21-4c8a-95c2-44fc448834f4", // AlgoXWrite
  "FW_update": "26b83d0d-4d66-45f2-8afb-32f1fed254aa", // firmware update
};

// ignore: non_constant_identifier_names
Map<String, String> uuid_algoBMS_idle_read = {
  "Battery_voltage ": "6c1e0a36-f854-49f2-a78f-3db43f6424b1", // 16 byte
  "Battery_temperature": "ee24bdeb-7408-4cec-8186-27e01bf301d7", // 16 byte
  "Battery_health_status":
      "96ff5f4c-4830-4ec1-95d8-8f92a4bba717", // 8 byte(SOC) + 8 byte(SOH)
  "Package_total_capacity": "0494e147-8541-4917-be37-09540a7f3161", // 16 byte
  "Battery_cycle_count": "0492a1ac-d680-4e46-a28d-0422753dd0b3", // 16 byte
  "BMS_fault": "28fcf388-dbe0-4453-a1aa-7f41116e0e58", // 8 byte
};

// ignore: non_constant_identifier_names
Map<String, String> uuid_algoBMS_charge_read = {
  "Battery_voltage ": "6c1e0a36-f854-49f2-a78f-3db43f6424b1", // 16 byte
  "Battery_current": "ffe56b2d-0607-428f-ba10-7a76268c4420", // 16 byte
  "Battery_temperature": "ee24bdeb-7408-4cec-8186-27e01bf301d7", // 16 byte
  "Battery_health_status": "96ff5f4c-4830-4ec1-95d8-8f92a4bba717", // 8 byte(SOH)
  "Package_total_capacity": "0494e147-8541-4917-be37-09540a7f3161", // 16 byte
  "Package_remaining_capacity":
      "2e2cb9b4-02d9-4ac3-a97e-52f3c6b0c51e", // 16 byte
  "Battery_full_charge": "79bda1ab-8b37-421a-83b7-01c1980bdec1", // 16 byte
  "Charging_Porfile_cv": "c628e8ca-6c4e-4cda-88b1-6ca0f9320855", // 16 byte
  "Charging_Porfile_cc": "16423408-9605-4312-a369-45bcacd6a880", // 16 byte
  "cell1_voltage": "59878c02-5bfc-42c1-9c91-861b3f262ee0", // 16 byte
  "cell2_voltage": "9bc4eb20-faef-48a3-a2d3-04a4977225d6", // 16 byte
  "cell3_voltage": "dd5d4670-160e-4304-8a09-bbadfc7c1dec", // 16 byte
  "cell4_voltage": "a3c48189-4ee2-40e1-86ee-7291fb61939d", // 16 byte
  "cell5_voltage": "a1d5d1fa-691b-4f82-8c6e-98945243d711", // 16 byte
  "cell6_voltage": "7d7f5064-9f05-4723-8c9a-49ca699a7535", // 16 byte
  "cell7_voltage": "df8de357-450d-4373-bf3b-d3fcbb61d4a7", // 16 byte
  "cell8_voltage": "6d3efe3d-e699-49ee-a01a-df60700305be", // 16 byte
  "cell9_voltage": "3b9c753a-53cb-4a55-aed6-2f6609250341", // 16 byte
  "cell10_voltage": "35496015-80bd-43b3-91ee-50aadb953ed8", // 16 byte
  "cell11_voltage": "a69b3c58-36ef-4b22-ad0b-dbb0af5dbacd", // 16 byte
  "cell12_voltage": "9452d6c5-3467-41f1-96fe-91df261efbcf", // 16 byte
  "cell13_voltage": "0bc76b72-e9a7-4be7-bf53-0d0c897d8a5c", // 16 byte
  "cell14_voltage": "a13f06e2-a6a8-4ecf-a130-441ab94f337d", // 16 byte
  "cell15_voltage": "1d6a23ef-523d-446c-93c0-53eebad0eca9", // 16 byte
  "cell16_voltage": "4c776ff8-7448-4ba0-b238-1010b4a62297", // 16 byte
  "BMS_fault": "28fcf388-dbe0-4453-a1aa-7f41116e0e58", // 8 byte
};

// ignore: non_constant_identifier_names
Map<String, String> uuid_algoBMS_discharge_read = {
  "Battery_voltage ": "6c1e0a36-f854-49f2-a78f-3db43f6424b1", // 16 byte
  "Battery_current": "ffe56b2d-0607-428f-ba10-7a76268c4420", // 16 byte
  "Battery_temperature": "ee24bdeb-7408-4cec-8186-27e01bf301d7", // 16 byte
  "Battery_health_status": "96ff5f4c-4830-4ec1-95d8-8f92a4bba717", // 8 byte(SOH)
  "Package_total_capacity": "0494e147-8541-4917-be37-09540a7f3161", // 16 byte
  "Package_remaining_capacity":
      "2e2cb9b4-02d9-4ac3-a97e-52f3c6b0c51e", // 16 byte
  "Battery_discharge": "24688ee9-9c1d-45bf-ba47-2b36cb92ace5", // 16 byte
  "BMS_fault": "28fcf388-dbe0-4453-a1aa-7f41116e0e58", // 8 byte
};

// ignore: non_constant_identifier_names
Map<String, String> uuid_algoBMS_write = {
  "Battery_cell_nos": "6bd6c397-e8dc-4d41-991d-8f2e887b7061", // compulsory
  "Battery_capacity": "0731d816-a269-4397-a7e5-0d1bf16310be", // default
  "Battery_constant_current": "fd049ff1-670c-40fe-98b8-00504699f8c1", // default
  "Battery_peak_current": "08b3b2fe-8fce-4393-b554-a31429b35d45", // default
  "Battery_max_voltage": "d9dbad81-4b0d-4e3b-b438-3a1170981179", // default
  "Battery_min_voltage": "751eafc6-1a1d-4a5e-8df1-4e6ee1f479d1", // default
  "Battery_operating_temperature":
      "73e469a2-b1c2-4119-8be7-f325f75b8374", // default
  "Battery_id": "2277ad1c-a8fd-48c3-9c1c-bddafa72922f", // compulsory
  "BMS_id": "d7e138fa-a4c2-482d-a8ee-f62429d4bdf4", // compulsory
  "Battery_CHG_C": "435ddd69-c9c1-498c-9889-a63d97dea0ed", // default
  "DSG_OverCurrent": "ed360ed8-8b14-4c3a-b39e-076ea97e782a", // default
  "CHG_OverCurrent": "4fa96911-6065-45a0-b0be-9d15827e06d5",
  "CHG_OverVoltage": "86435c8e-33b2-49f1-af7a-e54ef290a66e", // default
  "DSG_OverTemperature": "38b4df1e-08c8-4b33-8d71-654660afede1", // default
  "CHG_OverTemperature": "c00e4792-2ee8-4cd1-9bd6-803ac9fd113e", // default
  "DSG_UnderVoltage": "f9e62d2c-82f6-4cb4-ae6c-4b5b19b4c918", // default
  "Battery_DSG_C": "6fc9cfaf-cbf9-4c28-866d-6ef4e4e5440a", // default
  "SOC": "14df897e-b1cc-4b16-8df0-d032bc92a875", // default
};

// ignore: non_constant_identifier_names
Map<String, String> uuid_algoX_charge_read = {
  "Battery_voltage": "6c1e0a36-f854-49f2-a78f-3db43f6424b1", // 16 byte
  "Battery_current": "ffe56b2d-0607-428f-ba10-7a76268c4420", // 16 byte
  "cell1_voltage": "59878c02-5bfc-42c1-9c91-861b3f262ee0", // 16 byte
  "cell2_voltage": "9bc4eb20-faef-48a3-a2d3-04a4977225d6", // 16 byte
  "cell3_voltage": "dd5d4670-160e-4304-8a09-bbadfc7c1dec", // 16 byte
  "cell4_voltage": "a3c48189-4ee2-40e1-86ee-7291fb61939d", // 16 byte
  "cell5_voltage": "a1d5d1fa-691b-4f82-8c6e-98945243d711", // 16 byte
  "cell6_voltage": "7d7f5064-9f05-4723-8c9a-49ca699a7535", // 16 byte
  "cell7_voltage": "df8de357-450d-4373-bf3b-d3fcbb61d4a7", // 16 byte
  "cell8_voltage": "6d3efe3d-e699-49ee-a01a-df60700305be", // 16 byte
  "cell9_voltage": "3b9c753a-53cb-4a55-aed6-2f6609250341", // 16 byte
  "cell10_voltage": "35496015-80bd-43b3-91ee-50aadb953ed8", // 16 byte
  "cell11_voltage": "a69b3c58-36ef-4b22-ad0b-dbb0af5dbacd", // 16 byte
  "cell12_voltage": "9452d6c5-3467-41f1-96fe-91df261efbcf", // 16 byte
  "cell13_voltage": "0bc76b72-e9a7-4be7-bf53-0d0c897d8a5c", // 16 byte
  "cell14_voltage": "a13f06e2-a6a8-4ecf-a130-441ab94f337d", // 16 byte
  "cell15_voltage": "1d6a23ef-523d-446c-93c0-53eebad0eca9", // 16 byte
  "cell16_voltage": "4c776ff8-7448-4ba0-b238-1010b4a62297", // 16 byte
};

// ignore: non_constant_identifier_names
Map<String, String> uuid_algoX_write = {
  "Charging_type": "26b83d0d-4d66-45f2-8afb-32f1fed254aa", // compulsory
  "Cell_Chemistry": "4b9eba9d-3523-4311-ba81-9e4e18d5f491", // compulsory
  "Algox_Cell_Nos": "d57ec39e-8789-4aa6-89de-5d2ea01fa5aa", // compulsory
  "Algox_Current": "ad187c83-f94f-49fe-a686-6ab132447069", // compulsory
  // "Start_Charging": "9027cc8b-da21-4c8a-95c2-44fc448834f4", // compulsory
};

// ignore: non_constant_identifier_names
Map<String, String> uuid_algoPAD_idle_read = {
  "Drone_status": "1efa6f0c-2ab4-44ca-8153-71b32678c4c3", // 8 byte
  "Charging_status": "cc32c0bb-218b-4b7f-808c-63dc94dd5c08", // 8 byte
};

// ignore: non_constant_identifier_names
Map<String, String> uuid_algoPAD_charge_read = {
  "Battery_voltage": "6c1e0a36-f854-49f2-a78f-3db43f6424b1", // 16 byte
  "Battery_current": "ffe56b2d-0607-428f-ba10-7a76268c4420", // 16 byte
  "Battery_health_status": "96ff5f4c-4830-4ec1-95d8-8f92a4bba717", // 8 byte(SOC) + 8 byte(SOH)
  "Package_remaining_capacity":
      "2e2cb9b4-02d9-4ac3-a97e-52f3c6b0c51e", // 16 byte
  "cell1_voltage": "59878c02-5bfc-42c1-9c91-861b3f262ee0", // 16 byte
  "cell2_voltage": "9bc4eb20-faef-48a3-a2d3-04a4977225d6", // 16 byte
  "cell3_voltage": "dd5d4670-160e-4304-8a09-bbadfc7c1dec", // 16 byte
  "cell4_voltage": "a3c48189-4ee2-40e1-86ee-7291fb61939d", // 16 byte
  "cell5_voltage": "a1d5d1fa-691b-4f82-8c6e-98945243d711", // 16 byte
  "cell6_voltage": "7d7f5064-9f05-4723-8c9a-49ca699a7535", // 16 byte
  "cell7_voltage": "df8de357-450d-4373-bf3b-d3fcbb61d4a7", // 16 byte
  "cell8_voltage": "6d3efe3d-e699-49ee-a01a-df60700305be", // 16 byte
  "cell9_voltage": "3b9c753a-53cb-4a55-aed6-2f6609250341", // 16 byte
  "cell10_voltage": "35496015-80bd-43b3-91ee-50aadb953ed8", // 16 byte
  "cell11_voltage": "a69b3c58-36ef-4b22-ad0b-dbb0af5dbacd", // 16 byte
  "cell12_voltage": "9452d6c5-3467-41f1-96fe-91df261efbcf", // 16 byte
  "cell13_voltage": "0bc76b72-e9a7-4be7-bf53-0d0c897d8a5c", // 16 byte
  "cell14_voltage": "a13f06e2-a6a8-4ecf-a130-441ab94f337d", // 16 byte
  "cell15_voltage": "1d6a23ef-523d-446c-93c0-53eebad0eca9", // 16 byte
  "cell16_voltage": "4c776ff8-7448-4ba0-b238-1010b4a62297", // 16 byte
};
