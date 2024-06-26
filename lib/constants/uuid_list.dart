Map<String, String> uuids = {
    "BMS_state": "606d63cb-6f2c-42d0-9a1d-c3c20749c487",
    "Battery_configuration": "53072650-6e04-40f5-89a0-5914d2324b3b",
    "Battery_voltage": "6c1e0a36-f854-49f2-a78f-3db43f6424b1",
    "Battery_current": "ffe56b2d-0607-428f-ba10-7a76268c4420",
    "Battery_temperature": "ee24bdeb-7408-4cec-8186-27e01bf301d7",
    "Battery_cycle_count": "0492a1ac-d680-4e46-a28d-0422753dd0b3",
    "Battery_health_status": "96ff5f4c-4830-4ec1-95d8-8f92a4bba717",
    "BMS_fault": "28fcf388-dbe0-4453-a1aa-7f41116e0e58",
    "Package_total_capacity": "0494e147-8541-4917-be37-09540a7f3161",
    "Package_remaining_capacity": "2e2cb9b4-02d9-4ac3-a97e-52f3c6b0c51e",
    "cell1_voltage": "59878c02-5bfc-42c1-9c91-861b3f262ee0",
    "cell2_voltage": "9bc4eb20-faef-48a3-a2d3-04a4977225d6",
    "cell3_voltage": "dd5d4670-160e-4304-8a09-bbadfc7c1dec",
    "cell4_voltage": "a3c48189-4ee2-40e1-86ee-7291fb61939d",
    "cell5_voltage": "a1d5d1fa-691b-4f82-8c6e-98945243d711",
    "cell6_voltage": "7d7f5064-9f05-4723-8c9a-49ca699a7535",
    "cell7_voltage": "df8de357-450d-4373-bf3b-d3fcbb61d4a7",
    "cell8_voltage": "6d3efe3d-e699-49ee-a01a-df60700305be",
    "cell9_voltage": "3b9c753a-53cb-4a55-aed6-2f6609250341",
    "cell10_voltage": "35496015-80bd-43b3-91ee-50aadb953ed8",
    "cell11_voltage": "a69b3c58-36ef-4b22-ad0b-dbb0af5dbacd",
    "cell12_voltage": "9452d6c5-3467-41f1-96fe-91df261efbcf",
    "cell13_voltage": "0bc76b72-e9a7-4be7-bf53-0d0c897d8a5c",
    "cell14_voltage": "a13f06e2-a6a8-4ecf-a130-441ab94f337d",
    "cell15_voltage": "1d6a23ef-523d-446c-93c0-53eebad0eca9",
    "cell16_voltage": "4c776ff8-7448-4ba0-b238-1010b4a62297",
    "Battery_discharge": "24688ee9-9c1d-45bf-ba47-2b36cb92ace5",
    "Battery_full_charge": "79bda1ab-8b37-421a-83b7-01c1980bdec1",
    "Charging_Porf_cc": "16423408-9605-4312-a369-45bcacd6a880",
    "Charging_Porf_cv": "c628e8ca-6c4e-4cda-88b1-6ca0f9320855"
  };

Map<String, String> uuid_algoBMS_idle_read = {
  "Stack_voltage " : "", // 16 byte
  "Temperature" : "", // 16 byte
  "State_of_charge" : "", // 8 byte
  "State_of_health" : "", // 8 byte
  "Total_capacity" : "", // 16 byte
  "Life_cycle_count" : "", // 16 byte
  "Fault_code" : "", // 8 byte
};

