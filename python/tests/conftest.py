import os
import sys
from pathlib import Path

# Make `app` importable and force a SQLite URL before app modules load.
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
