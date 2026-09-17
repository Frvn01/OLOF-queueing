from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime

class StorageStats(BaseModel):
    total_gb: float
    used_gb: float
    free_gb: float
    free_percent: float

class HealthResponse(BaseModel):
    status: str = "ok"
    service: str = "OLOF Clinic Server Room Local Storage API"
    version: str = "1.0.0"
    server_time: datetime
    storage: StorageStats

class FileUploadResponse(BaseModel):
    success: bool = True
    file_url: str
    absolute_url: str
    filename: str
    category: str
    size_bytes: int
    content_type: str
    patient_id: Optional[str] = None
    created_at: datetime

class DrawingSaveRequest(BaseModel):
    patient_id: str
    organ: Optional[str] = None
    organ_type: Optional[str] = None
    image_base64: Optional[str] = None
    drawing_base64: Optional[str] = None
    doctor_id: Optional[str] = None
    doctor_name: Optional[str] = None
    findings: Optional[str] = None
    notes: Optional[str] = None
    symptoms: Optional[str] = None
    causes: Optional[str] = None
    annotations: Optional[List[Dict[str, Any]]] = None

class DrawingResponse(BaseModel):
    success: bool = True
    drawing_id: str
    filename: str
    file_url: str
    absolute_url: str
    patient_id: str
    organ: str
    created_at: datetime

class FileItem(BaseModel):
    id: str
    filename: str
    category: str
    patient_id: Optional[str] = None
    file_url: str
    size_bytes: int
    content_type: str
    created_at: str

class PatientFilesResponse(BaseModel):
    success: bool = True
    patient_id: str
    total_files: int
    files: List[FileItem]

class QueueBroadcastMessage(BaseModel):
    type: str = "CALL_PATIENT"  # CALL_PATIENT, SERVE_PATIENT, COMPLETE_PATIENT, QUEUE_UPDATE
    queue_number: str
    patient_name: str
    department: str
    room: str
    doctor_name: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.now)
