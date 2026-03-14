# verify_sync.py
import sys
import os
import uuid
from sqlalchemy import text
from sqlalchemy.orm import Session

# Add current dir to path
sys.path.append(os.getcwd())

import models, schemas, crud, security, database

def test_sync():
    print("--- Starting Sync Verification ---")
    
    # DROP and RECREATE for clean development test
    print("Recreating database tables for clean test...")
    models.Base.metadata.drop_all(bind=database.engine)
    models.Base.metadata.create_all(bind=database.engine)
    
    db = next(database.get_db())
    
    # Mock payload from Launchpad/User Service
    mock_uuid = "6a035e39-4620-4178-9424-ec49e88b091b"
    mock_payload = {
        "sub": mock_uuid,
        "email": "admin@dualforge.com",
        "ecosystem_role": "admin",
        "exp": 1773528919
    }
    
    print(f"Testing sync for UUID: {mock_uuid}")
    
    # Test sync
    user = crud.sync_user_with_ecosystem(db, mock_payload)
    
    if user:
        print(f"SUCCESS: User synced. ID: {user.user_id}, UUID: {user.external_id}, Role: {user.role.value}")
        assert str(user.external_id) == mock_uuid
        assert user.email == "admin@dualforge.com"
        assert user.role == models.UserRole.admin
    else:
        print("FAILURE: User not synced.")
        return

    # Test get_current_user logic (mocking token)
    token = security.create_access_token(data={"sub": mock_uuid, "ecosystem_role": "admin", "email": "admin@dualforge.com"})
    
    print("Testing get_current_user with generated token...")
    try:
        user_from_token = security.get_current_user(token=token, db=db)
        print(f"SUCCESS: get_current_user returned user {user_from_token.username}")
        assert user_from_token.user_id == user.user_id
    except Exception as e:
        print(f"FAILURE in get_current_user: {e}")
        import traceback
        traceback.print_exc()

    print("--- Verification Complete ---")

if __name__ == "__main__":
    test_sync()
