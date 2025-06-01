from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import httpx
import asyncio
import logging
import os

app = FastAPI(
    title="FastAPI X-Ray Demo",
    description="FastAPI application with OpenTelemetry auto-instrumentation for AWS X-Ray",
    version="1.0.0"
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.get("/")
async def root():
    logger.info("Root endpoint called")
    return {"message": "Hello from FastAPI with OpenTelemetry!", "service": "fastapi-xray-demo"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "fastapi-xray-demo"}

@app.get("/api/users/{user_id}")
async def get_user(user_id: int):
    logger.info(f"Getting user {user_id}")
    
    if user_id < 1:
        raise HTTPException(status_code=400, detail="User ID must be positive")
    
    if user_id > 1000:
        raise HTTPException(status_code=404, detail="User not found")
    
    await asyncio.sleep(0.1)
    
    return {
        "user_id": user_id,
        "name": f"User {user_id}",
        "email": f"user{user_id}@example.com"
    }

@app.get("/api/external")
async def call_external_service():
    logger.info("Calling external service")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get("https://httpbin.org/delay/1")
            return {
                "external_response": response.json(),
                "status": "success"
            }
        except Exception as e:
            logger.error(f"External service call failed: {e}")
            raise HTTPException(status_code=503, detail="External service unavailable")

@app.get("/api/database")
async def simulate_database_call():
    logger.info("Simulating database call")
    
    await asyncio.sleep(0.2)
    
    return {
        "query": "SELECT * FROM users",
        "results": [
            {"id": 1, "name": "Alice"},
            {"id": 2, "name": "Bob"}
        ],
        "execution_time_ms": 200
    }

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Global exception handler: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "error": str(exc)}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
