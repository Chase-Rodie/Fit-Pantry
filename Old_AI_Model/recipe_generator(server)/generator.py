import torch.nn as nn
from transformers import GPT2Config, GPT2LMHeadModel, GPT2Tokenizer
import torch
import warnings
warnings.filterwarnings('ignore')

class LightweightGPT2(nn.Module):
    def __init__(self, vocab_size, hidden_size=256, num_layers=4, num_heads=4):
        super().__init__()
        self.config = GPT2Config(
            vocab_size=vocab_size,
            n_positions=512,
            n_ctx=512,
            n_embd=hidden_size,
            n_layer=num_layers,
            n_head=num_heads,
            bos_token_id=50256,
            eos_token_id=50256
        )
        self.model = GPT2LMHeadModel(self.config)

    def forward(self, input_ids, attention_mask=None, labels=None):
        return self.model(
            input_ids=input_ids,
            attention_mask=attention_mask,
            labels=labels
        )

# Set device
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f'Using {device}')

# Load tokenizer
tokenizer = GPT2Tokenizer.from_pretrained("./save_token/")
tokenizer.pad_token = tokenizer.eos_token

# Recreate the model architecture (must match the original structure)
model = LightweightGPT2(vocab_size=tokenizer.vocab_size)

# Load model weights
model.load_state_dict(torch.load("./model/weights.pth", map_location=device))
model = model.to(device)
model.eval()

# Function to generate recipes
def generate_recipe(ingredients, model, tokenizer, device):
    model.eval()
    
    # Format input
    input_text = f"Ingredients: {', '.join(ingredients)}\nInstructions:"
    
    # Tokenize input
    inputs = tokenizer(
        input_text,
        return_tensors="pt",
        max_length=512,
        truncation=True,
        padding=True
    ).to(device)
    
    # Generate recipe
    with torch.no_grad():
        outputs = model.model.generate(
            input_ids=inputs["input_ids"],
            attention_mask=inputs["attention_mask"],
            max_length=512,
            num_return_sequences=1,
            temperature=0.7,
            top_p=0.9,
            do_sample=True
        )
    
    # Decode and return recipe
    recipe = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return recipe

# Test the loaded model
test_ingredients = ["chicken breast", "rice", "soy sauce", "garlic"] # Change ingredients to get different recomendations
generated_recipe = generate_recipe(test_ingredients, model, tokenizer, device)
print("Generated Recipe:")
print(generated_recipe)
