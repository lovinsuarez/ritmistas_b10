from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from routers import auth, users, sectors, ranking, activities, admin
import os

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Projeto Ritmistas B10 API v5")

# CORS Configuration
allowed_origins_env = os.getenv("RITMISTAS_CORS_ORIGINS", "")
ALLOWED_ORIGINS = [o.strip() for o in allowed_origins_env.split(",") if o.strip()]

LOCALHOST_REGEX = r"^https?://([a-z0-9-]+\.)?(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])(:\d+)?$"

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_origin_regex=LOCALHOST_REGEX,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(sectors.router)
app.include_router(ranking.router)
app.include_router(activities.router)
app.include_router(admin.router)

@app.get("/")
def health_check():
    return {"status": "ok", "service": "ritmistas-api"}