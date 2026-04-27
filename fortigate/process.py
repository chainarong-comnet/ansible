import os
import sys
import json
import gspread
from google.oauth2.service_account import Credentials
from datetime import datetime

SERVICE_ACCOUNT_FILE = "ansible-api-450806-93e910fedf83.json"
SPREADSHEET_NAME = "Fortigate_Inventory"

def get_gsheet():
    scopes = [
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/drive"
    ]
    creds = Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=scopes
    )
    client = gspread.authorize(creds)
    return client.open(SPREADSHEET_NAME)

def upload_devices(sh,data):
    sheet = sh.worksheet("devices")

    headers = [
        "SnapshotDate", "createdAt", "Hostname", "Serial", "Vendor", "Model",
        "Version", "IP Address", "CPU", "Memory",
        "Uptime", "Session", "NTP",
        "Routes Total", "Routes Totalv4",

        "FortiGuard Connection", "FortiGuard Server",
        "FortiGuard Last Update", "FortiGuard Next Update",

        "FMG Connection", "FMG Server", "FMG Registration",
        "FAZ Connection", "FAZ IP", "FAZ Registration"
    ]


    if not sheet.get_all_values():
        sheet.append_row(headers)

    rows = []
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    for d in data:
        rows.append([
        d.get("SnapshotDate"),
        now,
        d.get("Hostname"),
        d.get("Serial"),
        d.get("Vendor"),
        d.get("Model"),
        d.get("Version"),
        d.get("IP Address"),
        d.get("CPU"),
        d.get("Memory"),
        d.get("Uptime"),
        d.get("Session"),
        d.get("NTP"),
        d.get("Routes Total"),
        d.get("Routes Totalv4"),

        d.get("FortiGuard Connection"),
        d.get("FortiGuard Server"),
        d.get("FortiGuard Last Update"),
        d.get("FortiGuard Next Update"),

        d.get("FMG Connection"),
        d.get("FMG Server"),
        d.get("FMG Registration"),

        d.get("FAZ Connection"),
        d.get("FAZ IP"),
        d.get("FAZ Registration"),
    ])


    sheet.append_rows(rows, value_input_option="RAW")

def upload_interfaces(sh,data):
    sheet = sh.worksheet("interfaces")

    headers = ["SnapshotDate", "createdAt", "Hostname", "Serial", "Interface", "IP", "Link"]
    if not sheet.get_all_values():
        sheet.append_row(headers)

    rows = []
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    for iface in data:
        rows.append([
            iface.get("SnapshotDate"),
            now,
            iface.get("Hostname"),
            iface.get("Serial"),
            iface.get("Interface"),
            iface.get("IP"),
            iface.get("Link"),
        ])

    if rows:
        sheet.append_rows(rows, value_input_option="RAW")

def upload_ospf(sh,data):
    sheet = sh.worksheet("ospf_neighbors")

    headers = ["SnapshotDate", "createdAt", "Hostname", "Serial",
           "Neighbor IP", "Router ID", "Priority"]
    if not sheet.get_all_values():
        sheet.append_row(headers)

    rows = []
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    for ospf in data:
        rows.append([
            ospf.get("SnapshotDate"),
            now,
            ospf.get("Hostname"),
            ospf.get("Serial"),
            ospf.get("Neighbor IP"),
            ospf.get("Router ID"),
            ospf.get("Priority"),
        ])

    if rows:
        sheet.append_rows(rows, value_input_option="RAW")

def upload_bgp(sh,data):
    sheet = sh.worksheet("bgp_neighbors")

    headers = ["SnapshotDate", "createdAt", "Hostname", "Serial",
           "Neighbor IP", "Local IP", "State"]
    if not sheet.get_all_values():
        sheet.append_row(headers)

    rows = []
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    for bgp in data:
        rows.append([
            bgp.get("SnapshotDate"),
            now,
            bgp.get("Hostname"),
            bgp.get("Serial"),
            bgp.get("Neighbor IP"),
            bgp.get("Local IP"),
            bgp.get("State"),
        ])

    if rows:
        sheet.append_rows(rows, value_input_option="RAW")

