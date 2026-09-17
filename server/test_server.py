"""
Quick automated test for OLOF Local Storage Server endpoints.
"""
from fastapi.testclient import TestClient
from main import app
import base64

client = TestClient(app)

def test_all():
    print("Testing /health...")
    r = client.get("/health")
    assert r.status_code == 200, f"Health check failed: {r.text}"
    health = r.json()
    print("Health response:", health)
    assert health["status"] in ("ok", "healthy")

    print("\nTesting /api/drawings/save...")
    # 1x1 transparent PNG base64
    sample_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    payload = {
        "patient_id": "TEST-PT-001",
        "organ_type": "ear",
        "drawing_base64": f"data:image/png;base64,{sample_b64}",
        "notes": "Automated verification drawing",
        "doctor_id": "DR-TEST-01"
    }
    r = client.post("/api/drawings/save", json=payload)
    assert r.status_code == 200, f"Drawing save failed: {r.text}"
    drawing_res = r.json()
    print("Drawing save response:", drawing_res)
    filename = drawing_res["filename"]
    assert filename.endswith(".png")

    print(f"\nTesting static streaming /files/drawings/{filename}...")
    r = client.get(f"/files/drawings/{filename}")
    assert r.status_code == 200, f"Static file fetch failed: {r.status_code}"
    assert len(r.content) > 0

    print("\nTesting /api/files/patient/TEST-PT-001...")
    r = client.get("/api/files/patient/TEST-PT-001")
    assert r.status_code == 200, f"Patient query failed: {r.text}"
    patient_files = r.json()
    total = patient_files.get("total_files", len(patient_files.get("files", [])))
    print(f"Found {total} files for TEST-PT-001")
    assert total >= 1

    print(f"\nTesting /api/files/drawings/{filename} DELETE...")
    r = client.delete(f"/api/files/drawings/{filename}")
    assert r.status_code == 200, f"Delete failed: {r.text}"
    print("Delete response:", r.json())

    print("\nALL SERVER ENDPOINTS VERIFIED SUCCESSFULLY!")

if __name__ == "__main__":
    test_all()
