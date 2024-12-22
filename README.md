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
- [Progress](#progress)
- [Future Scope](#future-scope)
- [Applications](#applications)
- [Project Setup](#project-setup)
- [Usage](#usage)
- [Team Members](#team-members)
- [Mentors](#mentors)
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

## 3. SIDE BAR
Side bar is the most appropriate place for user to access its profile and to customize the app as per his/her need. Additionally, it is also the place where, a user can contact the developers in case of any feedback or suggestion. So in this app too, we tried to implement these features and the following is a breif description of each one of them:

- **View Profile:**
In this feature, the user can access his/her profile as entered during the signup. It also enables the user to update his/her profile and make appropriate changes as and when required.

- **Share App**
It is the most common feature of all the major apps and thus we also added this feature. Here when the user clicks on it, the pop-message comes up which allows to share the link of the app through various means.

- **Contact Us:**
It is the feature which connects the user with the app developers and also an email id is provided there which can be used to send us any suggestions/feedback for the app. Additionally, a special note for the developers of "VJTI Maps" has been written without whom the location within the campus could not be implemented.

- **Log out:**
This button facilitates user to sign off his/her account from the app. So when that particular user wants to access the app, he/she needs to sign in again. Thus protecting the data of the users in case of any long break from the app usage. 

Now in the subsequent points, the major features among the above list are described further.

## 4. SENIOR'S ADVICE
It is the most interactive feature of this app wherein the user can interact with each other and can effectively make use of the experiances of each other in the college. Here we have assured that the students of every year can gain the benifits of this feature. Since the students across various years and branches are all together in this chatbox, a healthy environment fillied with diverity can help users to ask/solve the doubts and queries of each other and subsequently, strengthening the bond among each other. Also this chatbox can be used for the promotion of various events conducted by various clubs/committees in the college. And finally, to maintain the decorum of the chatbox, the admins would be given a special access to control all the messages. 

## 5. NOTES & PYQs
As said earlier, it is the flagship feature of this app which is inspired from the healthy spirit of contribution. In this section, the user can share notes & pyqs which are available with him to the open community of VJTI. It becomes extremely helpful at the exam times to have a quick recap of the  This will immensely popularize the app among the various kinds of user.

# 🔗Links

- [GitHub Repository](https://github.com/Arsh-Khan/Xplore-VJTI)
- [Demo Video](https://drive.google.com/file/d/1XI-_DQdWHRqXOfNii0CETlp2YX3t3gu4/view?usp=drivesdk)


<!-- Add any more links/resources you used for your project -->

## 🤖Tech-Stack
<img src="https://github.com/get-icon/geticon/raw/master/icons/flutter.svg" width = "45" height = "45" alt="badge"/> <img src="https://github.com/get-icon/geticon/raw/master/icons/dart.svg" width = "45" height = "45" alt="badge"/> <img src="https://github.com/get-icon/geticon/raw/master/icons/firebase.svg" width = "45" height = "45" alt="badge"/> <img src="https://github.com/get-icon/geticon/raw/master/icons/mongodb-icon.svg" width = "45" height = "45" alt="badge"/> <img src="https://github.com/get-icon/geticon/raw/master/icons/figma.svg" width = "45" height = "45" alt="badge"/> 

## 📈Progress

**Succesfully Implemented**

- [x] Dashboard for both VJTI students and Non VJTI Students as per target audience.
- [x] How to get VJTI Page
- [x] About VJTI Page
- [x] Extra Curriculars Page
- [x] Map of VJTI 
- [x] Notes and PYQ 
- [x] Seniors Advice

**Partially Implemented**

- [x] Location within campus 

## 🔮Future Scope

- Adding the option for the profile picture in user profile
- Adding notifications for the app
- Implementation of light/dark theme
- Implementation of a search function to search Notes and PYQs and also sorting them according to year and subject
- Implementation of adding PDFs, Images, Videos and GIFs along with messages in Seniors Advice
- Implementation of Location within Campus using DFS AND DIJKSTRA Algorithm for finding shortest path and also using IPS for routing and live traffic in campus

## 💸Applications

**Notes & PYQs**

Is there someone very sincere in your class who attends all lectures and takes all the notes that he/she has written during lectures? 

What if all these Notes and in addition to that, Previous Year’s Question Papers (PYQs) become available in a single platform? Yes! Less time for searching the notes, more time for studying for Exams!!

Don’t Worry, the Notes and PYQs section of our app will help you find all the notes and PYQs that your fellow mates/seniors have uploaded.

**Seniors Advice** 

“How to study for ESEs?”, “How to balance committee and academics?”, “Aapke notes milenge?”,
“Kaunsi faculty kaisi hai?”

Seniors will help sort all your queries in this common chatbox.

**Location within the campus**

Especially for FYs - In-Campus Locations of all the departments, classrooms, labs and so on...
Special Thanks to our seniors Mr Ravi Maurya & Ms Sarah Tisekar for developing and merging their app “VJTI Maps” in XploreVJTI.

**Extra-Curriculars** gives you a complete idea of all the clubs in VJTI by redirecting to their websites or social media accounts.

## 🛠Project Setup

<!-- >Include your project setup basics here. Steps for how someone else can setup your project on their machine. Add any relevant details as well. -->

Open the terminal on your device

Move to the location where you want to store the app data

Clone our GitHub repository - Xplore-VJTI

    git clone <https_or_ssh_link_of_XploreVJTI>

Open the folder ‘Xplore-VJTI’

    cd Xplore-VJTI

Go to the branch ‘develop’

    git checkout develop

Open the folder ‘xplorevjtiofficialapp’

    cd xplorevjtiofficialapp

Open it in VS Code

    code .

Select the device on which you want to run our app
Ctrl + Shift + p (for Windows)
Command + Shift + p (for Mac)

NOTE: For a physical device, connect it to your PC via USB cable after turning ON Developer Options & USB Debugging)

Then click on ‘Run’ -> ‘Run without debugging’

**Now enjoy a virtual tour of VJTI!**

## 💻Usage

VJTI mai admission hua hai. Still figuring ways to fit inn😜. 
Don't know ki canteen mai kya mita hai? Kuch previous years papers chaiye? And what abt the various clubs and committees in the college? 

Don't worry we got u covered 😎✨
Presenting Xplore VJTI
A one stop location to cater to all needs of a freshie Or a seasoned VJTIian. 

## 👨‍💻Team Members

<!-- Add names of your team members with their emails and links to their GitHub accounts -->

- [Rushi Jani](https://github.com/Rushi-Jani): rvjani22@gmail.com 
- [Arsh Khan](https://github.com/Arsh-Khan): khanarsh0124@gmail.com
- [Ruturaj Rao](https://github.com/Rutu2004): rsrao_b21@et.vjti.ac.in
- [Himanshu Singh](https://github.com/Himanshu-singh04): hsingh_b21@et.vjti.ac.in

## 👨‍🏫Mentors

<!-- Add names of your mentors with their emails and links to their GitHub accounts -->

- [Ananya Bangera](https://github.com/ananya-bangera): agbangera_b20@ce.vjti.ac.in 

## 📱Screenshots

**Sign Up and Login of VJTI Students**

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_231313.jpg" height=700 width=370>

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_231424.jpg" height=1000 width=370>

**Dashboard View and Side Bar**

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_231733.jpg" height=800 width=370>

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_231746.jpg" height=700 width=370>

**Profile View and Update Profile**

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_231755.jpg" height=800 width=370>

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_232029.jpg" height=800 width=370>

**Extra Curricular Page**

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_231939.jpg" height=700 width=370>

**Notes And PYQS**

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_231959.jpg" height=700 width=370>

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_232002.jpg" height=700 width=370>

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_232006.jpg" height=700 width=370>

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_232011.jpg" height=700 width=370>


**Seniors Advice**

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_232357.jpg" height=800 width=370>

<img src = "https://github.com/Arsh-Khan/Xplore-VJTI/blob/develop/assets/Screenshot_20230202_232411.jpg" height=700 width=370>
