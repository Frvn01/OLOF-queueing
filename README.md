# 🏥 OLOF Queueing & Clinical Management System

**Our Lady of Fatima Eye Ear Nose Throat Center**  
📍 *Barangay 82 Baybay Road, Marasbaras, Tacloban City, Philippines*  
📞 *+63 968 721 6039* | ✉️ *olof.eentcenter@yahoo.com*  
> *"Because every SENSE deserves CLARITY"*

---

## 📌 Table of Contents
- [What was the Problem Seen?](#-what-was-the-problem-seen)
- [What was the Solution to the Problem? (Product Description)](#-what-was-the-solution-to-the-problem-product-description)
- [System Features](#-system-features)
- [How Did They Come Up With the Solution?](#-how-did-they-come-up-with-the-solution)
- [Technology Stack](#-technology-stack)
- [Database & Storage Architecture](#-database--storage-architecture)
- [Hardware & Platform Support](#-hardware--platform-support)
- [Getting Started](#-getting-started)

---

## 🔍 What was the Problem Seen?

Before the implementation of the OLOF Queueing System, **Our Lady of Fatima Eye Ear Nose Throat (EENT) Center** operated using traditional manual clinic procedures. Through operational assessment, several critical challenges and pain points were observed:

1. **Disorganized Patient Queues & Waiting Area Congestion**
   - Patients arrived without clear visibility into their queue position, wait times, or which room/doctor would attend to them.
   - Overcrowding and anxiety in the lobby due to uncertain waiting periods.
   - Staff had to verbally shout patient names across crowded rooms, leading to misheard calls, missed turns, and privacy concerns.

2. **Manual Paper-Based Intake & Chart Management**
   - Front desk staff relied on physical registration logbooks and paper patient records.
   - Retrieving records for returning patients was time-consuming, prone to clerical errors, and risked misplaced or degraded medical charts.
   - No standardized patient identification format across visits.

3. **Disconnected Inter-Departmental Communication**
   - Receptionists, triage nurses, and attending physicians worked in operational silos.
   - Handing off patients between front-desk registration, nurse pre-examination/triage, and doctor consultation rooms required manual physical movement of paper forms.
   - Doctors lacked immediate visibility into incoming patient volume and real-time waiting room load.

4. **Lack of Specialized EENT Clinical Charting Tools**
   - ENT and Ophthalmology diagnoses heavily rely on visual annotations (e.g., eye fundus, tympanic membrane, nasal cavity, throat diagrams).
   - Nurses and doctors had no digital canvas to illustrate and archive anatomical findings directly onto patient electronic records.

5. **Security, Auditability, and Access Control Gaps**
   - Staff shared terminals without individual identity verification, making accountability and role separation difficult.

---

## 💡 What was the Solution to the Problem? (Product Description)

The **OLOF Queueing & Clinical Management System** is a unified, real-time, cross-platform healthcare operations suite engineered specifically for the specialized needs of **Our Lady of Fatima Eye Ear Nose Throat Center**.

The product digitally transforms the entire patient journey into a streamlined, automated, paperless continuum:
- **Intelligent Queue Orchestration:** Automatically segregates and manages patient flow into dual clinical tracks: **ENT (Ear, Nose & Throat)** and **EYES (Ophthalmology)**, issuing standardized queue tickets (e.g., `ENT-001`, `EYE-001`).
- **Real-Time Waiting Area Display:** A dedicated TV/projector display board with crystal-clear visual status and automated audio announcements that calls patients by queue number to their assigned room and doctor.
- **Integrated Pre-Consultation Triage:** A dedicated digital Nurse Station for capturing vital signs, visual acuity (OD/OS), and interactive anatomical diagram sketching.
- **Doctor Consultation Suite:** An electronic health record (EHR) and consultation module allowing doctors to review pre-exam findings, inspect diagram annotations, document clinical notes, issue diagnoses, and track visit histories.
- **Cross-Platform & Offline-Resilient:** Operates seamlessly across Windows desktops, Android/iOS tablets, and Web browsers, backed by cloud synchronization with local storage fallback to ensure zero downtime.

---

## ⭐ System Features

### 1. 📺 Real-Time TV Queue Display (Web / Desktop)
- **Live Waiting & Serving Board:** Split-screen layout displaying active consultations and upcoming patients per department (ENT and EYES).
- **Automated Audio Chimes & Calling:** Plays alert tones and announces called queue numbers alongside room and doctor assignments.
- **Doctor & Room Attribution:** Displays assigned physician and consultation room clearly on screen.
- **Privacy-Compliant:** Displays designated queue numbers and doctor details, protecting patient identity in public waiting areas.

### 2. 🗂️ Front Desk & Receptionist Kiosk (Mobile / Tablet / Desktop)
- **Fast Patient Registration:** Comprehensive intake form covering demographics, contact info, civil status, referral source, and camera/photo upload.
- **Returning Patient Quick Search:** Instant search by Patient Number (`OLOF-XXXXXX`), name, or contact details to retrieve existing medical profiles.
- **QR Code Check-In:** Rapid scan-to-check-in using patient QR cards.
- **Queue Ticket Issuance:** Direct assignment to department, room, consulting physician, and visit purpose (Consultation, Follow-up, Pre-op, Post-op, Lab Results, etc.).
- **Patient Profile Management:** Complete view of previous visits, previous queue entries, and historical diagnoses.

### 3. 👩‍⚕️ Nurse Clinical Station & Triage (Mobile / Tablet / Desktop)
- **Queue Triage Queue:** Nurse-accessible list of queued patients ready for pre-consultation assessment.
- **Vital Signs Logging:** Dedicated recording for Blood Pressure (BP), Pulse Rate, Body Temperature, Respiratory Rate, Height, Weight, and automatic Body Mass Index (BMI) computation.
- **Visual Acuity Testing (Ophthalmology):** OD (Right Eye) and OS (Left Eye) distance and near vision tracking.
- **Interactive Anatomical Canvas (Clinical Drawings):**
  - High-resolution anatomical diagrams: **Eyes, Ears, Nose, Throat, Head & Neck, and General Anatomy**.
  - Multi-touch digital drawing canvas with customizable stroke width, colors, and eraser.
  - Multiple perspective/diagram views per clinical exam.
  - High-fidelity cloud storage for drawing captures linked to patient records.
- **Clinical History Ingestion:** Logs chief complaints, history of present illness (HPI), and past medical history (PMH) directly for the consulting physician.

### 4. 👨‍⚕️ Doctor Consultation Suite (Tablet / Mobile / Desktop)
- **Doctor Dashboard:** Real-time summary of today's pending patients, completed consultations, and room queue status.
- **Direct Queue Calling:** Controls to call the next patient, place patients on hold, skip, or finalize visits.
- **Comprehensive Patient Dossier:** Immediate review of nurse-recorded vital signs, visual acuity, clinical diagram annotations, and past visit chronologies.
- **Consultation Charting:** Secure documentation of clinical diagnosis, physician notes, and treatment plans.
- **Schedule & Appointment Management:** Set consulting availability, clinic days, and manage future appointments.
- **Doctor Profile & Reports:** Activity logs, consultations per day/week, and diagnostic trend reporting.

### 5. 🛠️ Administrative & Management Shell (Desktop)
- **Clinic Dashboard:** Real-time analytics, queue distribution, and operational metrics.
- **Global Queue Controller:** Central override to reorder, hold, transfer, or complete tickets across all rooms.
- **Staff & User Management:** Creation and maintenance of doctor, nurse, secretary, and receptionist accounts.
- **Staff QR Card Generation & Printing:** One-click generation and printing of QR credential badges for password-less physical login.
- **Department & Room Configuration:** Manage active doctors, consulting rooms, and service types.
- **Reports & Queue Archive:** Historical reporting with date-range filters, exportable records, and department breakdown.

### 6. 🔐 Staff Authentication & Security
- **Physical QR Card Login:** Staff scan their personalized physical badge at any device camera to unlock their assigned role.
- **Role-Based Station Locking:** Automatically routes users to their authorized views (Receptionist, Nurse, Doctor, Admin).
- **Theme Customization:** Complete support for Dark Mode and Light Mode across all modules.

---

## 🔬 How Did They Come Up With the Solution?

The design and technical development of the OLOF Queueing System followed a systematic, user-centered engineering approach:

1. **Field Observation & Workflow Mapping:**
   - The development team shadowed front-desk staff, clinic nurses, and doctors during operational hours.
   - Identified the exact hand-off points: *Patient Arrival ➔ Reception Registration ➔ Nurse Pre-Exam/Triage ➔ Waiting Area ➔ Doctor Consultation ➔ Departure*.
   - Pinpointed the major friction point: lack of visual charting tools for EENT specialties and paper chart transit delays.

2. **Domain-Specific Adaptation (EENT Focus):**
   - Unlike generic hospital queue systems, EENT practices require specialized visual assessments. The team developed the **Clinical Drawing Engine** with pre-loaded anatomical templates (tympanic membranes, eye anatomy, nasal septa, pharynx) to eliminate manual paper sketching.

3. **Real-Time Event-Driven Architecture:**
   - Selected WebSocket-powered database streaming via **Supabase Realtime**. When a receptionist registers a patient, the queue display, nurse station, and doctor suite reflect the update instantly without page refreshes.

4. **Multi-Role Single-Codebase Strategy (Adaptive Kiosk Architecture):**
   - Built with **Flutter**, the system dynamically adapts based on hardware context:
     - *Large Displays / Web Browsers:* Renders full-screen TV Queue boards.
     - *Desktop PCs:* Renders multi-pane Admin and Nurse management consoles.
     - *Tablets & Handhelds:* Renders touch-optimized Kiosks for Receptionists, Nurses, and Doctors.

5. **Failsafe Offline & Low-Bandwidth Resilience:**
   - Integrated local storage caching (`SharedPreferences` and local repository fallbacks) so front-desk and clinical operations continue uninterrupted even during internet outages.

6. **Low-Friction Physical QR Authentication:**
   - Replaced tedious username/password typing on shared clinic tablets with instant QR badge scanning, cutting login time down to under two seconds per shift change.

---

## 💻 Technology Stack

| Layer | Component | Description |
|---|---|---|
| **Framework** | [Flutter 3.x](https://flutter.dev) | High-performance, cross-platform UI framework for Desktop, Web & Mobile |
| **Language** | [Dart](https://dart.dev) | Strongly-typed, object-oriented language |
| **Backend & Database** | [Supabase](https://supabase.com) | Managed PostgreSQL with Row Level Security (RLS) |
| **Realtime Engine** | Supabase Realtime | WebSocket-based instant queue & status synchronization |
| **Media Storage** | Supabase Storage | Secure cloud storage for patient photos & clinical diagrams |
| **State Management** | [Provider](https://pub.dev/packages/provider) | Decoupled reactive application state management |
| **Routing** | [GoRouter](https://pub.dev/packages/go_router) | Declarative routing with deep linking and role-based guards |
| **QR Code Engine** | `qr_flutter` & `mobile_scanner` | Fast barcode/QR generation and live camera decoding |
| **Audio Alert** | `audioplayers` | Real-time chime and audio announcements for queue calling |
| **Canvas & Graphics** | `flutter_colorpicker` + CustomPainter | Vector sketching tool for medical diagram annotations |
| **Local Persistence** | `shared_preferences` | Client-side cache and offline fallback state |

---

## 🗄️ Database & Storage Architecture

The database schema (`supabase_schema.sql`) implements a robust relational structure:

- `patients` — Demographics, contact information, medical background, photo URLs, assigned physician/room.
- `queue_entries` — Daily ticket queue with statuses (`waiting`, `serving`, `completed`, `skipped`, `on_hold`), date keys, and timestamps.
- `clinical_examinations` — Nurse triage data, vital signs, exam views, annotation vectors (JSONB), and diagram snapshots.
- `visit_records` — Historical log of all consultations, diagnoses, and medical notes.
- `clinic_doctors` — Active physicians, departmental affiliations (ENT/EYES), and assigned rooms.
- `clinic_rooms` — Room directory, department mappings, and availability flags.
- **Storage Buckets:**
  - `patient-photos` — Profile images captured during registration.
  - `clinical-diagrams` — Annotated medical diagrams exported from the Nurse Drawing Canvas.

---

## 📱 Hardware & Platform Support

| Station | Recommended Platform | Primary Roles |
|---|---|---|
| **Lobby Waiting Area** | Smart TV / Chrome Web Browser / PC | TV Queue Display Board |
| **Front Desk Reception** | Android Tablet / iPad / Windows PC | Patient Registration, Check-in & Search |
| **Nurse Station** | Tablet with Stylus / Touchscreen PC | Triage, Vital Signs & Diagram Annotations |
| **Doctor Consultation** | Tablet / Laptop / Desktop | Patient EHR, Exam Review & Consultation |
| **Clinic Administration** | Windows / macOS Desktop | Staff Management, System Settings & Reports |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.11+ recommended)
- Chrome Browser (for web display testing) or Windows Desktop build tools
- A configured [Supabase](https://supabase.com) project

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/Frvn01/OLOF-queueing.git
cd "OLOF queueing"
flutter pub get
```

### 2. Configure Backend
1. Open your Supabase SQL editor.
2. Execute the schema script located at `supabase_schema.sql`.
3. Verify that the `patient-photos` and `clinical-diagrams` storage buckets are created.
4. Update your Supabase URL and Anon Key in `lib/core/constants/app_constants.dart` or pass them via environment variables:
   ```bash
   --dart-define=SUPABASE_URL=https://your-project.supabase.co
   --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```

### 3. Run the Application
- **TV Display Mode (Web):**
  ```bash
  flutter run -d chrome
  ```
- **Admin / Nurse Desktop Mode (Windows):**
  ```bash
  flutter run -d windows
  ```
- **Tablet / Mobile Kiosk Mode:**
  ```bash
  flutter run -d <device-id>
  ```

---

## 👥 Clinic Leadership & Credits

- **Clinic:** Our Lady of Fatima Eye Ear Nose Throat Center
- **Specialists:**
  - **Dr. Lorenzo Vera Cruz** — ENT (Ear, Nose & Throat) Specialist
  - **Dr. Ian J. Daguman** — Ophthalmology (Eyes) Specialist
- **Developed For:** OLOF EENT Clinical Team & Patients