Map<String, String> uuid_algoBMS_charge_read = {
  "Stack_voltage " : "", // 16 byte
  "Current" : "", // 16 byte
  "Temperature" : "", // 16 byte
  "State_of_charge" : "", // 8 byte
  "Total_capacity" : "", // 16 byte
  "Rem_capacity" : "", // 16 byte
  "Time_fullcharge" : "", // 16 byte
  "CV_set" : "", // 16 byte
  "CC_set" : "", // 16 byte
  "vcell_1" : "", // 16 byte
  "vcell_2" : "", // 16 byte
  "vcell_3" : "", // 16 byte
  "vcell_4" : "", // 16 byte
  "vcell_5" : "", // 16 byte
  "vcell_6" : "", // 16 byte
  "vcell_7" : "", // 16 byte
  "vcell_8" : "", // 16 byte
  "vcell_9" : "", // 16 byte
  "vcell_10" : "", // 16 byte
  "vcell_11" : "", // 16 byte
  "vcell_12" : "", // 16 byte
  "vcell_13" : "", // 16 byte
  "vcell_14" : "", // 16 byte
  "vcell_15" : "", // 16 byte
  "vcell_16" : "", // 16 byte
  "Fault_code" : "", // 8 byte
};

Map<String, String> uuid_algoBMS_discharge_read = {
  "Stack_voltage " : "", // 16 byte
  "Current" : "", // 16 byte
  "Temperature" : "", // 16 byte
  "State_of_charge" : "", // 8 byte
  "Total_capacity" : "", // 16 byte
  "Rem_capacity" : "", // 16 byte
  "Time_discharge" : "", // 16 byte
  "Fault_code" : "", // 8 byte
};

Map<String, String> uuid_algoBMS_write = {
  "Battery_configuration " : "", // compulsory
  "Battery_capacity" : "", // compulsory
  "Constant_current_limit" : "", // default
  "Peak_current_limit" : "", // default
  "Max_voltage_per_cell_limit" : "", // default
  "Min_voltage_per_cell_limit" : "", // default
  "Operating_temperature_limit" : "", // default
  "Battery_id" : "", // compulsory
  "BMS_id" : "", // compulsory
  "Protection_enabled" : "", // default
  "Self_DGS" : "" // default
};

Map<String, String> uuid_algoX_charge_read = {
  "Stack_voltage " : "", // 16 byte
  "Current" : "", // 16 byte
  "vcell_1" : "", // 16 byte
  "vcell_2" : "", // 16 byte
  "vcell_3" : "", // 16 byte
  "vcell_4" : "", // 16 byte
  "vcell_5" : "", // 16 byte
  "vcell_6" : "", // 16 byte
  "vcell_7" : "", // 16 byte
  "vcell_8" : "", // 16 byte
  "vcell_9" : "", // 16 byte
  "vcell_10" : "", // 16 byte
  "vcell_11" : "", // 16 byte
  "vcell_12" : "", // 16 byte
  "vcell_13" : "", // 16 byte
  "vcell_14" : "", // 16 byte
  "vcell_15" : "", // 16 byte
  "vcell_16" : "", // 16 byte
};

Map<String, String> uuid_algoX_write = {
  "Charging_type " : "", 
  "Cell_chemistry" : "",
  "Number_of_cells" : "",
  "Current" : "",
  "Start_stop_charging" : "",
};

Map<String, String> uuid_algoPAD_idle_read = {
  "Drone_status" : "",
  "Charging_status " : "",
};

Map<String, String> uuid_algoPAD_charge_read = {
  "Stack_voltage " : "", // 16 byte
  "Current" : "", // 16 byte
  "State_of_charge" : "", // 8 byte
  "Rem_capacity" : "", // 16 byte
  "vcell_1" : "", // 16 byte
  "vcell_2" : "", // 16 byte
  "vcell_3" : "", // 16 byte
  "vcell_4" : "", // 16 byte
  "vcell_5" : "", // 16 byte
  "vcell_6" : "", // 16 byte
  "vcell_7" : "", // 16 byte
  "vcell_8" : "", // 16 byte
  "vcell_9" : "", // 16 byte
  "vcell_10" : "", // 16 byte
  "vcell_11" : "", // 16 byte
  "vcell_12" : "", // 16 byte
  "vcell_13" : "", // 16 byte
  "vcell_14" : "", // 16 byte
  "vcell_15" : "", // 16 byte
  "vcell_16" : "", // 16 byte
};