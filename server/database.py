import os
import sqlite3
from typing import Optional, List, Dict, Any

DB_PATH = os.path.join(os.path.dirname(__file__), "storage", "olof_local.db")
SCHEMA_PATH = os.path.join(os.path.dirname(__file__), "olof_schema.sql")

def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = get_connection()
    try:
        with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
            conn.executescript(f.read())
        conn.commit()
    finally:
        conn.close()

def record_file(
    file_id: str,
    filename: str,
    category: str,
    content_type: str,
    size_bytes: int,
    relative_path: str,
    file_url: str,
    patient_id: Optional[str] = None,
    original_name: Optional[str] = None
) -> Dict[str, Any]:
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO local_files (
                id, filename, category, patient_id, original_name,
                content_type, size_bytes, relative_path, file_url
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                file_id, filename, category, patient_id, original_name,
                content_type, size_bytes, relative_path, file_url
            )
        )
        conn.commit()
        return {
            "id": file_id,
            "filename": filename,
            "category": category,
            "patient_id": patient_id,
            "file_url": file_url,
            "size_bytes": size_bytes,
            "content_type": content_type,
        }
    finally:
        conn.close()

def get_files_by_patient(patient_id: str) -> List[Dict[str, Any]]:
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT id, filename, category, patient_id, file_url,
                   size_bytes, content_type, created_at
            FROM local_files
            WHERE patient_id = ?
            ORDER BY created_at DESC
            """,
            (patient_id,)
        )
        return [dict(row) for row in cursor.fetchall()]
    finally:
        conn.close()

def delete_file_record(category: str, filename: str) -> bool:
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            "DELETE FROM local_files WHERE category = ? AND filename = ?",
            (category, filename)
        )
        conn.commit()
        return cursor.rowcount > 0
    finally:
        conn.close()

def record_drawing(
    drawing_id: str,
    patient_id: str,
    organ: str,
    file_url: str,
    doctor_id: Optional[str] = None,
    doctor_name: Optional[str] = None,
    findings: Optional[str] = None,
    symptoms: Optional[str] = None,
    causes: Optional[str] = None,
    annotations_json: Optional[str] = None,
    file_id: Optional[str] = None
) -> Dict[str, Any]:
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO clinical_drawings (
                id, patient_id, doctor_id, doctor_name, organ,
                file_id, file_url, findings, symptoms, causes, annotations_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                drawing_id, patient_id, doctor_id, doctor_name, organ,
                file_id, file_url, findings, symptoms, causes, annotations_json
            )
        )
        conn.commit()
        return {
            "id": drawing_id,
            "patient_id": patient_id,
            "organ": organ,
            "file_url": file_url,
        }
    finally:
        conn.close()

def get_storage_counts() -> Dict[str, Any]:
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT category, COUNT(*) as count, SUM(size_bytes) as total_size
            FROM local_files
            GROUP BY category
            """
        )
        categories = {}
        for row in cursor.fetchall():
            categories[row["category"]] = {
                "count": row["count"],
                "total_bytes": row["total_size"] or 0
            }
        return categories
    finally:
        conn.close()
