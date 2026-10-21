import json
import urllib.request
import urllib.error
import time

BASE = "http://localhost:5000/api"

def request(path, method="GET", body=None, token=None):
    url = f"{BASE}/{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode("utf-8") if body else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            return response.status, json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        try:
            return e.code, json.loads(raw)
        except:
            return e.code, {"raw": raw}

def main():
    print("=== TESTING WORKPULSE AI ATTENDANCE, NFC & MEETINGS API ===")

    ts = int(time.time())
    username = f"emp_{ts}"

    # 1. Register employee
    print(f"\n1. Registering new employee '{username}'...")
    status, res = request("Authenticate/register", "POST", {
        "username": username,
        "email": f"{username}@company.com",
        "password": "Password@123",
        "initials": "EMP",
        "role": "User"
    })
    assert status == 200, f"Register failed: {res}"

    # 2. Login employee
    print(f"\n2. Logging in as employee '{username}'...")
    status, res = request("Authenticate/login", "POST", {
        "username": username,
        "password": "Password@123"
    })
    assert status == 200, f"Login failed: {res}"
    emp_token = res["token"]

    # 3. Login Admin
    print("\n3. Logging in as Admin...")
    status, res = request("Authenticate/login", "POST", {
        "username": "admin",
        "password": "Admin@123"
    })
    assert status == 200, f"Admin login failed: {res}"
    admin_token = res["token"]

    # 4. Associate NFC Card
    card_uid = f"NFC_{ts}"
    print(f"\n4. Linking NFC Card [{card_uid}] to employee...")
    status, res = request("Attendance/register-nfc", "POST", {
        "nfcCardId": card_uid
    }, token=emp_token)
    assert status == 200, f"Register NFC failed: {res}"
    print(f"   -> Result: {res.get('message')}")

    # 5. Check-in via Face ID with AI Energy Pulse
    print("\n5. Testing Face ID Check-in with AI Energy Pulse (92.5%, Tràn đầy năng lượng)...")
    status, res = request("Attendance/check-in", "POST", {
        "method": "FaceID",
        "energyScore": 92.5,
        "moodLabel": "Tràn đầy năng lượng",
        "isLivenessVerified": True,
        "deviceInfo": "Android Physical Device",
        "notes": "Check-in khuôn mặt ca sáng thành công"
    }, token=emp_token)
    assert status == 200, f"Face Check-in failed: {res}"
    print(f"   -> Check-in Status: {res.get('message')}")
    print(f"   -> Energy Score: {res['data'].get('energyScore')}%, Mood: {res['data'].get('moodLabel')}")

    # 6. Check Today Status
    print("\n6. Checking Today Status...")
    status, res = request("Attendance/today-status", "GET", token=emp_token)
    assert status == 200 and res.get("hasCheckedIn") is True
    print(f"   -> Has Checked-In: {res.get('hasCheckedIn')}, Has Checked-Out: {res.get('hasCheckedOut')}")

    # 7. Check-out
    print("\n7. Testing Check-out...")
    status, res = request("Attendance/check-out", "POST", {
        "notes": "Hoàn thành ca trực"
    }, token=emp_token)
    assert status == 200, f"Check-out failed: {res}"
    print(f"   -> Check-out Result: {res.get('message')}")

    # 8. Check-in via NFC Card Tap
    print(f"\n8. Testing NFC Card Tap Check-in with Card UID [{card_uid}]...")
    status, res = request("Attendance/check-in-nfc", "POST", {
        "nfcCardId": card_uid,
        "deviceInfo": "NFC Hardware Reader"
    }, token=emp_token)
    assert status == 200, f"NFC Check-in failed: {res}"
    print(f"   -> NFC Check-in Result: {res.get('message')}")

    # 9. Admin view all today attendance
    print("\n9. Admin querying All Today Attendance...")
    status, res = request("Attendance/all-today", "GET", token=admin_token)
    assert status == 200, f"Admin all-today failed: {res}"
    print(f"   -> Total check-ins recorded today: {res.get('total')}")

    # 10. Admin view Energy Analytics & Well-being
    print("\n10. Admin querying AI Energy Analytics & Well-being...")
    status, res = request("Attendance/energy-analytics", "GET", token=admin_token)
    assert status == 200, f"Energy analytics failed: {res}"
    print(f"   -> Average Company Energy Score: {res.get('averageEnergy')}%")
    print(f"   -> Mood Distribution: {res.get('moodDistribution')}")

    # 11. Create & List Meeting Rooms
    print("\n11. Testing Group Video Standup Meeting Creation...")
    status, res = request("Meeting/create-room", "POST", {
        "title": "Giao Ban Đầu Giờ Ca Sáng",
        "description": "Báo cáo công việc và phân bổ nhiệm vụ ca trực"
    }, token=admin_token)
    assert status == 200, f"Create meeting room failed: {res}"
    room_code = res["data"]["roomCode"]
    print(f"   -> Created Room Code: {room_code}")

    status, rooms = request("Meeting/rooms", "GET", token=emp_token)
    assert status == 200 and len(rooms.get("data", [])) > 0
    print(f"   -> Employee found {len(rooms['data'])} active meeting rooms")

    print("\n=================================================================")
    print(">>> WORKPULSE AI BACKEND VERIFICATION PASSED 100% (ALL CHECKS) <<<")
    print("=================================================================")

if __name__ == "__main__":
    main()