def extract_config_values(file_path):
    with open(file_path, "r") as file:
        content = json.load(file)

    status = content.get("results", {}).get("status", {})

    # -------------------------
    # DEVICE
    # -------------------------

    mgmt_ip = "-"

    interfacesmgmt = status.get("interfacesmgmt") or []
    mgmt_iface = interfacesmgmt[0] if interfacesmgmt else {}

    ipv4_list = mgmt_iface.get("ipv4_addresses") or []

    if isinstance(ipv4_list, list) and ipv4_list:
        mgmt_ip = ipv4_list[0]

    ntp_status = "-"

    ntp_list = status.get("ntp") or []
    ntp = ntp_list[0] if ntp_list else {}

    if isinstance(ntp, dict):
        ntp_status = ntp.get("ntpreachable", "-")

    SNAPSHOT_DATE = datetime.now().strftime("%Y-%m-%d")
    serial = status.get("serial", "-")

    fortiguard = content.get("results", {}).get("fortiguardstat", {}) or {}
    fmg = content.get("results", {}).get("fmgstat", {}) or {}
    faz = content.get("results", {}).get("fazstat", {}) or {}
    
    device = {
        "SnapshotDate": SNAPSHOT_DATE,
        "Hostname": status.get("hostname", "-"),
        "Serial": serial,
        "Vendor": status.get("Vendor", "Fortinet"),
        "Model": status.get("model", "-"),
        "Version": status.get("version", "-"),
        "IP Address": mgmt_ip,
        "CPU": status.get("cpu", "-"),
        "Memory": status.get("memory", "-"),
        "Uptime": status.get("uptime", "-"),
        "Session": status.get("session", "-"),
        "NTP": ntp_status,
        "Routes Total": content.get("results", {}).get("routes", {}).get("total", "-"),
        "Routes Totalv4": content.get("results", {}).get("routes", {}).get("totalv4", "-"),

        # ---------- FortiGuard ----------
        "FortiGuard Connection": fortiguard.get("fortiguardconnection", "-"),
        "FortiGuard Server": fortiguard.get("fortiguardserver", "-"),
        "FortiGuard Last Update": fortiguard.get("fortiguardlast", "-"),
        "FortiGuard Next Update": fortiguard.get("fortiguardnextupdate", "-"),

        # ---------- FortiManager ----------
        "FMG Connection": fmg.get("fmgconnection", "-"),
        "FMG Server": fmg.get("fmgserver", "-"),
        "FMG Registration": fmg.get("fmgregistration", "-"),

        # ---------- FortiAnalyzer ----------
        "FAZ Connection": faz.get("fazconnection", "up"),
        "FAZ IP": faz.get("fazip", "-"),
        "FAZ Registration": faz.get("fazregistration", "-"),
    }

    # -------------------------
    # INTERFACES
    # -------------------------
    interfaces = []

    for iface in content.get("results", {}).get("interfaces", []):
        # filter type
        if iface.get("type") not in ["physical", "tunnel", "aggregate", "vap-switch"]:
            continue

        # filter name
        if iface.get("name") in ["naf.root", "l2t.root", "ssl.root", "modem", "fortilink"]:
            continue

        # ✅ เอาเฉพาะ interface ที่ UP
        link_status = iface.get("link", "").upper()
        if link_status != "UP":
            continue

        # ---------- IPv4 ----------
        ip_with_cidr = "0.0.0.0/0"
        ipv4_list = iface.get("ipv4_addresses") or []

        if ipv4_list:
            ipv4 = ipv4_list[0]

            # case: dict {ip, cidr_netmask}
            if isinstance(ipv4, dict):
                ip = ipv4.get("ip")
                cidr = ipv4.get("cidr_netmask")
                if ip and cidr:
                    ip_with_cidr = f"{ip}/{cidr}"

            # case: string "x.x.x.x" หรือ "No IPv4 addresses available"
            elif isinstance(ipv4, str):
                if ipv4 != "No IPv4 addresses available":
                    ip_with_cidr = ipv4

        interfaces.append({
            "SnapshotDate": SNAPSHOT_DATE,
            "Hostname": device["Hostname"],
            "Serial": serial,
            "Interface": iface.get("name"),
            "IP": ip_with_cidr,
            "Link": link_status
        })


    # -------------------------
    # OSPF
    # -------------------------
    ospf = []
    for nei in content.get("ospf_neighbors", []):
        ospf.append({
            "SnapshotDate": SNAPSHOT_DATE,
            "Hostname": device["Hostname"],
            "Serial": serial,
            "Neighbor IP": nei.get("neighbor_ip"),
            "Router ID": nei.get("router_id"),
            "Priority": nei.get("priority"),
        })

    # -------------------------
    # BGP
    # -------------------------
    bgp = []
    for nei in content.get("bgp_neighbors", []):
        bgp.append({
            "SnapshotDate": SNAPSHOT_DATE,
            "Hostname": device["Hostname"],
            "Serial": serial,
            "Neighbor IP": nei.get("neighbor_ip"),
            "Local IP": nei.get("local_ip"),
            "State": nei.get("state"),
        })

    return {
        "device": device,
        "interfaces": interfaces,
        "ospf": ospf,
        "bgp": bgp
    }

def write_log(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{timestamp}] {message}\n")


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(BASE_DIR, "upload.log")
JSON_FOLDER = os.path.join(BASE_DIR, "report/json")


if len(sys.argv) < 2:
    print("Usage: python script.py <hostname>")
    sys.exit(1)

hostname = sys.argv[1]
file_path = os.path.join(JSON_FOLDER, f"{hostname}_PM.json")

if not os.path.exists(file_path):
    msg = f"Upload NOT completed for {hostname} | File not found"
    print(msg)
    write_log(msg)
    sys.exit(1)

try:
    sh = get_gsheet()
    result = extract_config_values(file_path)

    # แยกตาม sheet
    devices = [result["device"]]
    interfaces = result["interfaces"]
    ospf = result["ospf"]
    bgp = result["bgp"]

    # upload
    upload_devices(sh,devices)
    upload_interfaces(sh,interfaces)
    upload_ospf(sh,ospf)
    upload_bgp(sh,bgp)

    msg = f"Upload completed for {hostname}"
    print(msg)
    write_log(msg)

except Exception as e:
    msg = f"Upload NOT completed for {hostname} | Error: {e}"
    print(msg)
    write_log(msg)
