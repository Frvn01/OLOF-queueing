import os
import shutil
import uuid
import base64
import json
from datetime import datetime
from typing import Optional, List

import aiofiles
from fastapi import FastAPI, File, UploadFile, Query, HTTPException, WebSocket, WebSocketDisconnect, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse

from models import (
    HealthResponse,
    StorageStats,
    FileUploadResponse,
    DrawingSaveRequest,
    DrawingResponse,
    PatientFilesResponse,
    QueueBroadcastMessage,
)
import database

# ── Base Directories ──────────────────────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STORAGE_DIR = os.path.join(BASE_DIR, "storage")
PHOTOS_DIR = os.path.join(STORAGE_DIR, "photos")
DRAWINGS_DIR = os.path.join(STORAGE_DIR, "drawings")
ATTACHMENTS_DIR = os.path.join(STORAGE_DIR, "attachments")
BACKUPS_DIR = os.path.join(STORAGE_DIR, "backups")

for d in [PHOTOS_DIR, DRAWINGS_DIR, ATTACHMENTS_DIR, BACKUPS_DIR]:
    os.makedirs(d, exist_ok=True)

# Initialize local SQLite database
database.init_db()

# ── FastAPI App Setup ─────────────────────────────────────────────────────────
app = FastAPI(
    title="OLOF Clinic Server Room Local Storage API",
    description="Local high-performance file storage and streaming service for Our Lady of Fatima Eye, Ear, Nose & Throat Center.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Enable CORS for all clinic devices on LAN
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files directory so /files/photos/xxx streams directly to clients
app.mount("/files", StaticFiles(directory=STORAGE_DIR), name="files")

# ── WebSocket Connection Manager (Local Queue Broadcaster) ────────────────────
class QueueConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                disconnected.append(connection)
        for dead in disconnected:
            self.disconnect(dead)

ws_manager = QueueConnectionManager()


# ── Helper Functions ──────────────────────────────────────────────────────────
def get_disk_storage_stats() -> StorageStats:
    total, used, free = shutil.disk_usage(STORAGE_DIR)
    total_gb = round(total / (1024 ** 3), 2)
    used_gb = round(used / (1024 ** 3), 2)
    free_gb = round(free / (1024 ** 3), 2)
    free_pct = round((free / total) * 100, 1)
    return StorageStats(
        total_gb=total_gb,
        used_gb=used_gb,
        free_gb=free_gb,
        free_percent=free_pct,
    )

def get_category_dir(category: str) -> str:
    cat = category.lower().strip()
    if cat == "photos":
        return PHOTOS_DIR
    elif cat == "drawings":
        return DRAWINGS_DIR
    elif cat == "attachments":
        return ATTACHMENTS_DIR
    elif cat == "backups":
        return BACKUPS_DIR
    else:
        raise HTTPException(status_code=400, detail=f"Invalid category: '{category}'. Allowed: photos, drawings, attachments, backups")


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/", response_class=HTMLResponse)
async def root_dashboard():
    stats = get_disk_storage_stats()
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>OLOF Server Room Storage API</title>
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f0fdf4; color: #064e3b; padding: 40px; }}
            .card {{ background: white; max-width: 650px; margin: 0 auto; padding: 30px; border-radius: 16px; box-shadow: 0 10px 25px rgba(5,150,105,0.1); border: 1px solid #bbf7d0; }}
            h1 {{ color: #059669; margin-top: 0; display: flex; align-items: center; gap: 10px; }}
            .pill {{ background: #d1fae5; color: #065f46; padding: 4px 12px; border-radius: 20px; font-weight: bold; font-size: 13px; }}
            .stat {{ margin: 15px 0; padding: 12px; background: #f8fafc; border-radius: 10px; }}
            a.btn {{ display: inline-block; background: #059669; color: white; padding: 10px 20px; border-radius: 8px; text-decoration: none; font-weight: bold; margin-top: 15px; }}
            a.btn:hover {{ background: #047857; }}
        </style>
    </head>
    <body>
        <div class="card">
            <h1>🏥 OLOF Clinic Local Storage API</h1>
            <p><span class="pill">● RUNNING ON LOCAL SERVER PC</span></p>
            <p>High-performance on-premise storage for heavy clinical drawings, patient photos, and attachments.</p>
            <div class="stat">
                <strong>Local Server Storage:</strong><br>
                Free Space: <b>{stats.free_gb} GB</b> of {stats.total_gb} GB ({stats.free_percent}% free)
            </div>
            <p>API Endpoint: <code>/api</code> | File Streaming: <code>/files/*</code></p>
            <a class="btn" href="/docs">View Interactive API Documentation (/docs)</a>
        </div>
    </body>
    </html>
    """

@app.get("/health", response_model=HealthResponse)
@app.get("/api/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint used by Flutter clients on startup to verify connectivity."""
    return HealthResponse(
        status="ok",
        service="OLOF Clinic Server Room Local Storage API",
        version="1.0.0",
        server_time=datetime.now(),
        storage=get_disk_storage_stats(),
    )


@app.post("/api/files/upload", response_model=FileUploadResponse)
async def upload_file(
    request: Request,
    file: UploadFile = File(...),
    category: str = Query("attachments", description="photos, drawings, attachments, backups"),
    patient_id: Optional[str] = Query(None, description="Optional patient ID association"),
):
    """
    Upload heavy files (photos, scan PDFs, drawings) directly to the server room PC.
    Saves to local disk and returns the relative & absolute URLs.
    """
    target_dir = get_category_dir(category)
    file_id = str(uuid.uuid4())
    
    # Preserve original extension
    ext = os.path.splitext(file.filename or "")[1].lower()
    if not ext:
        ext = ".jpg" if category == "photos" else ".png"
    
    clean_filename = f"{category}_{file_id[:8]}{ext}"
    dest_path = os.path.join(target_dir, clean_filename)
    
    # Stream write directly to disk asynchronously to handle large files
    size_bytes = 0
    async with aiofiles.open(dest_path, "wb") as out_file:
        while chunk := await file.read(1024 * 64):  # 64KB chunks
            size_bytes += len(chunk)
            await out_file.write(chunk)
            
    relative_url = f"/files/{category}/{clean_filename}"
    base_url = str(request.base_url).rstrip("/")
    absolute_url = f"{base_url}{relative_url}"
    
    # Record metadata in local SQLite
    database.record_file(
        file_id=file_id,
        filename=clean_filename,
        category=category,
        content_type=file.content_type or "application/octet-stream",
        size_bytes=size_bytes,
        relative_path=os.path.relpath(dest_path, BASE_DIR),
        file_url=relative_url,
        patient_id=patient_id,
        original_name=file.filename,
    )
    
    return FileUploadResponse(
        success=True,
        file_url=relative_url,
        absolute_url=absolute_url,
        filename=clean_filename,
        category=category,
        size_bytes=size_bytes,
        content_type=file.content_type or "application/octet-stream",
        patient_id=patient_id,
        created_at=datetime.now(),
    )


@app.post("/api/drawings/save", response_model=DrawingResponse)
async def save_clinical_drawing(request: Request, payload: DrawingSaveRequest):
    """
    Save nurse / doctor clinical canvas drawing (base64 PNG) to the local server room PC.
    """
    drawing_id = str(uuid.uuid4())
    organ_str = (payload.organ or payload.organ_type or "OTHER").strip().upper()
    filename = f"drawing_{organ_str.lower()}_{drawing_id[:8]}.png"
    dest_path = os.path.join(DRAWINGS_DIR, filename)
    
    # Strip base64 header if present (e.g. data:image/png;base64,...)
    b64_data = payload.image_base64 or payload.drawing_base64 or ""
    if not b64_data:
        raise HTTPException(status_code=400, detail="Missing base64 drawing data (image_base64 or drawing_base64)")

    if "," in b64_data:
        b64_data = b64_data.split(",", 1)[1]
        
    try:
        image_bytes = base64.b64decode(b64_data)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid base64 image data: {str(e)}")
        
    async with aiofiles.open(dest_path, "wb") as out_file:
        await out_file.write(image_bytes)
        
    relative_url = f"/files/drawings/{filename}"
    base_url = str(request.base_url).rstrip("/")
    absolute_url = f"{base_url}{relative_url}"
    
    # Record file in files table
    database.record_file(
        file_id=drawing_id,
        filename=filename,
        category="drawings",
        content_type="image/png",
        size_bytes=len(image_bytes),
        relative_path=os.path.relpath(dest_path, BASE_DIR),
        file_url=relative_url,
        patient_id=payload.patient_id,
        original_name=f"{organ_str}_clinical_drawing.png",
    )
    
    # Record in clinical drawings table
    database.record_drawing(
        drawing_id=drawing_id,
        patient_id=payload.patient_id,
        organ=organ_str,
        file_url=relative_url,
        doctor_id=payload.doctor_id,
        doctor_name=payload.doctor_name,
        findings=payload.findings or payload.notes,
        symptoms=payload.symptoms,
        causes=payload.causes,
        annotations_json=json.dumps(payload.annotations) if payload.annotations else None,
        file_id=drawing_id,
    )
    
    return DrawingResponse(
        success=True,
        drawing_id=drawing_id,
        filename=filename,
        file_url=relative_url,
        absolute_url=absolute_url,
        patient_id=payload.patient_id,
        organ=organ_str,
        created_at=datetime.now(),
    )


@app.get("/api/patients/{patient_id}/files", response_model=PatientFilesResponse)
@app.get("/api/files/patient/{patient_id}", response_model=PatientFilesResponse)
async def get_patient_files(patient_id: str):
    """Retrieve list of all files stored on local server for a specific patient."""
    records = database.get_files_by_patient(patient_id)
    return PatientFilesResponse(
        success=True,
        patient_id=patient_id,
        total_files=len(records),
        files=[
            {
                "id": r["id"],
                "filename": r["filename"],
                "category": r["category"],
                "patient_id": r["patient_id"],
                "file_url": r["file_url"],
                "size_bytes": r["size_bytes"],
                "content_type": r["content_type"],
                "created_at": str(r["created_at"]),
            }
            for r in records
        ],
    )


@app.delete("/api/files/{category}/{filename}")
async def delete_file(category: str, filename: str):
    """Delete a file from the server room PC and database."""
    target_dir = get_category_dir(category)
    file_path = os.path.join(target_dir, filename)
    
    if os.path.exists(file_path):
        os.remove(file_path)
        
    database.delete_file_record(category, filename)
    return {"success": True, "message": f"File {filename} deleted successfully"}


@app.get("/api/storage/stats")
async def storage_breakdown():
    """Detailed storage breakdown of categories and sizes."""
    disk = get_disk_storage_stats()
    cat_counts = database.get_storage_counts()
    return {
        "success": True,
        "disk": disk.model_dump(),
        "categories": cat_counts,
    }


# ── WebSocket Queue Endpoint ──────────────────────────────────────────────────
@app.websocket("/ws/queue")
async def websocket_queue_endpoint(websocket: WebSocket):
    """
    Local LAN WebSocket endpoint for ultra-low-latency queue broadcasting across tablets.
    """
    await ws_manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_json()
            # Broadcast the received queue message to all connected screens
            await ws_manager.broadcast(data)
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception:
        ws_manager.disconnect(websocket)
