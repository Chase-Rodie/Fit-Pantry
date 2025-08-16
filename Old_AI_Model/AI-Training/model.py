import torch.nn as nn
from transformers import GPT2Config, GPT2LMHeadModel

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
