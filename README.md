# คู่มือติดตั้ง Ansible Environment WSL2

> **Environment:** Windows 10/11 + WSL2 (Ubuntu 22.04)  
> **Repository:** https://github.com/chainarong-comnet/ansible

---

## ความต้องการเบื้องต้น

- Windows 10/11 ที่เปิดใช้งาน WSL2 แล้ว
- Ubuntu 22.04 บน WSL2
- Internet Connection

---

## ขั้นตอนที่ 1 — เปิด WSL2

เปิด **Windows Terminal** หรือ **PowerShell** แล้วพิมพ์:

```bash
wsl
```

หรือเปิดแอป **Ubuntu** จาก Start Menu โดยตรง

---

## ขั้นตอนที่ 2 — ดาวน์โหลด setup script

```bash
curl -o setup.sh https://raw.githubusercontent.com/chainarong-comnet/ansible/main/setup.sh
```

---

## ขั้นตอนที่ 3 — ให้สิทธิ์และรัน script

```bash
chmod +x setup.sh
bash setup.sh
```

script จะดำเนินการทุกอย่างอัตโนมัติ ใช้เวลาประมาณ **5–15 นาที** ขึ้นอยู่กับความเร็วอินเทอร์เน็ต

**ระหว่างรันจะเห็น output ประมาณนี้:**

```
>>> Cleaning up old/stale Docker binaries...
>>> Installing Docker CE via apt...
>>> Docker CE installed: Docker version 29.x.x
>>> c2 is already in the docker group.
>>> Docker daemon is accessible.
```

---

## ขั้นตอนที่ 4 — เปิด terminal ใหม่

ปิด WSL terminal แล้วเปิดใหม่ เพื่อให้ docker group มีผล

```bash
# หรือรัน command นี้แทนการเปิด terminal ใหม่
newgrp docker
```
---
## ขั้นตอนที่ 5 — สั่งรัน script setup.sh อีกครั้งเพื่อให้ clone repo และ build docker image

```bash
bash setup.sh
```
**ระหว่างรันจะเห็น output ประมาณนี้:**

```
>>> Cloning https://github.com/chainarong-comnet/ansible.git ...
>>> Building Docker image...
>>> Setting up Docker Compose services...

✅ Setup complete!
```
---

---

## ขั้นตอนที่ 6 — ทดสอบการติดตั้ง

```bash
cd ansible
docker run --rm ansible-env
```

**ผลลัพธ์ที่ควรได้:**

```
ansible-playbook [core 2.13.13]
  config file = None
  python version = 3.8.20
  ...
```
---

## ขั้นตอนที่ 7 — ให้สิทธิ์ Script run.sh และรัน script

```bash
chmod +x run.sh
```
---

## วิธีรัน Playbook

```bash
cd ansible
./run.sh <path/to/playbook.yml>
```

**ตัวอย่าง:**

```bash
# FortiGate
./run.sh -i inventory/inventory_fortigate.ini fortigate/fortigate_collect_pm.yml

# Aruba
./run.sh -i inventory/inventory_aruba.ini aruba/arubapm.yaml

# HPE Comware7
./run.sh -i inventory/inventory_hpe.ini hpe/hpepm.yml
```

**Flow การทำงาน:**

```
./run.sh -i inventory/inventory_fortigate.ini fortigate/fortigate_collect_pm.yml
        ↓
สร้าง container จาก ansible-env:latest
        ↓
mount โฟลเดอร์ปัจจุบัน → /ansible   ← playbook, inventory
mount ~/.ssh            → /root/.ssh  ← SSH key
        ↓
รัน ansible-playbook -i inventory fortigate/backup.yml
        ↓
container ถูกลบทิ้งอัตโนมัติ
```

> Docker จะรันเฉพาะตอนสั่ง `./run.sh` แล้วจบไป **ไม่ได้ค้างอยู่ตลอด**

---

## การอัปเดต repo

เมื่อมีการแก้ไข playbook หรือ config ใหม่จาก repo ให้รัน:

```bash
cd ansible
git pull
```

หากมีการแก้ไข `Dockerfile` หรือ `requirements.yml` ต้อง build image ใหม่ด้วย:

```bash
docker build -t ansible-env .
```

---

## ปัญหาที่พบบ่อย

| อาการ | วิธีแก้ |
|-------|---------|
| `permission denied` ตอนรัน docker | รัน `newgrp docker` หรือเปิด terminal ใหม่ |
| `./run.sh: Permission denied` | รัน `chmod +x run.sh` |
| `docker: command not found` | รัน `hash -r` แล้วลองใหม่ |
| Docker daemon ไม่ start | รัน `sudo service docker start` |
| Script ค้างนานผิดปกติ | เช็คการเชื่อมต่ออินเทอร์เน็ต |

---

## โครงสร้าง Repository

```
ansible/
├── Dockerfile          ← สร้าง image สำหรับรัน Ansible
├── docker-compose.yml  ← config การรัน container
├── run.sh              ← script สำหรับรัน playbook
├── setup.sh            ← script ติดตั้งทั้งหมด
├── requirements.yml    ← Ansible collections ที่ใช้
├── ansible.cfg         ← config ของ Ansible
├── inventory           ← รายชื่ออุปกรณ์
├── fortigate/          ← playbook สำหรับ FortiGate
├── aruba/              ← playbook สำหรับ Aruba
└── hpe/                ← playbook สำหรับ HPE Comware7
```

---
