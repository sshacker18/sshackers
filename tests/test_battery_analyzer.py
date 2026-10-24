import sys
import tempfile
import unittest
from datetime import datetime, timezone, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import battery_analyzer


class BatteryAnalyzerTests(unittest.TestCase):
    def sample(self, minute, level, plugged=False, temp=31.0):
        return {
            "timestamp": datetime(2026, 10, 15, tzinfo=timezone.utc) + timedelta(minutes=minute),
            "level_percent": level,
            "plugged": plugged,
            "temperature_c": temp,
            "status": "discharging",
            "voltage_mv": 3900,
            "current_now_ua": None,
        }

    def test_discharge_rate_ignores_plugged_intervals(self):
        data = [
            self.sample(0, 80),
            self.sample(60, 75),
            self.sample(120, 90, plugged=True),
            self.sample(180, 88),
        ]
        result = battery_analyzer.analyze(data)
        self.assertEqual(result["discharge_rate_percent_points_per_hour_mean"], 5.0)
        self.assertEqual(result["estimated_unplugged_drop_percent_points"], 5.0)

    def test_temperature_warning(self):
        result = battery_analyzer.analyze([self.sample(0, 50, temp=41), self.sample(30, 48, temp=41)])
        self.assertTrue(any("temperature" in item.lower() or "heat" in item.lower() for item in result["recommendations"]))

    def test_empty_samples_rejected(self):
        with self.assertRaises(ValueError):
            battery_analyzer.analyze([])

    def test_csv_load(self):
        csv_data = (
            "timestamp,level_percent,temperature_c,voltage_mv,plugged,status,health,current_now_ua,charge_counter_uah\n"
            "2026-10-15T08:00:00Z,70,32.0,3900,0,discharging,good,,\n"
            "2026-10-15T09:00:00Z,66,33.0,3850,0,discharging,good,,\n"
        )
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "battery.csv"
            path.write_text(csv_data, encoding="utf-8")
            result = battery_analyzer.analyze(battery_analyzer.load_samples(path))
            self.assertEqual(result["sample_count"], 2)
            self.assertEqual(result["discharge_rate_percent_points_per_hour_mean"], 4.0)


if __name__ == "__main__":
    unittest.main()
