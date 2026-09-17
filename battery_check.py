import ctypes
import ctypes.wintypes

# Get battery info via WMI through Python
try:
    import wmi
    c = wmi.WMI()
    for battery in c.Win32_Battery():
        print(f"Charge: {battery.EstimatedChargeRemaining}%, Status: {battery.BatteryStatus}")
except ImportError:
    # Try via PowerShell through ctypes
    print("wmi module not available, trying powershell")
    try:
        import subprocess
        result = subprocess.run(
            ["powershell", "-Command", 
             "Get-WmiObject Win32_Battery | Select-Object EstimateChargeRemaining, BatteryStatus | Format-List"],
            capture_output=True, text=True, timeout=10
        )
        print(result.stdout)
        print(result.stderr)
    except Exception as e:
        print(f"PowerShell failed: {e}")
