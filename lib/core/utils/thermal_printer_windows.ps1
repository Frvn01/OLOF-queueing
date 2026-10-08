param(
    [string]$PrinterName = "POS-58",
    [string]$LogoPath = "",
    [string]$Dept = "ENT",
    [string]$DeptLabel = "[ENT CLINIC]",
    [string]$QueueNo = "#001",
    [string]$PatientName = "",
    [string]$DoctorName = "",
    [string]$RoomName = "",
    [string]$Purpose = "",
    [string]$IssuedAt = ""
)

$code = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class RawThermalPrinter {
    [DllImport("winspool.Drv", EntryPoint="OpenPrinterA", SetLastError=true, CharSet=CharSet.Ansi)]
    public static extern bool OpenPrinter(string szPrinter, out IntPtr hPrinter, IntPtr pd);

    [DllImport("winspool.Drv", EntryPoint="ClosePrinter", SetLastError=true)]
    public static extern bool ClosePrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint="StartDocPrinterA", SetLastError=true, CharSet=CharSet.Ansi)]
    public static extern bool StartDocPrinter(IntPtr hPrinter, int level, [In, MarshalAs(UnmanagedType.LPStruct)] DOCINFOA di);

    [DllImport("winspool.Drv", EntryPoint="EndDocPrinter", SetLastError=true)]
    public static extern bool EndDocPrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint="StartPagePrinter", SetLastError=true)]
    public static extern bool StartPagePrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint="EndPagePrinter", SetLastError=true)]
    public static extern bool EndPagePrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint="WritePrinter", SetLastError=true)]
    public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, int dwCount, out int dwWritten);

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
    public class DOCINFOA {
        [MarshalAs(UnmanagedType.LPStr)] public string pDocName = "Queue Ticket";
        [MarshalAs(UnmanagedType.LPStr)] public string pOutputFile = null;
        [MarshalAs(UnmanagedType.LPStr)] public string pDataType = "RAW";
    }

    public static bool Send(string printerName, byte[] bytes) {
        IntPtr hPrinter;
        if (!OpenPrinter(printerName, out hPrinter, IntPtr.Zero)) return false;
        DOCINFOA di = new DOCINFOA();
        if (StartDocPrinter(hPrinter, 1, di)) {
            if (StartPagePrinter(hPrinter)) {
                IntPtr p = Marshal.AllocCoTaskMem(bytes.Length);
                Marshal.Copy(bytes, 0, p, bytes.Length);
                int written;
                bool ok = WritePrinter(hPrinter, p, bytes.Length, out written);
                Marshal.FreeCoTaskMem(p);
                EndPagePrinter(hPrinter);
                EndDocPrinter(hPrinter);
                ClosePrinter(hPrinter);
                return ok;
            }
            EndDocPrinter(hPrinter);
        }
        ClosePrinter(hPrinter);
        return false;
    }

    public static byte[] ImageToEscPos(string imagePath, int targetWidth) {
        if (!System.IO.File.Exists(imagePath)) return new byte[0];
        try {
            targetWidth = ((targetWidth + 7) / 8) * 8;
            using (var orig = new Bitmap(imagePath)) {
                int targetHeight = (int)((float)orig.Height / orig.Width * targetWidth);
                using (var resized = new Bitmap(targetWidth, targetHeight)) {
                    using (var g = Graphics.FromImage(resized)) {
                        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g.Clear(Color.White);
                        g.DrawImage(orig, 0, 0, targetWidth, targetHeight);
                    }

                    int widthBytes = targetWidth / 8;
                    var list = new List<byte>();

                    // GS v 0 0 xL xH yL yH
                    list.Add(0x1D);
                    list.Add(0x76);
                    list.Add(0x30);
                    list.Add(0x00);
                    list.Add((byte)(widthBytes & 0xFF));
                    list.Add((byte)((widthBytes >> 8) & 0xFF));
                    list.Add((byte)(targetHeight & 0xFF));
                    list.Add((byte)((targetHeight >> 8) & 0xFF));

                    for (int y = 0; y < targetHeight; y++) {
                        for (int xByte = 0; xByte < widthBytes; xByte++) {
                            byte b = 0;
                            for (int bit = 0; bit < 8; bit++) {
                                int x = xByte * 8 + bit;
                                Color c = resized.GetPixel(x, y);
                                int lum = (int)(0.299 * c.R + 0.587 * c.G + 0.114 * c.B);
                                if (lum < 165 && c.A > 50) {
                                    b |= (byte)(0x80 >> bit);
                                }
                            }
                            list.Add(b);
                        }
                    }
                    return list.ToArray();
                }
            }
        } catch {
            return new byte[0];
        }
    }
}
"@

Add-Type -AssemblyName System.Drawing
if (-not ([System.Management.Automation.PSTypeName]'RawThermalPrinter').Type) {
    Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
}

$list = [System.Collections.Generic.List[byte]]::new()
$esc = [byte]0x1B
$gs = [byte]0x1D

function T($str) {
    $b = [System.Text.Encoding]::ASCII.GetBytes($str)
    $list.AddRange([byte[]]$b)
}

# 1. Initialize
$list.AddRange([byte[]]@($esc, 0x40))

# 2. Hardware Center Align
$list.AddRange([byte[]]@($esc, 0x61, 1))

# 3. Print Logo if available
if ($LogoPath -and (Test-Path $LogoPath)) {
    $logoBytes = [RawThermalPrinter]::ImageToEscPos($LogoPath, 160)
    if ($logoBytes.Length -gt 0) {
        $list.AddRange($logoBytes)
        T("`r`n")
    }
}

# 4. Clinic Header
$list.AddRange([byte[]]@($esc, 0x45, 1)) # Bold on
T("OUR LADY OF FATIMA`r`n")
T("E.E.N.T. CENTER`r`n")
$list.AddRange([byte[]]@($esc, 0x45, 0)) # Bold off
T("$DeptLabel`r`n")
T("================================`r`n")
T(">> QUEUE NUMBER <<`r`n")

# 5. Double Size Queue Number
$list.AddRange([byte[]]@($gs, 0x21, 0x11))
T("$QueueNo`r`n")
$list.AddRange([byte[]]@($gs, 0x21, 0x00))
T("================================`r`n")

# 6. Left Align for Patient Details
$list.AddRange([byte[]]@($esc, 0x61, 0))
if ($PatientName) { T(" Patient : $PatientName`r`n") }
if ($DoctorName)  { T(" Doctor  : $DoctorName`r`n") }
if ($RoomName)    { T(" Room    : $RoomName`r`n") }
if ($Purpose)     { T(" Purpose : $Purpose`r`n") }
if ($IssuedAt)    { T(" Issued  : $IssuedAt`r`n") }

# 7. Center Align for Footer
$list.AddRange([byte[]]@($esc, 0x61, 1))
T("--------------------------------`r`n")
T("Please wait for your number`r`n")
T("on the TV display.`r`n")
T("Senior & PWD Priority`r`n")
T("================================`r`n`r`n`r`n`r`n")

$ok = [RawThermalPrinter]::Send($PrinterName, $list.ToArray())
if ($ok) { exit 0 } else { exit 1 }
