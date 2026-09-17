# OLOF Clinic - Local Big Data Storage & Streaming Server

This server runs locally on the clinic's server room PC (e.g. `192.168.100.17:8080`) to store high-resolution patient webcam photos, clinical canvas drawings (Eye, Ear, Nose, Throat), lab results, and diagnostic files without consuming cloud Supabase storage limits or bandwidth.

---

## 🚀 Quick Start (Server Room PC)

### 1. First-Time Setup
Simply double-click `setup.bat`.  
This will:
- Check for Python 3.10+
- Create a virtual environment in `venv/`
- Install all dependencies (`FastAPI`, `Uvicorn`, `Pillow`, etc.)
- Initialize storage directories (`storage/photos`, `storage/drawings`, `storage/attachments`)
- Initialize SQLite database at `storage/olof_local.db`

### 2. Run the Server
Double-click `start_server.bat`.  
The server will start listening on `0.0.0.0:8080` and display the server's local IP address.

---

## 🛡️ Windows Firewall Setup (One-Time Command)

If client tablets or doctor kiosks cannot connect across the clinic LAN, allow port 8080 through the Windows Firewall.

Open **PowerShell as Administrator** on the server room PC and run:

```powershell
netsh advfirewall firewall add rule name="OLOF Clinic Storage Server (8080)" dir=in action=allow protocol=TCP localport=8080
```

---

## 📡 API Endpoints

Interactive Swagger UI documentation is available at:  
👉 **`http://localhost:8080/docs`** (or `http://192.168.100.17:8080/docs` from any clinic tablet)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Server status, storage disk usage & file count summary |
| `POST` | `/api/files/upload` | Multipart file upload (photos, lab scans, PDF reports) |
| `POST` | `/api/drawings/save` | Base64 canvas drawing decoder (Eye/Ear/Nose/Throat drawings) |
| `GET` | `/api/files/patient/{patient_id}` | Query all local files and drawings for a specific patient |
| `GET` | `/files/{category}/{filename}` | Fast static streaming file delivery |
| `DELETE`| `/api/files/{category}/{filename}`| Safely delete local file and database record |
| `WS` | `/ws/queue` | Real-time WebSocket broadcasting for queue displays |

---

## 🔄 Hybrid Architecture Overview

```
[ Receptionist / Nurse / Doctor Tablets ]
     |                                 |
     | (Lightweight records,           | (Heavy binary files:
     |  auth, patient metadata,        |  high-res photos,
     |  appointment status)            |  canvas drawings, lab scans)
     v                                 v
[ Cloud Supabase ]          [ Server Room PC: 192.168.100.17:8080 ]
  - PostgreSQL Database       - FastAPI Streaming Server
  - Supabase Auth             - Multi-Terabyte Local Hard Drive
  - Fast sync & internet access - Zero cloud bandwidth cost (<5ms LAN latency)
```

---

## 🗄️ Storage Directory Structure

```
server/
├── storage/
│   ├── olof_local.db       # SQLite local metadata & index
│   ├── photos/             # Patient webcam & profile photos
│   ├── drawings/           # Doctor/Nurse clinical canvas drawings (PNG)
│   ├── attachments/        # Lab reports, scan attachments (PDF/JPG)
│   └── backups/            # Local database backup snapshots
├── database.py             # SQLite helper functions
├── main.py                 # FastAPI backend & routes
├── models.py               # Pydantic data models
├── olof_schema.sql         # Local database schema definition
├── requirements.txt        # Python package dependencies
├── setup.bat               # 1-click Windows installer
└── start_server.bat        # 1-click Windows launcher
```
