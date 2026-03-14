import sys
import os
import uuid
from datetime import datetime, timedelta, timezone
from jose import jwt

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import security
import schemas
from models import UserRole

def test_jwt_standardization():
    print("Testing JWT Standardization...")
    
    # Mock data
    user_uuid = uuid.uuid4()
    role = UserRole.admin
    
    # Create token
    token = security.create_access_token(
        data={"user_uuid": user_uuid, "role": role},
        expires_delta=timedelta(minutes=10)
    )
    
    # Decode token
    payload = jwt.decode(token, security.SECRET_KEY, algorithms=[security.ALGORITHM])
    
    print(f"Payload: {payload}")
    
    # Assertions
    assert payload["sub"] == str(user_uuid), f"Expected sub to be {user_uuid}, got {payload['sub']}"
    assert payload["ecosystem_role"] == "admin", f"Expected ecosystem_role to be admin, got {payload['ecosystem_role']}"
    assert "exp" in payload
    
    print("✅ JWT Standardization Test Passed!")

def test_schema_aliases():
    print("\nTesting Schema Aliases...")
    
    # Mock user data
    external_id = uuid.uuid4()
    user_data = {
        "email": "test@example.com",
        "username": "Ecosystem User",
        "nickname": "Eco",
        "user_id": 123,
        "external_id": external_id,
        "role": UserRole.admin,
        "status": "ACTIVE",
        "profile_pic": "https://example.com/photo.jpg"
    }
    
    # This should populate fields based on the provided keys (matching aliases or field names)
    user = schemas.User.model_validate(user_data)
    
    print(f"User Object: {user}")
    print(f"User ID (UUID): {user.user_id}")
    print(f"Full Name: {user.full_name}")
    print(f"Photo URL: {user.photo_url}")
    
    # Verify values - Note: Attribute access uses the field name, NOT the alias
    assert user.user_id == external_id
    # username is mapped to full_name attribute
    assert user.full_name == "Ecosystem User"
    # profile_pic is mapped to photo_url attribute
    assert user.photo_url == "https://example.com/photo.jpg"
    
    # Verify serialization (exporting with aliases)
    exported = user.model_dump(by_alias=True)
    print(f"Exported (by_alias=True): {exported}")
    
    assert exported["user_id"] == external_id # external_id alias is user_id
    assert exported["full_name"] == "Ecosystem User"
    assert exported["photo_url"] == "https://example.com/photo.jpg"
    
    print("✅ Schema Aliases Test Passed!")

if __name__ == "__main__":
    try:
        test_jwt_standardization()
        test_schema_aliases()
        print("\nAll standardization tests passed successfully!")
    except Exception as e:
        print(f"\n❌ Test Failed: {e}")
        sys.exit(1)
