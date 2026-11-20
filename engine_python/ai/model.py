"""The Gebeta network (section 6 of the guide).

The layer names h1, h2, policy and value are part of the contract: export.py
reads the state_dict keys h1.weight, h1.bias, h2.weight, h2.bias,
policy.weight, policy.bias, value.weight and value.bias.
"""
import torch
from torch import nn


class GebetaNet(nn.Module):
    def __init__(self, hidden: int = 128):
        super().__init__()
        self.h1 = nn.Linear(14, hidden)
        self.h2 = nn.Linear(hidden, hidden)
        self.policy = nn.Linear(hidden, 6)
        self.value = nn.Linear(hidden, 1)

    def forward(self, x):
        """x: float tensor (batch, 14), already divided by 48.

        Returns (policy logits (batch, 6), value (batch,)), value in -1..1.
        """
        a = torch.relu(self.h1(x))
        a = torch.relu(self.h2(a))
        return self.policy(a), torch.tanh(self.value(a)).squeeze(-1)


if __name__ == "__main__":
    # Self-check: python engine_python/ai/model.py
    net = GebetaNet()
    expected = {
        "h1.weight": (128, 14), "h1.bias": (128,),
        "h2.weight": (128, 128), "h2.bias": (128,),
        "policy.weight": (6, 128), "policy.bias": (6,),
        "value.weight": (1, 128), "value.bias": (1,),
    }
    actual = {k: tuple(v.shape) for k, v in net.state_dict().items()}
    assert actual == expected, f"state_dict mismatch: {actual}"
    logits, value = net(torch.zeros(3, 14))
    assert tuple(logits.shape) == (3, 6), logits.shape
    assert tuple(value.shape) == (3,), value.shape
    assert float(value.abs().max()) <= 1.0
    print("model ok:", ", ".join(f"{k} {v}" for k, v in actual.items()))