from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from groq import Groq
import os
from dotenv import load_dotenv
import json
from typing import List

# Load environment variables from .env file
load_dotenv()

# Read the API key from the environment
API_KEY = os.getenv("GROQ_API_KEY")

# Check if the API key is loaded
if not API_KEY:
    raise RuntimeError("GROQ_API_KEY not found. Make sure it is set in the .env file.")

# Initialize Groq client with loaded API key
try:
    client = Groq(api_key=API_KEY)
except Exception as e:
    raise RuntimeError(f"Failed to initialize Groq client: {str(e)}")

# FastAPI app instance
app = FastAPI()

# Request model
class MedicineRequest(BaseModel):
    medicine_name: str
    get_all: bool = False

# Prompt generator
def generate_medicine_prompt(medicine_names: List[str], get_all: bool) -> str:
    if get_all:
        return f"""For each medicine in {medicine_names}, provide information as a JSON object with these fields per medicine:
        {{
            "medicine_name": "",
            "generic_name": "",
            "strength": "",
            "uses": [],
            "dosage": {{
                "adults": "",
                "children": "",
                "max_daily": ""
            }},
            "side_effects": {{
                "common": [],
                "serious": []
            }},
            "precautions": [],
            "interactions": [],
            "warnings": []
        }}
        Return a JSON array of these objects, one for each valid medicine you can identify.
        Important:
        - Only return valid JSON array
        - Skip any unrecognized medicine names
        - Maintain the exact field structure"""
    else:
        return f"""Provide information about one medicine from {medicine_names} as a single JSON object with these fields:
        {{
            "medicine_name": "",
            "generic_name": "",
            "strength": "",
            "uses": [],
            "dosage": {{
                "adults": "",
                "children": "",
                "max_daily": ""
            }},
            "side_effects": {{
                "common": [],
                "serious": []
            }},
            "precautions": [],
            "interactions": [],
            "warnings": []
        }}
        Choose the most common/relevant medicine from the list.
        Important:
        - Only return valid JSON object
        - Maintain the exact field structure"""

# Main route to fetch medicine info
@app.post("/medicine-info")
async def get_medicine_info(request: MedicineRequest):
    try:
        # Split comma-separated medicine names
        medicine_names = [name.strip() for name in request.medicine_name.split(",")]

        # Create chat completion
        response = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "You are a medical information specialist. Provide accurate drug information in exact JSON format."
                },
                {
                    "role": "user",
                    "content": generate_medicine_prompt(medicine_names, request.get_all)
                }
            ],
            model="llama3-70b-8192",
            temperature=0.3,
            response_format={"type": "json_object"}
        )

        result = json.loads(response.choices[0].message.content)

        # Wrap single object in list for consistency
        if request.get_all and not isinstance(result, list):
            result = [result]

        return JSONResponse(content=result)

    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Failed to parse JSON response")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

# Health check
@app.get("/")
def health_check():
    return {"status": "API is running"}
