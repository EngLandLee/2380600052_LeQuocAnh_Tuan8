import json
import urllib.request
import urllib.error
import time
import sys

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
    print("=== STARTING INTEGRATION & E2E TESTS ===")

    # 1. Register User
    username = f"user_{int(time.time())}"
    print(f"\n1. Testing Register New User ({username})...")
    status, res = request("Authenticate/register", "POST", {
        "username": username,
        "email": f"{username}@test.com",
        "password": "Password@123",
        "initials": "U1",
        "role": "User"
    })
    print(f"   -> Status: {status}, Response: {res}")
    assert status == 200, f"Register failed: {res}"

    # 2. Login User
    print(f"\n2. Testing Login as Normal User ({username})...")
    status, res = request("Authenticate/login", "POST", {
        "username": username,
        "password": "Password@123"
    })
    print(f"   -> Status: {status}, Role: {res.get('role')}")
    assert status == 200 and res.get("role") == "User", f"User login failed: {res}"
    user_token = res["token"]

    # 3. Login Admin (Default Seed account)
    print("\n3. Testing Login as Admin (Default Seed: admin / Admin@123)...")
    status, res = request("Authenticate/login", "POST", {
        "username": "admin",
        "password": "Admin@123"
    })
    print(f"   -> Status: {status}, Role: {res.get('role')}")
    assert status == 200 and res.get("role") == "Admin", f"Admin login failed: {res}"
    admin_token = res["token"]

    # 4. User tries to create Category -> Must be 403 Forbidden
    print("\n4. Testing Role Authorization: Normal User creating Category (Should be Forbidden)...")
    status, res = request("Category", "POST", {"name": "Hàng Cấm"}, token=user_token)
    print(f"   -> Status: {status} (Expected 403 Forbidden)")
    assert status == 403, f"Expected 403 but got {status}"

    # 5. Admin creates Category
    print("\n5. Testing Admin creating Category...")
    status, res = request("Category", "POST", {
        "name": "Điện Thoại & Phụ Kiện",
        "description": "Các dòng smartphone chính hãng"
    }, token=admin_token)
    assert status == 200, f"Category creation failed: {res}"
    cat_id = res["data"]["id"]
    print(f"   -> Created Category ID: {cat_id}, Name: {res['data']['name']}")

    # 6. Admin creates Product linked to Category
    print(f"\n6. Testing Admin creating Product attached to Category #{cat_id}...")
    status, res = request("Product", "POST", {
        "name": "Samsung Galaxy S24 Ultra",
        "price": 28990000,
        "description": "Snapdragon 8 Gen 3, Camera 200MP",
        "categoryId": cat_id
    }, token=admin_token)
    assert status == 200, f"Product creation failed: {res}"
    prod_id = res["data"]["id"]
    print(f"   -> Created Product ID: {prod_id}, CategoryId: {res['data']['categoryId']}")

    # 7. Unauthenticated user tries to get products -> Must be 401 Unauthorized
    print("\n7. Testing Homework Requirement: Product API requires Authorization (Anonymous should be 401)...")
    status, res = request("Product", "GET")
    print(f"   -> Status: {status} (Expected 401 Unauthorized)")
    assert status == 401, f"Expected 401 but got {status}"

    # 8. User gets products with token
    print("\n8. Testing User getting products with valid JWT...")
    status, res = request("Product", "GET", token=user_token)
    assert status == 200, f"Product GET failed: {res}"
    print(f"   -> Total products returned: {len(res['data'])}")

    # 9. Homework Constraint Check: Delete Category -> Product's categoryId must become null
    print(f"\n9. Testing Homework Requirement: Delete Category #{cat_id} and verify Product #{prod_id} categoryId becomes NULL...")
    status, res = request(f"Category/{cat_id}", "DELETE", token=admin_token)
    assert status == 200, f"Delete category failed: {res}"
    print(f"   -> Delete response: {res.get('message')}")

    # Re-fetch product
    status, res = request(f"Product/{prod_id}", "GET", token=admin_token)
    assert status == 200, f"Get product failed: {res}"
    product_data = res["data"]
    print(f"   -> Product after category deletion: CategoryId = {product_data.get('categoryId')}, Category = {product_data.get('category')}")
    assert product_data.get("categoryId") is None, "ERROR: Product CategoryId was not set to NULL!"

    print("\n=======================================================")
    print(">>> ALL VERIFICATION CHECKS PASSED SUCCESSFULLY! 100% <<<")
    print("=======================================================")

if __name__ == "__main__":
    main()
