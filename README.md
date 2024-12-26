<h1 align="center">
  <a href="https://github.com/Himanshu-singh04/AlgoSafe">
    <img src="https://github.com/Himanshu-singh04/AlgoSafe/blob/main/assets/images/AlgoFET%20logo%20white%20text%20coloured.png" alt="AlgoFET" width="600" height="400">
  </a>
  <br>
  AlgoSAFE 
</h1>

<div align="center">
   <strong>AlgoSAFE</strong> -  A cross-platform Flutter-based mobile application to monitor and control AlgoFET devices via an ESP32 using Bluetooth Low Energy (BLE). The app supports real-time data monitoring across Android and iOS, featuring a robust communication framework with custom UUIDs and advanced message decoding. <br> <br>
<!--   Add any <a href="https://shields.io/">Shields</a> here -->
</div>
<hr>

<summary>Table of Contents</summary>

- [Description](#description)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Links](#links)
- [Contributors](#contributors)
- [Screenshots](#screenshots)


# 📝Description

**AlgoSAFE** The product's primary focus was to develop a sophisticated mobile application for AlgoFET, aimed at monitoring and controlling its product ecosystem through an advanced communication framework. The application's core objective: is to create a cross-platform solution that could interface seamlessly with an ESP32-based device, AlgoCOM, utilizing Bluetooth Low Energy (BLE) communication protocols. This user-friendly solution empowers users to interact seamlessly with multiple AlgoFET devices. 

Any queries or suggestion regarding this app can be sent us to :
**himanshu.singh.ws@gmail.com**

<!-- Add your **project description** here. Your project description should cover how your website/app works. That way you can convey what your project is without the need for anyone to view the code. A more *detailed README* in your project repository is encouraged, which can include build and use instructions etc. -->


# Features
## 1. Landing and Loading Screen

When you open the app, a loading screen appears, ensuring everything is set up correctly before you start. During this time, the app secures the necessary permissions to access Bluetooth, allowing it to connect with your devices and retrieve the data you need. Once the setup is complete, you'll be seamlessly directed into the app, ready to connect and manage your devices easily.

## 2. Home Screen

The scan screen is designed to help users easily connect to nearby AlgoFET devices via Bluetooth Low Energy (BLE). When Scan for Devices is pressed, it starts scanning for available AlgoFET devices in the vicinity.
   
Detected devices are displayed in a list format, with each device name (AlgoTEST) shown alongside a corresponding image of the device. Each device entry includes a Connect button that, when pressed, initiates the connection process to that specific device. Additionally, a Stop Scanning button at the bottom allows the user to halt the scanning process at any time, which is useful when they have found the device they wish to connect to or if no devices are available.

## 3. AlgoBMS Display
AlgoBMS, the indigenously designed Smart Battery Monitoring and Protection Board for UAVs, offering universal battery support, robust protection, and seamless CAN/SMBus communication in a compact, lightweight form factor.

**Monitoring Features:**
 - BMS State
 - Stack Voltage
 - Current
 - Temperature
 - Battery Health Status
 - Total Capacity
 - Remaining Capacity
 - Time Full Charge
 - Time Discharge
 - Life Cycle Count
 - CV Set
 - CC Set
 - Cell Count with Individual Display
 - Fault

**Configuration Features**
 - Battery Config. (no. of cells)
 - Battery Capacity
 - Maximum Operation Limits
 - Protections to be Enabled
 - Self Discharge Mode
 - Battery Id
 - BMS Id

## 4. AlgoX Display
AlgoX is the revolutionary drone charger that supports 6S to 14S batteries, high-current paralleling, cloud connectivity, and advanced safety features, making it the future of drone power.

**Monitoring Features:**
 - Stack Voltage
 - Current
 - Temperature
 - AlgoX Status
 - Cell Count with Individual Display

**Configuration Features**
 - Charging Type
 - Cell Chemistry
 - Number of Cells
 - Current
 - Start Charging

## 5. AlgoPAD Display
AlgoDOCK, the revolutionary Contact-Based Charging System for drones. By utilizing contact pads on both the drone and charging station, AlgoDOCK ensures a secure and cable-free connection, delivering seamless and efficient charging every time your drone lands.

**Monitoring Features:**
 - Drone Status
 - Charging Status
 - Stack Voltage
 - Current
 - Battery Health Status
 - Remaining Capacity
 - PAD On/Off Control

# 🔗Links

- [GitHub Repository](https://github.com/Himanshu-singh04/AlgoSafe)

<!-- Add any more links/resources you used for your project -->

## 🤖Tech-Stack
<img src="https://github.com/get-icon/geticon/raw/master/icons/flutter.svg" width = "45" height = "45" alt="badge"/> <img src="https://github.com/get-icon/geticon/raw/master/icons/dart.svg" width = "45" height = "45" alt="badge"/> <img src="https://github.com/get-icon/geticon/raw/master/icons/firebase.svg" width = "45" height = "45" alt="badge"/>

## 👨‍💻Contributors

<!-- Add names of your team members with their emails and links to their GitHub accounts -->
- [Himanshu Singh](https://github.com/Himanshu-singh04) : hsingh_b21@et.vjti.ac.in

## 📱Screenshots

<img src = "https://github.com/Himanshu-singh04/AlgoSafe/blob/main/assets/app_images/splash_screen.jpg" height=700 width=370>

<img src = "https://github.com/Himanshu-singh04/AlgoSafe/blob/main/assets/app_images/ble_permission.jpg" height=700 width=370>

<img src = "https://github.com/Himanshu-singh04/AlgoSafe/blob/main/assets/app_images/scan_screen.jpg" height=700 width=370>

<img src = "https://github.com/Himanshu-singh04/AlgoSafe/blob/main/assets/app_images/algobms_read(3).jpg" height=700 width=370>

<img src = "https://github.com/Himanshu-singh04/AlgoSafe/blob/main/assets/app_images/algobms_write%20(2).jpg" height=700 width=370>

<img src = "https://github.com/Himanshu-singh04/AlgoSafe/blob/main/assets/app_images/algox_read.jpg" height=700 width=370>

<img src = "https://github.com/Himanshu-singh04/AlgoSafe/blob/main/assets/app_images/algox_final.jpg" height=700 width=370>

<img src = "https://github.com/Himanshu-singh04/AlgoSafe/blob/main/assets/app_images/algo_pad1.jpg" height=700 width=370>
