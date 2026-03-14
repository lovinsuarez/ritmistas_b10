from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from routers import auth, users, sectors, ranking, activities, admin
import os

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Projeto Ritmistas B10 API v5")

# CORS Configuration
DEPLOYED_ORIGINS = [
    "https://ritmistas-b10-1.onrender.com",
    "https://ritmistas-b10.onrender.com",
]

extra = os.getenv("CORS_EXTRA_ORIGINS", "")
EXTRA_ORIGINS = [o.strip() for o in extra.split(",") if o.strip()]
ALLOWED_ORIGINS = DEPLOYED_ORIGINS + EXTRA_ORIGINS

LOCALHOST_REGEX = r"^https?://(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])(:\d+)?$"

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