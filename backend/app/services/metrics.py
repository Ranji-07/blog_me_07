"""Small dependency-free Prometheus text metrics registry."""
from collections import Counter
from threading import Lock

class Metrics:
    def __init__(self): self._counts, self._latency, self._lock = Counter(), Counter(), Lock()
    def inc(self, name, labels=""):
        with self._lock: self._counts[(name, labels)] += 1
    def observe(self, name, seconds):
        with self._lock: self._latency[name] += seconds
    def render(self):
        with self._lock:
            lines = []
            for (name, labels), value in self._counts.items(): lines.append(f"portfolio_{name}{{{labels}}} {value}" if labels else f"portfolio_{name} {value}")
            for name, value in self._latency.items(): lines.append(f"portfolio_{name}_seconds_total {value:.6f}")
        return "\n".join(lines) + "\n"
metrics = Metrics()
