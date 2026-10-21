import json
import urllib.request
import urllib.error
import time

BASE = "http://localhost:5000/api"

def request(path, method="GET", body=None):
    url = f"{BASE}/{path}"
    headers = {"Content-Type": "application/json"}
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
    print("=== TESTING GMAIL OTP REGISTRATION FLOW ===")

    ts = int(time.time())
    username = f"otp_user_{ts}"
    email = f"otp_user_{ts}@gmail.com"

    # Step 1: Send OTP for registration
    print(f"\n1. Sending OTP to register new user '{username}' ({email})...")
    status, res = request("Authenticate/register-send-otp", "POST", {
        "username": username,
        "email": email,
        "password": "SecurePassword@123",
        "initials": "OTP",
        "role": "User"
    })
    print(f"   -> Status: {status}, Response message: {res.get('message')}")
    assert status == 200, f"Failed to send OTP: {res}"
    dev_otp = res.get("devOtp")
    print(f"   -> Received OTP: {dev_otp}")
    assert dev_otp is not None and len(dev_otp) == 6, "OTP should be 6 digits"

    # Step 2: Try verifying with INVALID OTP
    print("\n2. Testing verification with WRONG OTP (000000)...")
    status, res = request("Authenticate/verify-register-otp", "POST", {
        "email": email,
        "otp": "000000"
    })
    print(f"   -> Status: {status} (Expected 400), Message: {res.get('message')}")
    assert status == 400, f"Expected 400 for wrong OTP, got {status}"

    # Step 3: Test Resend OTP
    print("\n3. Testing Resend OTP...")
    status, res = request("Authenticate/resend-otp", "POST", {"email": email})
    print(f"   -> Status: {status}, Message: {res.get('message')}")
    assert status == 200, f"Resend OTP failed: {res}"
    new_otp = res.get("devOtp")
    print(f"   -> New OTP code: {new_otp}")
    assert new_otp is not None and len(new_otp) == 6

    # Step 4: Verify with CORRECT OTP
    print(f"\n4. Testing verification with CORRECT OTP ({new_otp})...")
    status, res = request("Authenticate/verify-register-otp", "POST", {
        "email": email,
        "otp": new_otp
    })
    print(f"   -> Status: {status}, Message: {res.get('message')}")
    assert status == 200, f"Valid OTP verification failed: {res}"

    # Step 5: Test Login with the newly registered user
    print("\n5. Testing Login with the newly created account...")
    status, res = request("Authenticate/login", "POST", {
        "username": username,
        "password": "SecurePassword@123"
    })
    print(f"   -> Status: {status}, Role: {res.get('role')}")
    assert status == 200 and res.get("role") == "User", f"Login failed for newly verified user: {res}"
    token = res.get("token")
    assert token is not None, "Login did not return JWT token"
    print(f"   -> Successfully logged in with JWT token (length {len(token)})")

    print("\n=======================================================")
    print(">>> GMAIL OTP VERIFICATION TEST SUITE PASSED 100%! <<<")
    print("=======================================================")

if __name__ == "__main__":
    main()
