from fastapi import FastAPI
from pydantic import BaseModel
from transformers import GPT2Tokenizer
import torch

# Import your model
from generator import LightweightGPT2, generate_recipe

# Initialize FastAPI
app = FastAPI()

# Set device
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Load tokenizer
tokenizer = GPT2Tokenizer.from_pretrained("./save_token/")
tokenizer.pad_token = tokenizer.eos_token

# Load model
model = LightweightGPT2(vocab_size=tokenizer.vocab_size)
model.load_state_dict(torch.load("./model/weights.pth", map_location=device))
model = model.to(device)
model.eval()

# Request model for API
class RecipeRequest(BaseModel):
    ingredients: list[str]

@app.post("/generate_recipe/")
async def generate_recipe_api(request: RecipeRequest):
    recipe = generate_recipe(request.ingredients, model, tokenizer, device)
    return {"recipe": recipe}

# Run with: uvicorn server:app --host 0.0.0.0 --port 8000
